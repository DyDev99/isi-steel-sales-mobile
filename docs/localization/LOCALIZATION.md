# Localization Guide

> ISI Steel Sales Mobile · How the multilingual system works and how to extend it.
> Companion: `STRING_ANALYSIS_REPORT.md` (the migration analysis that produced this system).
> Last updated: 2026-07-22.

---

## 1. Overview

The app ships **English (`en`)** and **Khmer (`km`)**, fully key-based:

- **841 keys** per language file, verified at parity (`en.json` ⇄ `km.json` key-diff = ∅).
- **Zero hardcoded user-facing strings** in presentation code (mock/demo data, brand names
  like "ISI STEEL", and unit codes like `Pc`/`Ton` are deliberately excluded).
- Live, in-place language switching — no restart. Selection persists across launches.

## 2. Architecture

```
presentation                     domain                        data
────────────                     ──────                        ────
LanguageCubit ──────────────────▶ ChangeLanguage ─────────────▶ LanguageRepositoryImpl
(state: Locale, consumed          GetCurrentLanguage             ├─ LanguageLocalDatasource
 by MaterialApp in app.dart)      GetSupportedLanguages           │   (Hive AppPreferences,
LanguageSection /                 RestoreSavedLanguage            │    legacy kh→km migration)
LanguageSelectorSheet             LanguageRepository (interface)  └─ LanguageManager (core)
LanguageSelectionScreen           LanguageEntity                      └─ LocalizationService
MainAppBar language menu                                                 (loads assets/lang/<code>.json,
                                                                          ChangeNotifier → LocalizedBuilder)
```

| Piece | File | Role |
|---|---|---|
| `LocalizationService` | `core/localization/localization_services.dart` | Flattened key store; `'key'.tr` / `'key'.trParams({...})`; notifies on reload |
| `LocalizedBuilder` | `core/localization/localized_builder.dart` | Rebuilds a subtree the instant the language changes |
| `LanguageManager` | `core/localization/language_manager.dart` | The one place that *applies* a language (loads bundle + notifies) |
| `LanguageEntity` | `features/localization/domain/entities/` | Pure value: `code`, `nameKey`, `regionKey`, `flag` |
| `LanguageRepository` | `features/localization/domain/repositories/` | Sync reads (no wrong-language flash on boot), async writes |
| Usecases | `features/localization/domain/usecases/` | `GetCurrentLanguage`, `GetSupportedLanguages`, `ChangeLanguage`, `RestoreSavedLanguage` |
| `LanguageModel` | `features/localization/data/models/` | **The shipped catalog** (`LanguageModel.supported`) + `fromCode` fallback |
| `LanguageLocalDatasource` | `features/localization/data/datasources/` | Hive persistence; migrates legacy stored `kh` → `km` on first read |
| `LanguageRepositoryImpl` | `features/localization/data/repositories/` | Wires datasource + manager; domain sees only entities |
| `LanguageCubit` | `features/localization/presentation/bloc/` | `Cubit<Locale>`; calls usecases only; runs startup restoration |
| DI | `features/localization/localization_injection.dart` | `registerLocalizationFeature(sl)` from `core/di/injection_container.dart` |

**Widgets never touch `LocalizationService` for switching** — they go through
`LanguageCubit` → usecases. Reading (`'key'.tr`) stays on the String extension by design.

## 3. UI surfaces

- **Profile → Language section** (`features/localization/presentation/widgets/language_section.dart`)
  — row showing the active flag + native name; opens the selector sheet.
- **Language selector sheet** (`language_selector_sheet.dart`) — native name, region line, flag,
  animated radio → spinner while switching; the sheet itself re-renders in the new language
  before dismissing.
- **Onboarding** (`features/splash/presentation/language_selection_screen.dart`) and the
  **app-bar menu** (`features/shell/.../main_app_bar.dart`) — both render from
  `LanguageCubit.supportedLanguages`, so they update automatically when the catalog grows.

## 4. Startup restoration

`LanguageCubit` (a lazy singleton provided above `MaterialApp`) seeds its `Locale`
synchronously from the repository, then fire-and-forgets `RestoreSavedLanguage` to load the
bundle. `app.dart` keys `MaterialApp` on `locale.languageCode`, so a language change rebuilds
the navigator and `AppTypography.fontFamilyForLocale` picks **Kantumruy** for `km`
(fixed by the `kh → km` code migration — the old non-ISO `kh` code never matched).

## 5. Key naming rules

- Feature-first, dot-separated: `leads.hq.finish_onboarding`, `my_visits.depot.search_hint`,
  `sync.discard_draft_title`. Cross-feature phrases live in `common.*`
  (`common.cancel`, `common.save`, `common.filter_sort`, `common.any`, …).
- Parameters use `{name}` placeholders resolved with `.trParams`:
  `'sync.checkin_progress'.trParams({'done': done, 'total': total})`.
- Never generic (`title1`, `text1`); never leave a literal English string in a widget.
- `.tr` is **not const** — never place it in a `const` constructor, `const` map, enum
  constructor, or a constructor default. For enums, store the *key* and expose
  `String get label => labelKey.tr` (see `DueUrgency`, `FilterFacet`).

## 6. Adding a string

1. Add the key to **both** `assets/lang/en.json` and `assets/lang/km.json` (nested form).
2. Use `'feature.key'.tr` (or `.trParams`) in the widget.
3. Parity check (CI-able):
   every `'…'.tr` key in `lib/` must exist in `en.json`, and `en.json` ⇄ `km.json`
   key sets must be identical.

## 7. Adding a language (e.g. Chinese later)

1. Drop `assets/lang/<code>.json` (translate from `en.json`; identical key set).
2. Add one `LanguageModel` entry to `LanguageModel.supported`
   (`features/localization/data/models/language_model.dart`).
3. Add its `language.<name>` / `language.<name>_region` keys to **every** bundle.
4. If the script needs a dedicated font, extend `AppTypography.fontFamilyForLocale`.

Nothing else changes — every selector UI is catalog-driven.

## 8. Deliberate exclusions

- **Mock/demo data** (`data/mock/*`, seed fixtures, demo names/products/cities) — replaced by
  SAP data in production; localizing it would be wasted churn.
- **Brand strings** ("ISI STEEL", "ISI Steel Sales" as PDF author/file names).
- **Unit codes** (`Pc`, `Ton`, `Kg`, `m`, `mm`) — SAP unit vocabulary.
- **Dev-facing text** (asserts, `FlutterError`, debug-fixture hints, log lines).
- The quotation **PDF** localizes through its own `_l(key, fallback)` helper against
  `orders.quotation.pdf.*` — a Khmer session produces a Khmer document.

## 9. Known follow-ups

- ~190 keys in the bundles are referenced only dynamically (coach steps via
  `titleKey`/`messageKey`, enum `labelKey`s, notification kinds) — a naive "unused key"
  lint must account for these.
- Widget/golden tests for the language selector (en + km light/dark) per
  `ENGINEERING_STANDARD.md` §10 are not yet written — this refactor predates the test
  infrastructure sprints in `MIGRATION_PLAN.md`.
