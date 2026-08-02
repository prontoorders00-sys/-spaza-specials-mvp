-- ============================================================
-- 0003_grants_and_policies.sql
--
-- A) TABLE GRANTS — "Automatically expose new tables" is DISABLED
--    in this Supabase project, so every table needs an explicit
--    GRANT before PostgREST can reach it. RLS governs which ROWS
--    are visible; without the grant the query never starts and
--    returns "permission denied for table X".
--
-- B) ROLE-SCOPED POLICIES — policies that call owns_wholesaler()
--    must be TO authenticated. Anonymous callers have no EXECUTE
--    on that function and the query dies with "permission denied
--    for function owns_wholesaler" before RLS runs.
-- ============================================================

-- ============================================================
-- 1. FUNCTION HARDENING
-- ============================================================
alter function public.owns_wholesaler(uuid)                 set search_path = public, pg_temp;
alter function public.feed_for_shop(uuid, integer, integer) set search_path = public, pg_temp;
alter function public.record_price_change()                 set search_path = public, pg_temp;
alter function public.touch_listing_updated_at()            set search_path = public, pg_temp;
alter function public.expire_stale_specials()               set search_path = public, pg_temp;

revoke execute on function public.owns_wholesaler(uuid)   from public;
revoke execute on function public.expire_stale_specials() from public;
grant  execute on function public.owns_wholesaler(uuid)   to authenticated;
grant  execute on function public.feed_for_shop(uuid, integer, integer) to anon, authenticated;

-- ============================================================
-- 2. TABLE GRANTS
-- ============================================================
grant select on public.wholesalers to anon;
grant select on public.products    to anon;
grant select on public.listings    to anon;
grant insert on public.events          to anon;
grant insert on public.campaign_events to anon;

grant select on public.wholesalers      to authenticated;
grant select on public.products         to authenticated;
grant select on public.wholesaler_users to authenticated;
grant select on public.campaign_results to authenticated;
grant select on public.price_history    to authenticated;
grant update on public.wholesalers      to authenticated;
grant select, insert, update, delete on public.listings   to authenticated;
grant select, insert, update, delete on public.campaigns  to authenticated;
grant select, update on public.shops to authenticated;
grant select, insert, update, delete on public.favourites to authenticated;
grant select on public.price_alerts to authenticated;
grant select, insert, update on public.order_requests      to authenticated;
grant select, insert         on public.order_request_items to authenticated;
grant select, insert on public.campaign_events to authenticated;
grant insert on public.events to authenticated;

grant usage, select on sequence public.events_id_seq          to anon, authenticated;
grant usage, select on sequence public.campaign_events_id_seq to anon, authenticated;
grant usage, select on sequence public.price_history_id_seq   to authenticated;

-- ============================================================
-- 3. ROLE-SCOPED POLICIES
--
-- Drop every policy created in 0001_init.sql and recreate with
-- explicit TO roles. Policies calling owns_wholesaler() are
-- scoped TO authenticated so anon callers never attempt to
-- execute the function. Public-read policies are scoped
-- TO anon, authenticated.
-- ============================================================

-- ---- listings ----
drop policy if exists "public read live listings"      on public.listings;
drop policy if exists "wholesaler manages listings"    on public.listings;

create policy "public read live listings"
  on public.listings for select
  to anon, authenticated
  using (status = 'live');

create policy "wholesaler selects own listings"
  on public.listings for select
  to authenticated
  using (owns_wholesaler(wholesaler_id));

create policy "wholesaler inserts own listings"
  on public.listings for insert
  to authenticated
  with check (owns_wholesaler(wholesaler_id));

create policy "wholesaler updates own listings"
  on public.listings for update
  to authenticated
  using (owns_wholesaler(wholesaler_id))
  with check (owns_wholesaler(wholesaler_id));

create policy "wholesaler deletes own listings"
  on public.listings for delete
  to authenticated
  using (owns_wholesaler(wholesaler_id));

-- ---- wholesalers ----
drop policy if exists "public read wholesalers"  on public.wholesalers;
drop policy if exists "wholesaler updates self"  on public.wholesalers;

create policy "public read wholesalers"
  on public.wholesalers for select
  to anon, authenticated
  using (true);

create policy "wholesaler updates self"
  on public.wholesalers for update
  to authenticated
  using (owns_wholesaler(id));

-- ---- products ----
drop policy if exists "public read products" on public.products;

create policy "public read products"
  on public.products for select
  to anon, authenticated
  using (true);

-- ---- campaigns ----
drop policy if exists "wholesaler manages campaigns" on public.campaigns;

