-- SpazaSpecials — initial schema
-- Run in Supabase SQL Editor, or: supabase db push
--
-- Money is stored in cents (integer). Never use float for money.
-- Every table has RLS enabled. Policies are at the bottom.

create extension if not exists "uuid-ossp";
create extension if not exists postgis;      -- for radius queries
create extension if not exists pg_trgm;      -- for fuzzy product search

-- ============================================================
-- WHOLESALERS
-- ============================================================
create type wholesaler_plan as enum ('free', 'growth');

create table wholesalers (
  id              uuid primary key default uuid_generate_v4(),
  name            text not null,
  slug            text unique not null,
  logo_initials   text,                       -- e.g. 'KC'
  phone_whatsapp  text not null,              -- E.164, e.g. +27760000000
  phone_call      text,
  address         text,
  location        geography(point, 4326),     -- lng/lat
  suburb          text,
  hours           jsonb default '{}'::jsonb,  -- {"mon":["07:00","18:00"], ...}
  verified        boolean default false,
  verified_at     timestamptz,
  plan            wholesaler_plan default 'free',
  created_at      timestamptz default now()
);

create index wholesalers_location_idx on wholesalers using gist (location);

-- Links a Supabase auth user to a wholesaler
create table wholesaler_users (
  user_id       uuid references auth.users(id) on delete cascade,
  wholesaler_id uuid references wholesalers(id) on delete cascade,
  role          text default 'owner',         -- owner | staff
  created_at    timestamptz default now(),
  primary key (user_id, wholesaler_id)
);

-- ============================================================
-- CANONICAL PRODUCT CATALOGUE
-- One row per real-world product. Shared across all wholesalers
-- so price comparison actually compares like with like.
-- ============================================================
create table products (
  id          uuid primary key default uuid_generate_v4(),
  name        text not null,                  -- 'ACE Super Maize Meal'
  brand       text,
  category    text not null,                  -- 'Maize Meal'
  subcategory text,
  pack_size   text not null,                  -- '12.5kg'
  pack_unit   text,                           -- 'bag' | 'case' | 'drum'
  units_per   integer default 1,              -- 6 for a case of 6
  base_qty    numeric,                        -- 12.5 (for per-kg maths)
  base_unit   text,                           -- 'kg' | 'l' | 'ea'
  barcode     text,
  aliases     text[] default '{}',            -- ['pap','impuphu','bur','maize']
  image_url   text,
  created_at  timestamptz default now()
);

-- Fuzzy + alias search
create index products_name_trgm on products using gin (name gin_trgm_ops);
create index products_aliases_idx on products using gin (aliases);
create index products_category_idx on products (category);

-- ============================================================
-- LISTINGS
-- A wholesaler's price for a product. Two kinds:
--   'stock'   — always-on catalogue entry, no end date
--   'special' — time-limited promotional price
-- ============================================================
create type listing_type as enum ('stock', 'special');
create type stock_band   as enum ('in_stock', 'low', 'out');
create type listing_status as enum ('draft', 'live', 'expired', 'paused');

create table listings (
  id             uuid primary key default uuid_generate_v4(),
  wholesaler_id  uuid not null references wholesalers(id) on delete cascade,
  product_id     uuid not null references products(id),
  type           listing_type not null default 'stock',
  status         listing_status not null default 'draft',

  price_cents    integer not null check (price_cents > 0),
  was_price_cents integer check (was_price_cents is null or was_price_cents > price_cents),

  stock          stock_band default 'in_stock',
  stock_qty      integer,                     -- optional, specials only
  stock_unit     text,                        -- 'cases' | 'bags'

  photo_url      text,
  notes          text,

  starts_at      timestamptz default now(),
  ends_at        timestamptz,                 -- required for specials

  -- Freshness. This is the business-critical field.
  confirmed_at   timestamptz default now(),

  created_at     timestamptz default now(),
  updated_at     timestamptz default now(),

  constraint special_needs_end_date
    check (type <> 'special' or ends_at is not null)
);

create unique index listings_one_per_product
  on listings (wholesaler_id, product_id, type)
  where status in ('live', 'draft');

create index listings_live_idx on listings (status, type, ends_at);
create index listings_wholesaler_idx on listings (wholesaler_id);
create index listings_confirmed_idx on listings (confirmed_at);

-- How stale is this price? Drives ranking and the "confirm prices" nudge.
create or replace function listing_staleness_hours(l listings)
returns numeric language sql immutable as $$
  select extract(epoch from (now() - l.confirmed_at)) / 3600;
