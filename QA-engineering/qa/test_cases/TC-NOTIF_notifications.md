# Push Notifications & Inbox: Test Cases

**Feature:** Push Notifications, Category Channels & Notification Inbox  
**Package:** `isi_steel_sales_mobile/features/notification`  
**Priority:** P2 (Operational Alerts)  
**Preconditions:** Handset registered with FCM token, user logged in.

| ID | Title | Steps | Test Data / Payload | Expected Result | Type | Automated Level |
|---|---|---|---|---|---|---|
| TC-NOTIF-001 | Foreground Notification Banner | 1. App in foreground<br>2. Send test FCM push message for order update | Payload: `channel_id: order_updates`, title: "Order #SO-421 Dispatched" | `flutter_local_notifications` displays top alert banner. Sound and vibration fire per channel priority. | Functional | Unit + Widget |
| TC-NOTIF-002 | Tap Notification - Deep Link Routing | 1. App in background/closed<br>2. Tap received notification for Quotation approval | Payload: `route: /order`, `quote_id: QT-109` | App opens directly to Quotation detail screen (bypassing generic home feed). | Integration | Widget + E2E |
| TC-NOTIF-003 | Notification Inbox Read / Unread Status | 1. Open Notification Center from bell icon on Home<br>2. Observe unread badge<br>3. Tap notification card | 3 unread notifications | Unread count badge decreases from 3 to 2. Tapped card background changes from highlight to read state. | UI / Functional | Widget |
| TC-NOTIF-004 | Quiet Hours (Phnom Penh Timezone) | 1. System time set to 22:30 (Quiet hours: 22:00 - 06:00 Asia/Phnom_Penh)<br>2. Send marketing / digest notification | Quiet hours active | Sound and heads-up banner suppressed. Notification quietly deposited into inbox. | Business Rule | Unit |
| TC-NOTIF-005 | FCM Token Refresh on Device | 1. FCM token invalidated or refreshed by Google Play Services | New FCM token | `DeviceIdentity` worker detects new token and silently posts update to `/devices/register` backend endpoint. | Architecture | Unit |
