# Build Plan

## The stack decision, and why

**Mobile web (PWA), not an app-store app.**

A spaza owner with a R900 Android and 500MB of data will not download a 40MB app
to check prices. They will tap a WhatsApp link. Every real constraint points the
same way:

| Constraint | What it forces |
|---|---|
| Low-end Android, little storage | No app download |
| Expensive prepaid data | Small bundle, aggressive caching |
| Distribution is WhatsApp groups | A link must open the thing |
| You need to change it daily during the pilot | Instant deploy, no review queue |

Next.js + Supabase + Vercel gives you a site that loads in ~2 seconds on 3G,
installs to the home screen if they want it, and ships on `git push`.

### On FlutterFlow

Your sister knows FlutterFlow, and that's real value — don't waste it. But
Flutter's *web* output is a heavy bundle, which is exactly wrong for this
audience. Two options:

1. **Best:** she owns Supabase — schema, policies, edge functions, the WhatsApp
   webhook. That's the harder half and it's stack-independent.
2. **If she'd rather build UI:** she builds the *wholesaler portal* in
   FlutterFlow. Wholesalers sit at a desk on wifi; bundle size doesn't matter
   there. The shop-owner side stays web.

Revisit a native app when you have 1,000+ weekly active shops and a reason
(push notifications, offline). Not before.

---

## Phase 0 — Prove it with no code (Weeks 1–4)

**Do not write software yet.** The prototype is enough to sell with.

- Sign 3 wholesalers. Koshin is #1 — you control the data, so it's perfect.
- Collect their flyers/price lists. You maintain the listings by hand.
- Create a WhatsApp group: "Tembisa Specials". Add 50–100 shop owners.
- Every morning at 05:00, post the day's specials as an image + text.
- Track by hand in a spreadsheet: who replies, who asks for what, who buys.

**What you're testing:** do shop owners engage with a daily deals drop at all?

**Kill criteria:** if fewer than 20% of the group reacts or replies in week 2,
the problem is not your software. Stop and find out why before building.

**Cost: R0.**

---

## Phase 1 — Shop-owner web app (Weeks 5–8)

Only build this once Phase 0 shows engagement.

```
/                    feed — specials + stock, sorted by distance
/p/[listingId]       product detail
/cart                order request, grouped by wholesaler
/saved               favourites + price-drop alerts
/w/[slug]            wholesaler profile
```

**Must have:**
- Phone-number auth (Supabase OTP over SMS)
- Search with the alias table (this is your moat — see `0002_seed_products.sql`)
- 5 languages, stored on the shop record
- Cart → structured WhatsApp deep link
- Works offline for the last-loaded feed

**Deliberately not yet:** payments, delivery, ratings, streaks, gamification.

The WhatsApp handoff is just a link — no API needed at this stage:

```
https://wa.me/27760000000?text=<url-encoded message>
```

---

## Phase 2 — Wholesaler portal (Weeks 9–12)

```
/wh/login
/wh                  dashboard
/wh/listings         specials + stock, with confirm-prices nudge
/wh/import           flyer upload → extraction → review → publish
/wh/requests         incoming order requests, confirm / partial / decline
```

**The single most important feature is `/wh/import`.** Every wholesaler will say
"I don't have time to load 50 products." Flyer import is the answer. Build it
before anything else in this phase.

Extraction pipeline:
1. Upload image/PDF to Supabase Storage
2. Edge function → vision model → structured JSON
3. Fuzzy-match each row to `products` (pg_trgm)
4. Anything below ~85% confidence gets flagged for human review
5. Wholesaler approves → listings created

**Freshness is the business.** Ship these together:
- `confirmed_at` on every listing
- Daily 05:00 WhatsApp: "Confirm today's prices" with a one-tap link
- Stale listings rank lower (already in `feed_for_shop`)
- Specials auto-expire

---

## Phase 3 — Campaigns (Weeks 13–16)

Only after ~200 weekly-active shops. You cannot sell reach you don't have.

```
/wh/boost/[listingId]    objective → audience → radius → budget → forecast
/wh/campaigns            list
/wh/campaigns/[id]       results: funnel, cost per enquiry, request value
```

Every number on the results screen comes from `campaign_events`. Never estimate
a delivered result — estimate only the forecast, and label it as an estimate.

**Pricing to test:** R200/1 day, R750/7 days, R1,500/14 days. Free listings
always.

---

## Order of work if you only have one developer

1. `0001_init.sql` + `0002_seed_products.sql` in Supabase — half a day
2. Feed + search + product detail — 1 week
3. Cart + WhatsApp deep link — 3 days
4. Phone auth + shop profile — 3 days
5. Wholesaler login + manual listing CRUD — 1 week
6. Flyer import — 1–2 weeks
7. Confirm-prices loop — 3 days
8. Saved + price-drop alerts — 4 days
9. Campaigns — 2 weeks

Roughly 8–10 weeks of one competent full-stack developer.

---

## Things that will bite you

**Duplicate products.** Two wholesalers list "ACE 12.5kg" as separate products
and comparison breaks. Always match to `products.id`. Never let a wholesaler
create a free-text product without a match or an admin review.

**Pack-size mismatch.** "10kg × 2" vs "20kg" are not the same purchase. Compare
on `base_qty` + `base_unit`, and show the per-kg price.

**VAT.** Decide now whether prices include VAT and label every price. Wholesale
is usually ex-VAT; shop owners often think in incl. Getting this wrong destroys
trust instantly.

**Loose vs bale pricing.** Your own Koshin rule: the single-unit price is always
higher than the per-unit box price. They are never proportional. Model them as
separate listings, not a calculated field.

**Phone numbers.** Store E.164 (`+27760000000`). Normalise on input. South
Africans type `0760000000`, `27 76 000 0000`, and `076-000-0000`.
