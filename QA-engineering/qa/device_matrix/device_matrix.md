# Supported Device Matrix: ISI Steel Sales Mobile

Targeted hardware profiles based on sales field team handset fleet in Cambodia.

| Platform | Tier | Target Hardware | OS Version | Display Resolution | RAM / Chipset | Testing Method |
|---|---|---|---|---|---|---|
| **Android** | Budget / Entry | Samsung Galaxy A05 / Vivo Y17s | Android 13/14 | 720 × 1600 (20:9) | 3GB - 4GB (Helio G85) | Physical Device (Field representative fleet standard) |
| **Android** | Mid-Range | Samsung Galaxy A34 / A54 / Redmi Note 12 | Android 14 / 15 | 1080 × 2340 (FHD+) | 6GB - 8GB | Physical Device + CI Emulator |
| **Android** | Tablet | Samsung Galaxy Tab A9+ / Lenovo Tab | Android 13/14 | 1200 × 1920 (WUXGA) | 4GB - 8GB | Physical Tablet (Quotation PDF & presentation view) |
| **iOS** | Compact | iPhone SE (3rd Gen) | iOS 16 / 17 | 750 × 1334 (4.7") | 4GB (A15 Bionic) | Simulator + Physical (Layout overflow verification) |
| **iOS** | Mainstream | iPhone 13 / 14 / 15 | iOS 17 / 18 | 1170 × 2532 (6.1") | 4GB - 6GB | Physical + iOS Simulator in CI |
| **iOS** | Large | iPhone 15 Pro Max / iPad Air | iOS 17 / 18 | 1290 × 2796 (6.7") | 6GB - 8GB | Simulator |

---

## Environmental & Hardware Constraints

1. **Network Throttling Profiles:**
   - **4G LTE:** 15 Mbps down / 5 Mbps up, 50ms latency (Urban Phnom Penh).
   - **3G / HSPA+:** 1.5 Mbps down / 500 Kbps up, 250ms latency (Provincial transit).
   - **Intermittent EDGE:** 150 Kbps down / 50 Kbps up, 800ms latency with 10% packet drop.
   - **Offline / Dead Zone:** Zero network throughput (Rural warehouse/remote sites).

2. **Hardware Sensor Validation:**
   - **GNSS / GPS:** Tested with High Accuracy Mode, GPS Only Mode, and Mock Location detection.
   - **Camera:** Camera permission, autofocus on barcode/QR code labels, compressed image capture.
   - **Biometrics:** Fingerprint / Face ID authentication integration where supported.

3. **Accessibility & Localization Matrix:**
   - Khmer Battambang / Hanuman / System font rendering at 100%, 120%, and 150% font scale.
   - Android Dark Mode & High Contrast display settings.
