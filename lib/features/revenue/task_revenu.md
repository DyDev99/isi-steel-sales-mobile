You are a Senior Flutter Architect.

## Objective

Implement the `/revenue` feature **UI only**, matching the provided design while following the existing project architecture. Do **not** implement APIs or business logic.

## Architecture (Strict)

```
feature/revenue/
├── data/
│   ├── datasource/
│   │   ├── local/
│   │   └── remote/
│   ├── models/
│   ├── repositories/
│   └── mock/
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
└── presentation/
    ├── bloc/
    ├── screens/
    ├── widgets/
    └── mapper/
```

## Rules

* Follow this architecture exactly.
* Never create files outside this feature.
* Reuse existing design system, theme, colors, spacing, typography, and shared widgets.
* Preserve navigation, routing, and project structure.
* Modify only files required for `/revenue`.
* Do not rewrite unchanged files.
* Generate production-ready, maintainable code.

## Layer Responsibilities

### data

* Store mock data only.
* Models represent raw data.
* Repository implementations return mock data.
* No UI code.

### domain

* Entities are UI-independent.
* Repository interfaces only.
* UseCases expose business operations.
* No Flutter imports.

### presentation

* Bloc manages UI state only.
* Screens compose widgets.
* Widgets are small, reusable, and preferably stateless.
* Mapper converts Entities → UI ViewModels when needed.
* Never access the data layer directly from widgets.

## Revenue Screen

Build these sections:

* Search Bar
* Customer Credit Summary
* Product Grid/List
* Discount Card
* Category Card (horizontal scroll)
* Cart Summary
* Fixed Bottom Action Bar

## UI Interactions (Mock Only)

* Search products
* Select category
* Select discount chip
* Increase/decrease quantity
* Update totals using mock data
* Show selected states
* Handle loading, empty, and error states

## Quality

* Responsive layout.
* Pixel-perfect implementation.
* Reusable widgets.
* Minimal widget rebuilds.
* Clean Bloc state management.
* Consistent naming.
* Follow SOLID and Clean Architecture.

## Output

* Generate only the necessary files.
* Explain file creation briefly.
* Do not generate backend, API, database, or networking code unless requested later.
