# Order — Workflow & Structure

Sales-catalog / quotation / sales-order feature for field reps. Offline-first: the product catalog is synced into a local DB and browsed offline; cart, quotation, and sales-order data are purely local (SAP is mocked at the point of "conversion", not synced in the background).

## 1. Folder structure (clean architecture)

```
order/
├── data/
│   ├── local/         # sqlite catalog DB, cart/product/quotation/sales-order local sources
│   ├── mock/           # mock product generator (dev backend)
│   ├── models/         # ProductModel, CategoryModel (DTOs)
│   ├── remote/         # ProductRemoteDataSource + RemoteSyncPage / RemoteDeltaPage
│   ├── repositories/    # repository implementations
│   └── services/        # MockCreditService, MockMtoPricingService
├── domain/
│   ├── entities/        # Product, CartItem, Quotation, SalesOrder, OffVisitReason, MtoQuote, CreditSummary, ...
│   ├── repositories/     # abstract repository contracts
│   ├── services/         # BarcodeScannerService, VoiceSearchService, ImageSearchService, CreditService, MtoPricingService, OrderLocationService
│   └── usecases/          # one class per action (BrowseProducts, SaveQuotation, CreateSalesOrder, ...)
├── presentation/
│   ├── bloc/               # CartCubit, CatalogBloc, ProductDetailCubit, SyncCubit
│   ├── screens/            # see workflow below
│   ├── widgets/            # product cards, cart tiles, discount section, credit card, etc.
│   └── services/           # real implementations (mobile_scanner, speech_to_text, image_picker, geolocator)
└── order_injection.dart      # DI wiring
```

## 2. Three entry points

### A. Direct / tab entry (full path, off-visit gate always applies)
`OrderScreen` (bottom-nav tab) → `TerritoryScreen` → `ShopListScreen` → `ShopOrderEntryScreen` → `QuotationBuilderScreen`

### B. Hand-off from `my_visits` (Route Stock Count)
`RouteStockCountScreen` ("Build Quotation") pushes straight into `ShopListScreen(territory:, skipOffVisitCheck: true, seedSearchTerm: <out-of-stock item>)` — skips territory-picking's need and the off-visit gate, since the rep is provably already on a checked-in visit, and pre-seeds the catalog search.

### C. Hand-off from Lead
`LeadDetailScreen` opens `QuotationBuilderScreen(leadId:, leadDisplayName:)` directly — no territory/shop/off-visit steps, because a lead has no SAP `Customer` record yet. Lead-scoped quotations **cannot** be converted to a sales order later.

## 3. Step-by-step: full order path

| Step | Screen | What happens | Next |
|---|---|---|---|
| 0 | `OrderScreen` | Tab root. Shows "New Order" button + merged recent list of quotations/sales orders (`WatchQuotations`/`WatchSalesOrders`) | "New Order" → Step 1 |
| 1 | `TerritoryScreen` | Lists territories grouped from `BrowseCustomers`, with shop counts | Tap territory → Step 2 |
| 2 | `ShopListScreen` | Lists shops in the territory, each with a lazily-loaded credit badge | Tap shop → Step 3 |
| 3 | `ShopOrderEntryScreen` | Shows shop info, credit summary, captures GPS once. If not skipped, blocks progress until an `OffVisitReason` is picked via a bottom sheet | "Start Quotation" → Step 4 |
| 4 | `QuotationBuilderScreen` | Catalog browse/search (text/voice/image), category & size/quality filters, add-to-cart, inline product detail, discounts, cart preview. Sync runs on init | "Save" → Step 5 |
| 5 | `QuotationDetailScreen` | Read-only summary of the saved quotation (lines, totals, status). "Convert to Sales Order" is disabled for lead-scoped quotations | "Convert" → Step 6, or "Edit Quotation" → back to Step 4 (edit mode) |
| 6 | `SalesOrderScreen` | Editable line list seeded from the quotation (qty change/remove), "Create Sales Order in SAP" (mocked — freezes totals, no repricing) | Success → Step 7 |
| 7 | `OrderSuccessScreen` | Terminal screen — shows the confirmed sales order. "Done" pops to app root | — |

