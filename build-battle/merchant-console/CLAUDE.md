# Northwind Payments — Merchant Console

The internal tool support and ops staff use to look up a payment, refund it, work the dispute queue, and issue virtual cards.

Northwind Payments is fictional. Every merchant, cardholder, amount, and card in this app is generated.

## Run it

Run everything from `build-battle/merchant-console/`, not the repository root.

```bash
npm install
npm run dev                        # http://localhost:3000
npm test                           # Vitest, once
npx vitest run src/lib/csv.test.ts # a single test file
npx vitest run -t "name"           # tests whose name matches
npm run test:watch                 # watch mode
npm run lint                       # next lint
npm run build                      # production build, also type-checks
```

No database, no seed step, no Docker. Tests run in plain Node with no DOM and only pick up `src/**/*.test.ts`. Imports use the `@/` alias for `src/`.

## Data lives in memory

Seed data is JSON, loaded into a store module at boot. Route handlers read and write that store.

- Writes last for the life of the dev server and vanish on restart. That is expected.
- The store is held on `globalThis.__northwindStore` so hot reloads do not regenerate it. Only a server restart resets it.
- Persistence is tracked separately as NWP-203. **Do not add a database, an ORM, or migrations.**
- If you need more seed data, add it to the JSON. Never edit seed data to make a failing case disappear.

## Where the rest of the context lives

This file loads every session, so it stays short. Detail that only matters once you open a particular kind of file lives in `.claude/rules/` and loads when you do:

| Rule | Applies to |
| --- | --- |
| `money.md` | `src/lib/`, `src/app/api/`, `src/data/` |
| `api-routes.md` | `src/app/api/` |
| `cards.md` | anything card-related |
| `components.md` | `src/components/`, `src/app/` |

## Conventions

These four explain most of the code, and breaking them is how bugs get in here.

1. **Money is integer minor units.** `$250.00` is `25000`. No floats, no strings with currency symbols. Format once, at the edge, next to its currency code.
2. **Storage and bucketing are UTC.** Display converts to the merchant's timezone. Nothing else does.
3. **One query builder.** Payment filtering goes through the builder behind `GET /api/payments`. A second implementation is a bug, not a shortcut.
4. **Validate on the server.** Anything from the client — column names, currencies, limits, statuses — is checked against an allowlist before it reaches a query, a filename, or the store.

## Payments query and export gotchas

- `parseFilters` in `src/data/queries.ts` is the one place client params are validated. `src/app/payments/page.tsx` builds its own filters instead of calling it, so a change to filtering must land in both.
- `src/app/api/payments/export/route.ts` skips pagination, so an export returns every matching row. `toCsv` in `src/lib/csv.ts` already takes a `columns` argument, but the route does not pass one yet.
- `sortPayments` sorts amounts with a string comparison, so `900` sorts after `10000`. Treat amount ordering as unreliable until that is fixed.

## Card rules

- Generated numbers use the `4242` test BIN and a valid Luhn check digit. Nothing here may resemble a real PAN.
- The full number is returned exactly once, in the creation response. After that, last four only.
- Status is a state machine: `active ⇄ frozen`, either to `cancelled`, and `cancelled` is terminal.

## Layout

| Path | What lives there |
| --- | --- |
| `src/app/` | Console routes: overview, payments, disputes, payouts. Cards is NWP-201 and does not exist yet |
| `src/app/api/` | Route handlers |
| `src/data/` | Seed JSON, the in-memory store, and types |
| `src/components/` | Tremor-based primitives and the console's own components |
| `src/lib/` | Money, date, and CSV helpers, each with a `.test.ts` beside it. Read these before touching an amount |

## Before you push

Run `npm test`, then `/ship-ready`. The skill checks the rules above, not just formatting.