$$;

-- Price history — powers price-drop alerts
create table price_history (
  id          bigserial primary key,
  listing_id  uuid not null references listings(id) on delete cascade,
  price_cents integer not null,
  recorded_at timestamptz default now()
);

create index price_history_listing_idx on price_history (listing_id, recorded_at desc);

create or replace function record_price_change()
returns trigger language plpgsql as $$
begin
  if (tg_op = 'INSERT') or (old.price_cents is distinct from new.price_cents) then
    insert into price_history (listing_id, price_cents)
    values (new.id, new.price_cents);
  end if;
  new.updated_at := now();
  return new;
end $$;

create trigger listings_price_history
  before insert or update on listings
  for each row execute function record_price_change();

-- Auto-expire specials past their end date
create or replace function expire_stale_specials()
returns void language sql as $$
  update listings
     set status = 'expired'
   where type = 'special'
     and status = 'live'
     and ends_at < now();
$$;

-- ============================================================
-- SHOPS (the buyers)
-- ============================================================
create type shop_type as enum ('spaza', 'mini_market', 'restaurant', 'street_vendor', 'tavern', 'other');

create table shops (
  id            uuid primary key default uuid_generate_v4(),
  user_id       uuid references auth.users(id) on delete set null,
  shop_name     text,
  owner_name    text,
  phone_whatsapp text not null unique,
  type          shop_type default 'spaza',
  location      geography(point, 4326),
  suburb        text,
  language      text default 'en',            -- en | so | am | zu | pt
  -- consent flags (POPIA)
  consent_marketing   boolean default false,
  consent_share_name  boolean default false,  -- may a wholesaler see the name?
  created_at    timestamptz default now(),
  last_seen_at  timestamptz default now()
);

create index shops_location_idx on shops using gist (location);

-- ============================================================
-- FAVOURITES / WATCHLIST → price-drop alerts
-- ============================================================
create table favourites (
  shop_id     uuid references shops(id) on delete cascade,
  product_id  uuid references products(id) on delete cascade,
  -- price when they saved it; alert when a listing drops below this
  baseline_cents integer,
  created_at  timestamptz default now(),
  primary key (shop_id, product_id)
);

create table price_alerts (
  id            uuid primary key default uuid_generate_v4(),
  shop_id       uuid references shops(id) on delete cascade,
  listing_id    uuid references listings(id) on delete cascade,
  old_cents     integer not null,
  new_cents     integer not null,
  sent_at       timestamptz,
  seen_at       timestamptz,
  created_at    timestamptz default now()
);

create index price_alerts_shop_idx on price_alerts (shop_id, seen_at);

-- ============================================================
-- ORDER REQUESTS
-- Deliberately called "request", not "order". We only know a
-- message was generated — not that stock existed or money moved.
-- ============================================================
create type request_status as enum (
  'generated',   -- message built in the app
  'sent',        -- user tapped through to WhatsApp
  'confirmed',   -- wholesaler confirmed stock + price
  'partial',     -- some items unavailable
  'declined',
  'expired'
);

create table order_requests (
  id             uuid primary key default uuid_generate_v4(),
  shop_id        uuid not null references shops(id) on delete cascade,
  wholesaler_id  uuid not null references wholesalers(id) on delete cascade,
  campaign_id    uuid,                        -- attribution, set below
  status         request_status default 'generated',
  total_cents    integer not null,
  message_text   text,                        -- exactly what was sent
  created_at     timestamptz default now(),
  sent_at        timestamptz,
  confirmed_at   timestamptz
);

create index order_requests_wholesaler_idx on order_requests (wholesaler_id, created_at desc);
create index order_requests_shop_idx on order_requests (shop_id, created_at desc);

create table order_request_items (
  id              uuid primary key default uuid_generate_v4(),
  request_id      uuid not null references order_requests(id) on delete cascade,
  listing_id      uuid references listings(id) on delete set null,
  product_name    text not null,              -- snapshot, survives listing deletion
  pack_size       text not null,
  qty             integer not null check (qty > 0),
  unit_cents      integer not null,
  line_cents      integer not null
);

-- ============================================================
-- CAMPAIGNS (the revenue)
-- ============================================================
create type campaign_objective as enum ('requests', 'enquiries', 'footfall', 'clear_stock');
create type campaign_status as enum ('draft', 'running', 'complete', 'cancelled');

