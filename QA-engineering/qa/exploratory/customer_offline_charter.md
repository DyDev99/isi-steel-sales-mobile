# Charter: Customer creation under unstable connectivity

**Charter:** Explore Create Customer with network toggling and app backgrounding, to discover data loss, duplicates and sync bugs.
**Time box:** 60 min

## Ideas to try
1. Fill the form → turn internet off → Submit → turn internet on → Submit again. Is the customer created once?
2. Submit → immediately enable airplane mode. What does the user see? What is in the backend?
3. Tap Submit 3–5 times quickly on slow 3G (use the emulator's network throttling).
4. Fill half the form → background the app for 5 minutes → return. Is the data still there?
5. Submit → kill the app → reopen. Does the customer exist? Is there a pending sync?
6. Let the token expire while the form is open, then submit.
7. Switch between Wi-Fi and mobile data during submit.
