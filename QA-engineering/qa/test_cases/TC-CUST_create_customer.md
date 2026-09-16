# Test Cases: Create Customer

**Feature:** Customer → Add Customer  **Priority:** P1  **Preconditions:** logged in as sales user, on Customer list.

| ID | Title | Steps | Test data | Expected result | Type | Automated |
|---|---|---|---|---|---|---|
| TC-CUST-001 | Required fields empty | Tap Add → tap Submit | all empty | Errors under Name, Phone, Credit limit. No API call. | Negative | Unit + Widget |
| TC-CUST-002 | Create valid customer | Fill all fields → Submit | Name `QA Test Co`, Phone `+85512345678`, Type Wholesale, Limit `5000` | Loading shown, button disabled, success message, customer appears in list | Functional | Unit + Widget + E2E |
| TC-CUST-010 | Valid credit limit | Enter limit → Submit | `5000` | Accepted | Functional | Unit |
| TC-CUST-011 | Negative credit limit | Enter limit → Submit | `-500` | "Credit limit cannot be negative" | Negative | Unit + Widget |
| TC-CUST-012 | Non-numeric credit limit | Enter limit → Submit | `abc` | "Credit limit must be a number" (or keyboard blocks letters) | Negative | Unit |
| TC-CUST-013 | Empty credit limit | Leave empty → Submit | empty | "Credit limit is required" | Negative | Unit |
| TC-CUST-014 | Zero credit limit | Enter `0` → Submit | `0` | **OPEN QUESTION: business rule needed** | Boundary | Unit (assumes allowed) |
| TC-CUST-015 | Very large credit limit | Enter limit → Submit | `1000000000.01` | Rejected as above maximum (**max value to confirm**) | Boundary | Unit |
| TC-CUST-020 | Valid phone formats | Enter phone | `012345678`, `+85512345678`, `012 345 678` | Accepted | Functional | Unit |
| TC-CUST-021 | Invalid phone | Enter phone | `123`, `abcdefghij` | "Phone number is invalid" | Negative | Unit |
| TC-CUST-030 | Double-tap Submit | Fill valid → tap Submit rapidly 3× | valid | Exactly one customer created | Negative | Unit |
| TC-CUST-040 | No internet | Airplane mode → Submit | valid | Friendly network error, data kept in form | Negative | Unit + Widget |
| TC-CUST-041 | Server error 500 | Point QA API to error stub → Submit | valid | "Server error" message, can retry | Negative | Unit |
| TC-CUST-042 | Token expired | Expire token → Submit | valid | Session-expired message → redirect to login | Negative | Unit (message only) |
| TC-CUST-050 | Duplicate customer | Create same phone twice | existing phone | **Define rule:** block or warn | Negative | Manual |
| TC-CUST-060 | Background mid-submit | Submit → press Home → return | valid | No crash; one result shown | Exploratory | Manual |
| TC-CUST-061 | Rotate / resize | Fill form → rotate device | partial data | Data not lost, no overflow | UI | Widget (sizes) + Manual |
| TC-CUST-062 | Khmer input | Enter Khmer name | `ក្រុមហ៊ុន ដែក` | Saved and displayed correctly | Functional | Unit + Manual |