create table campaigns (
  id             uuid primary key default uuid_generate_v4(),
  wholesaler_id  uuid not null references wholesalers(id) on delete cascade,
  listing_id     uuid not null references listings(id) on delete cascade,
  objective      campaign_objective not null default 'requests',
  audience       shop_type[] not null default '{spaza}',
  radius_km      integer not null default 10,
  suburbs        text[] default '{}',
  retarget_savers boolean default false,
  budget_cents   integer not null check (budget_cents >= 20000),  -- min R200
  spent_cents    integer default 0,
  starts_at      timestamptz default now(),
  ends_at        timestamptz not null,
  status         campaign_status default 'draft',
  created_at     timestamptz default now()
);

create index campaigns_active_idx on campaigns (status, starts_at, ends_at);

-- Every measurable thing a campaign produced.
-- Cost-per-enquiry is derived from this, never estimated.
create type campaign_event_type as enum (
  'impression',   -- appeared in a shop's feed
  'view',         -- opened the detail page
  'save',         -- favourited
  'enquiry',      -- tapped WhatsApp or call
  'direction',    -- tapped directions
  'request'       -- generated an order request
);

create table campaign_events (
  id           bigserial primary key,
  campaign_id  uuid not null references campaigns(id) on delete cascade,
  shop_id      uuid references shops(id) on delete set null,
  type         campaign_event_type not null,
  created_at   timestamptz default now()
);

