# Authentication & Session: Test Cases

**Feature:** Authentication & Security  
**Package:** `isi_steel_sales_mobile/features/authentication`  
**Priority:** P1 (Blocker)  
**Preconditions:** App installed, network connected (or simulated offline where specified).

| ID | Title | Steps | Test Data / Payload | Expected Result | Type | Automated Level |
|---|---|---|---|---|---|---|
| TC-AUTH-001 | Phone & Password Login Success | 1. Open app to Login screen<br>2. Enter registered phone number<br>3. Enter valid password<br>4. Tap "Sign In" | Phone: `+85512345678` (or `012345678`)<br>Password: `ValidPass123!` | Loading indicator shown, token stored securely in `FlutterSecureStorage`, navigated to `/main` (Home tab). | Functional | Unit + Widget + E2E |
| TC-AUTH-002 | Empty Credentials Validation | 1. Leave phone and password blank<br>2. Tap "Sign In" | Empty fields | Red error text below both fields: "Phone number is required" and "Password is required". No API request sent. | Negative | Unit + Widget |
| TC-AUTH-003 | Invalid Phone Format | 1. Enter non-numeric / malformed phone<br>2. Enter valid password<br>3. Tap "Sign In" | Phone: `abcd`, `123`, `012` | Validation error: "Invalid Cambodian phone number format". Sign In button disabled or error triggered. | Negative | Unit + Widget |
| TC-AUTH-004 | Incorrect Password | 1. Enter registered phone<br>2. Enter wrong password<br>3. Tap "Sign In" | Phone: `012345678`<br>Password: `WrongPass999` | Error toast/banner: "Invalid credentials. Please verify your phone and password." Password field cleared. | Negative | Unit + Widget |
| TC-AUTH-005 | Password Visibility Toggle | 1. Enter password<br>2. Tap eye icon | Password: `SecretPassword123` | Password text changes from obfuscated dots (`••••••`) to plain text. Tap again returns to dots. | UI / UX | Widget |
| TC-AUTH-006 | Network Timeout on Login | 1. Delay network response > 15s<br>2. Tap "Sign In" | Valid credentials, simulated slow proxy | "Connection timed out. Please check your internet connection." Retry button available; form retains inputs. | Negative | Unit + Widget |
| TC-AUTH-007 | Server 500 Error Handling | 1. Trigger backend 500 status on `/auth/login` | Valid credentials | Graceful error: "Server is temporarily unavailable (500). Please try again later." No crash. | Negative | Unit |
| TC-AUTH-008 | Forgot Password - OTP Request | 1. Tap "Forgot Password"<br>2. Enter registered phone<br>3. Tap "Send OTP" | Phone: `012345678` | Navigates to `/verify-otp`. 60-second cooldown countdown timer begins for "Resend OTP". | Functional | Unit + Widget |
| TC-AUTH-009 | Forgot Password - OTP Verification | 1. Enter 6-digit OTP code received | OTP: `123456` | Input auto-advances to next digit; on 6th digit, validates and opens `/create-new-password`. | Functional | Unit + Widget |
| TC-AUTH-010 | Forgot Password - Invalid OTP | 1. Enter invalid OTP code | OTP: `000000` | Error: "Invalid or expired OTP code. 2 attempts remaining." | Negative | Unit |
| TC-AUTH-011 | Password Reset - Mismatch Confirmation | 1. Enter new password<br>2. Enter different confirm password | New: `NewPass123!`<br>Confirm: `Different456!` | Validation error: "Passwords do not match." Submit button disabled. | Negative | Unit + Widget |
| TC-AUTH-012 | Password Reset - Weak Password Rule | 1. Enter weak password | `12345` or `password` | Rejection: "Must contain at least 8 characters, 1 uppercase, and 1 number." | Negative | Unit |
| TC-AUTH-013 | Silent Token Refresh | 1. Active session with expired access token<br>2. Trigger any protected API (e.g., fetch catalog) | Access Token expired, Refresh Token valid | Interceptor automatically exchanges refresh token for new access token. User experiences zero disruption. | Security | Unit |
| TC-AUTH-014 | Refresh Token Expired / Revoked | 1. Invalidate refresh token on server<br>2. Make protected API call | Expired refresh token | Session terminates cleanly. Secure storage cleared. User redirected to `/login` with "Session expired" banner. | Security | Unit |
| TC-AUTH-015 | Explicit Logout | 1. Go to Profile tab<br>2. Tap "Log Out"<br>3. Confirm dialog | Tap Confirm | JWT tokens purged from `FlutterSecureStorage`. Local cache preserved/cleared as per policy. Navigates to `/login`. | Functional | Unit + Widget + E2E |
| TC-AUTH-016 | App Kill & Cold Restart with Saved Session | 1. Login successfully<br>2. Force quit app<br>3. Relaunch app | Saved auth state | Splash screen runs `AuthCheckRequested()`, verifies token, and routes directly to `/main` without login prompt. | Session | Unit + E2E |
| TC-AUTH-017 | Khmer Language Localization | 1. Switch language to Khmer (`km`) on Splash/Login<br>2. Verify all labels | Locale: `km` | Labels, hint text, validation errors, and buttons display in fluent Khmer without clipping or font overflow. | i18n | Widget |