Search modalities (barcode, voice, image) all resolve to a text query and feed the same `CatalogBloc` pipeline (barcode is the exception — it resolves directly to a single product via `GetProductByBarcode`, though it isn't currently wired to a button in the search bar).

## 4. State machines

**`QuotationStatus`**: `draft` (transient, UI-only, never persisted) → `saved` (persisted/editable) → `converted` (intended once a sales order is created — note: `SalesOrderRepositoryImpl.createFromQuotation` does not appear to call `markConverted`, worth verifying whether this transition actually fires).

**`SalesOrderStatus`**: two-value enum `{pending, confirmed}` — `pending` is never assigned in practice; every created sales order jumps straight to `confirmed` (mocked SAP confirmation, no repricing).

**`ProductStatus`**: `active / inactive / discontinued`. `Product.isAvailable` requires `availableQuantity > 0 && status == active`.

## 5. State management (bloc/cubit)

- **`CartCubit`** — in-memory + locally-persisted cart. `addProduct` merges into an existing line by product+lead+customer; `loadFromQuotation` seeds the cart from a saved quotation (edit / convert-to-sales-order flows); `saveQuotation` creates or updates a `Quotation` and clears the cart on success.
- **`CatalogBloc`** — paginated (30/page) product grid. `CatalogIdle` landing state means no fetch until the first query/filter. Uses `droppable()` for load/refresh/loadMore and `restartable()` for search/filter/voice/image so fast typing never races. All four query types funnel through one shared `_runQuery()`; search is debounced 300ms.
- **`ProductDetailCubit`** — powers the inline expanded product detail (variants, per-warehouse stock, favorite, records as "recently viewed").
- **`SyncCubit`** — `syncIfNeeded()` runs full initial sync if never synced; `refresh()` always runs delta sync. Drives the sync status banner.

## 6. Domain usecases (grouped)

- **Catalog browsing/search**: `BrowseProducts`, `FetchBrands`, `FetchCategories`, `FetchFavorites`, `FetchRecentProducts`, `GetProductByBarcode`, `GetProductById`, `GetProductVariants`, `GetProductsByCategory`, `GetWarehouseStock`, `RecordViewed`, `ToggleFavorite`, `GetPricing`
- **Cart**: `AddToCart`, `UpdateCartItem`, `RemoveFromCart`, `ClearCart`, `FetchCart`, `ReplaceCart`
- **Quotation**: `SaveQuotation`, `UpdateQuotation`, `GetQuotationById`, `WatchQuotations`
- **Sales order**: `CreateSalesOrder`, `GetSalesOrderById`, `WatchSalesOrders`
- **Sync**: `RunInitialSync`, `RunDeltaSync`, `GetLastSyncedAt`
- **MTO pricing**: `RequestMtoQuote`
- **Credit**: `GetCreditSummary`
- **Location**: `CaptureLocationOnce` (one-shot GPS snapshot, distinct from `my_visits`' continuous route tracking)

## 7. Off-visit handling

- **`OffVisitReason`**: `phoneOrder | urgentRestock | passingBy` — why a rep is ordering without being on a scheduled/checked-in visit.
- **`skipOffVisitCheck`**: threaded `ShopListScreen → ShopOrderEntryScreen`, default `false` (gate on for the direct/tab path). Only the `my_visits` Route Stock Count hand-off sets it `true`.
- **Gate behavior**: not a hard block — the rep simply cannot proceed to the builder without picking a reason from the bottom sheet; dismissing the sheet just leaves them on the entry screen. Once picked, the reason is stored on the quotation/sales order and shown later on `OrderSuccessScreen`/`QuotationDetailScreen`.

## 8. MTO pricing & credit check (both advisory, non-blocking)

- **MTO pricing** (`MtoPricingService`/`RequestMtoQuote`) — for `Product.isMto` SKUs, pricing is never resolved from the local table; always a fresh "SAP" quote request. Mock: offline → unavailable message; online → `standardPrice * 1.15` with a "confirm with SAP" disclaimer.
- **Credit check** (`CreditService`/`GetCreditSummary`) — outstanding balance + credit/debit notes, deterministically mocked per customer. Purely informational — nothing blocks quotation/order creation on a bad credit position; the UI just displays the badge (and hides itself if the lookup is unavailable).

## 9. Sync

Same idle/in-progress/succeeded/failed cubit shape as `my_visits`' route sync, but catalog-scoped only (products + categories), keyed by `SyncScope.forCurrentUser`. `SyncRepositoryImpl` is the only repository allowed to touch `ProductRemoteDataSource`. Initial sync pages through the backend (500/page), upserting products after each page and syncing all categories up front. Delta sync fetches everything changed since the last sync (falls back to a full initial sync if never synced) and applies upserts + deletes. Cart/quotation/sales-order data is never synced remotely — it's purely local, "SAP" is only mocked at the point of conversion.

## 10. Known gaps / things to verify or flag

- Barcode scanning (`BarcodeScannerService`/`GetProductByBarcode`) exists end-to-end but isn't currently wired to a button in `CatalogSearchBar` — dead entry point until hooked up.
- `QuotationStatus.converted` may never actually get set — `SalesOrderRepositoryImpl.createFromQuotation` doesn't appear to call `markConverted()` on the source quotation. Worth confirming before relying on that status in reporting/UI.
- `OrderSuccessScreen`'s `onNewOrder` callback is scaffolded (doc comment says it's meant to be hidden for Lead/Route-Stock-Count entry points) but is never actually passed from `SalesOrderScreen` today — the "New Order" action is unreachable.
- Tapping a confirmed sales-order row on `OrderScreen`'s recent list does nothing (`onTap: null`) — only quotations are tappable there.