create index campaign_events_idx on campaign_events (campaign_id, type);
-- One impression per shop per campaign per day (don't inflate reach)
create unique index campaign_events_impression_daily
  on campaign_events (campaign_id, shop_id, (created_at::date))
  where type = 'impression';

alter table order_requests
  add constraint order_requests_campaign_fk
  foreign key (campaign_id) references campaigns(id) on delete set null;

-- Campaign results view — this is the renewal screen
create view campaign_results as
select
  c.id,
  c.wholesaler_id,
  c.listing_id,
  c.objective,
  c.budget_cents,
  c.spent_cents,
  c.status,
  count(*) filter (where e.type = 'impression') as reached,
  count(*) filter (where e.type = 'view')       as views,
  count(*) filter (where e.type = 'save')       as saves,
  count(*) filter (where e.type = 'enquiry')    as enquiries,
  count(*) filter (where e.type = 'direction')  as directions,
  count(*) filter (where e.type = 'request')    as requests,
  case when count(*) filter (where e.type = 'enquiry') > 0
       then c.spent_cents::numeric / count(*) filter (where e.type = 'enquiry')
  end as cost_per_enquiry_cents,
  coalesce((
    select sum(o.total_cents) from order_requests o where o.campaign_id = c.id
  ), 0) as request_value_cents
from campaigns c
left join campaign_events e on e.campaign_id = c.id
group by c.id;

-- ============================================================
-- GENERIC ANALYTICS (non-campaign)
-- ============================================================
create table events (
  id          bigserial primary key,
  shop_id     uuid references shops(id) on delete set null,
  listing_id  uuid references listings(id) on delete set null,
  type        text not null,       -- 'search' | 'view' | 'save' | 'enquiry' | ...
  meta        jsonb default '{}'::jsonb,
  created_at  timestamptz default now()
);

create index events_type_idx on events (type, created_at desc);
create index events_listing_idx on events (listing_id, created_at desc);

-- ============================================================
-- FEED QUERY
-- Ranks listings by distance, freshness and campaign boost.
-- Stale listings sink. This is what protects trust.
-- ============================================================
create or replace function feed_for_shop(
  p_shop_id uuid,
  p_radius_km integer default 15,
  p_limit integer default 40
)
returns table (
  listing_id uuid,
  product_name text,
  pack_size text,
  price_cents integer,
  was_price_cents integer,
  type listing_type,
  ends_at timestamptz,
  wholesaler_name text,
  distance_km numeric,
  staleness_hours numeric,
  is_sponsored boolean,
  score numeric
) language sql stable as $$
  with shop as (select location from shops where id = p_shop_id)
  select
    l.id,
    p.name,
    p.pack_size,
    l.price_cents,
    l.was_price_cents,
    l.type,
    l.ends_at,
    w.name,
    round((st_distance(w.location, shop.location) / 1000)::numeric, 1),
    round(extract(epoch from (now() - l.confirmed_at)) / 3600),
    (c.id is not null),
    -- ranking: closer + fresher + special + sponsored ranks higher
      (100 - least(st_distance(w.location, shop.location) / 1000, 50) * 1.5)
    + (case when l.type = 'special' then 25 else 0 end)
    - least(extract(epoch from (now() - l.confirmed_at)) / 3600, 72) * 0.8
    + (case when c.id is not null then 40 else 0 end)
  from listings l
  join products p     on p.id = l.product_id
  join wholesalers w  on w.id = l.wholesaler_id
  cross join shop
  left join campaigns c
         on c.listing_id = l.id
        and c.status = 'running'
        and now() between c.starts_at and c.ends_at
  where l.status = 'live'
    and l.stock <> 'out'
    and (l.ends_at is null or l.ends_at > now())
    and st_dwithin(w.location, shop.location, p_radius_km * 1000)
  order by score desc
  limit p_limit;
$$;

-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================
alter table wholesalers        enable row level security;
alter table wholesaler_users   enable row level security;
alter table products           enable row level security;
alter table listings           enable row level security;
alter table shops              enable row level security;
alter table favourites         enable row level security;
alter table price_alerts       enable row level security;
alter table order_requests     enable row level security;
alter table order_request_items enable row level security;
alter table campaigns          enable row level security;
alter table campaign_events    enable row level security;
alter table events             enable row level security;

-- Helper: does the current user own this wholesaler?
create or replace function owns_wholesaler(w_id uuid)
returns boolean language sql stable security definer as $$
  select exists (
    select 1 from wholesaler_users
     where user_id = auth.uid() and wholesaler_id = w_id
  );
$$;

-- Public read: anyone can browse wholesalers, products, live listings
create policy "public read wholesalers" on wholesalers for select using (true);
create policy "public read products"    on products    for select using (true);
create policy "public read live listings" on listings  for select using (status = 'live');

-- Wholesalers manage their own records
create policy "wholesaler updates self" on wholesalers
  for update using (owns_wholesaler(id));

create policy "wholesaler manages listings" on listings
  for all using (owns_wholesaler(wholesaler_id))
  with check (owns_wholesaler(wholesaler_id));

create policy "wholesaler manages campaigns" on campaigns
  for all using (owns_wholesaler(wholesaler_id))
  with check (owns_wholesaler(wholesaler_id));

-- Wholesaler sees only AGGREGATE campaign events, never raw shop identity.
-- Reads go through the campaign_results view, not this table.
create policy "wholesaler reads own campaign events" on campaign_events
  for select using (
    exists (select 1 from campaigns c
             where c.id = campaign_id and owns_wholesaler(c.wholesaler_id))
  );

-- Wholesaler sees order requests sent TO them (the shop chose to contact them)
create policy "wholesaler reads own requests" on order_requests
  for select using (owns_wholesaler(wholesaler_id));

create policy "wholesaler updates own requests" on order_requests
  for update using (owns_wholesaler(wholesaler_id));

-- Shops own their own data
create policy "shop reads self" on shops
  for select using (user_id = auth.uid());
create policy "shop updates self" on shops
  for update using (user_id = auth.uid());

create policy "shop manages favourites" on favourites
  for all using (
    exists (select 1 from shops s where s.id = shop_id and s.user_id = auth.uid())
  );

create policy "shop reads own alerts" on price_alerts
  for select using (
    exists (select 1 from shops s where s.id = shop_id and s.user_id = auth.uid())
  );

create policy "shop manages own requests" on order_requests
  for insert with check (
    exists (select 1 from shops s where s.id = shop_id and s.user_id = auth.uid())
  );
create policy "shop reads own requests" on order_requests
  for select using (
    exists (select 1 from shops s where s.id = shop_id and s.user_id = auth.uid())
  );

-- Line items follow their parent request
create policy "read own request items" on order_request_items
  for select using (
    exists (
      select 1 from order_requests o
       where o.id = request_id
         and (
           owns_wholesaler(o.wholesaler_id)
           or exists (select 1 from shops s where s.id = o.shop_id and s.user_id = auth.uid())
         )
    )
  );

create policy "shop writes own request items" on order_request_items
  for insert with check (
    exists (
      select 1 from order_requests o
        join shops s on s.id = o.shop_id
       where o.id = request_id and s.user_id = auth.uid()
    )
  );

-- A user can see which wholesalers they belong to
create policy "read own membership" on wholesaler_users
  for select using (user_id = auth.uid());

-- Events are write-only from the client
create policy "anyone writes events" on events for insert with check (true);
create policy "anyone writes campaign events" on campaign_events for insert with check (true);
