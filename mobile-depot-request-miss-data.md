# Missing Data / Static Fields in Mobile Depot

This document outlines the hardcoded (static) values currently used in the `StopInformationScreen` (`lib/features/my_visits/presentation/screens/stop_information/stop_information_screen.dart`). 

The backend API needs to be upgraded to supply these fields dynamically so the mobile app can display real data instead of placeholders.

## 1. Hero Card (Header Section)
* **Customer / Loyalty Tier**: Currently hardcoded as `"Diamond"`. 
  * **Requirement**: Provide the customer's loyalty tier, ranking, or classification.
* **Default Phone Number**: Falls back to `"026 407 480"` if the customer phone is empty.

## 2. Overview Tab
* **Default SAP ID**: Falls back to `"BP-884920"` if `c.code` is empty.
* **Outlet Type**: Currently hardcoded as `"WHS / Retail"`.
  * **Requirement**: Provide the business type/outlet classification.
* **Action Tag**: Currently hardcoded as `"Attack"`.
  * **Requirement**: Provide the visit strategy or status tag (e.g., Attack, Defend, Maintain).
* **Contact Person**: Falls back to `"Yim Vithou"` if `c.contact` is empty.
* **Telegram Username**: Currently hardcoded as `"@phnom_penh_steel_outlet"`.
  * **Requirement**: Provide the shop's Telegram handle or contact link if available.
* **Default Address**: Falls back to `"St. 218, Mean Chey"` if `c.address` is empty.

## 3. Sales Tab (Customer Financials & History)
* **Payment Status**: Currently hardcoded as `"Good Standing"`.
  * **Requirement**: Provide the current account standing (e.g., Good Standing, Overdue, Blocked).
* **Credit Limit**: Currently hardcoded as `"$50,000"`.
  * **Requirement**: Provide the approved credit limit for the customer.
* **Payment Term**: Currently hardcoded as `"30 Days Net"`.
  * **Requirement**: Provide the negotiated payment terms.
* **Average Revenue per Order**: Currently hardcoded as `"$12,500"`.
  * **Requirement**: Provide the calculated average order value (AOV) for this customer.
* **Latest Order Date**: Currently hardcoded as `"12 Aug 2026"`.
  * **Requirement**: Provide the timestamp of the last successful order.

## 4. Promos Tab
* **Total Active Promotions**: Currently hardcoded as `"25 Available"`.
  * **Requirement**: Provide the total count of promotions applicable to this customer.
* **On-Invoice Promotions**: Currently hardcoded as `20`.
  * **Requirement**: Count of active on-invoice discounts/promos.
* **Off-Invoice Promotions**: Currently hardcoded as `0`.
  * **Requirement**: Count of active off-invoice or rebate promos.
* **Contract Promotions**: Currently hardcoded as `5`.
  * **Requirement**: Count of active contract-based promotional agreements.