create policy "wholesaler manages campaigns"
  on public.campaigns for all
  to authenticated
  using (owns_wholesaler(wholesaler_id))
  with check (owns_wholesaler(wholesaler_id));

-- ---- campaign_events ----
drop policy if exists "wholesaler reads own campaign events" on public.campaign_events;
drop policy if exists "anyone writes campaign events"        on public.campaign_events;

create policy "wholesaler reads own campaign events"
  on public.campaign_events for select
  to authenticated
  using (
    exists (
      select 1 from public.campaigns c
       where c.id = campaign_id
         and owns_wholesaler(c.wholesaler_id)
    )
  );

create policy "anyone writes campaign events"
  on public.campaign_events for insert
  to anon, authenticated
  with check (true);

-- ---- order_requests ----
drop policy if exists "wholesaler reads own requests"  on public.order_requests;
drop policy if exists "wholesaler updates own requests" on public.order_requests;
drop policy if exists "shop manages own requests"      on public.order_requests;
drop policy if exists "shop reads own requests"        on public.order_requests;

create policy "wholesaler reads own requests"
  on public.order_requests for select
  to authenticated
  using (owns_wholesaler(wholesaler_id));

create policy "wholesaler updates own requests"
  on public.order_requests for update
  to authenticated
  using (owns_wholesaler(wholesaler_id));

create policy "shop reads own requests"
  on public.order_requests for select
  to authenticated
  using (
    exists (select 1 from public.shops s where s.id = shop_id and s.user_id = auth.uid())
  );

create policy "shop writes own requests"
  on public.order_requests for insert
  to authenticated
  with check (
    exists (select 1 from public.shops s where s.id = shop_id and s.user_id = auth.uid())
  );

-- ---- order_request_items ----
drop policy if exists "read own request items"       on public.order_request_items;
drop policy if exists "shop writes own request items" on public.order_request_items;

create policy "read own request items"
  on public.order_request_items for select
  to authenticated
  using (
    exists (
      select 1 from public.order_requests o
       where o.id = request_id
         and (
           owns_wholesaler(o.wholesaler_id)
           or exists (select 1 from public.shops s where s.id = o.shop_id and s.user_id = auth.uid())
         )
    )
  );

create policy "shop writes own request items"
  on public.order_request_items for insert
  to authenticated
  with check (
    exists (
      select 1 from public.order_requests o
        join public.shops s on s.id = o.shop_id
       where o.id = request_id and s.user_id = auth.uid()
    )
  );

-- ---- price_history ----
drop policy if exists "wholesaler reads own price history" on public.price_history;

create policy "wholesaler reads own price history"
  on public.price_history for select
  to authenticated
  using (
    exists (
      select 1 from public.listings l
       where l.id = listing_id
         and owns_wholesaler(l.wholesaler_id)
    )
  );

-- ---- shops ----
drop policy if exists "shop reads self"   on public.shops;
drop policy if exists "shop updates self" on public.shops;

create policy "shop reads self"
  on public.shops for select
  to authenticated
  using (user_id = auth.uid());

create policy "shop updates self"
  on public.shops for update
  to authenticated
  using (user_id = auth.uid());

-- ---- favourites ----
drop policy if exists "shop manages favourites" on public.favourites;

create policy "shop manages favourites"
  on public.favourites for all
  to authenticated
  using (
    exists (select 1 from public.shops s where s.id = shop_id and s.user_id = auth.uid())
  );

-- ---- price_alerts ----
drop policy if exists "shop reads own alerts" on public.price_alerts;

create policy "shop reads own alerts"
  on public.price_alerts for select
  to authenticated
  using (
    exists (select 1 from public.shops s where s.id = shop_id and s.user_id = auth.uid())
  );

-- ---- wholesaler_users ----
drop policy if exists "read own membership" on public.wholesaler_users;

create policy "read own membership"
  on public.wholesaler_users for select
  to authenticated
  using (user_id = auth.uid());

-- ---- events ----
drop policy if exists "anyone writes events" on public.events;

create policy "anyone writes events"
  on public.events for insert
  to anon, authenticated
  with check (true);

-- ============================================================
-- Verified live (2026-08-02):
--   AS anon  — a live listing IS visible; a draft is NOT;
--              INSERT on listings is refused;
--              shops / order_requests / wholesaler_users are
--              unreadable (permission denied);
--              SELECT owns_wholesaler(...) is refused
--              (permission denied for function);
--              feed_for_shop(...) executes successfully.
-- ============================================================
