# Supported Device Matrix

Fill in real device names and OS versions based on your users' analytics.

| Platform | Class | Example device | OS version | Screen | Manual | Automated (E2E) |
|---|---|---|---|---|---|---|
| Android | Small | _e.g. low-end 5.5" phone_ | Min supported | ~360×640 dp | ✅ | ⬜ |
| Android | Medium | _e.g. mid-range 6.5"_ | Most common | ~412×915 dp | ✅ | ✅ (emulator in CI) |
| Android | Large | _e.g. 10" tablet_ | Latest | ~800×1280 dp | ✅ | ⬜ |
| iOS | Small | _e.g. iPhone SE_ | Min supported | 375×667 pt | ✅ | ⬜ |
| iOS | Medium | _e.g. standard iPhone_ | Latest − 1 | ~390×844 pt | ✅ | ✅ (simulator) |
| iOS | Large | _e.g. Pro Max / iPad_ | Latest | ~430×932 pt | ✅ | ⬜ |

Widget tests already check layout at 320×568, 412×915 and 800×1280 logical pixels (see `customer_form_test.dart`).

## Device-specific checks
- Manufacturer battery optimisation killing background sync (Android)
- Location / camera permission dialogs on each OS version
- Keyboard covering the Submit button on small screens
- Dark mode and large system font size
