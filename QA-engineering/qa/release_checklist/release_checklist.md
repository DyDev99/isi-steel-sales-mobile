# Release Checklist

**Version:**  **Build:**  **Date:**  **QA owner:**

## Automated
- [ ] `./scripts/qa_agent.sh regression` exit code 0
- [ ] Coverage ≥ agreed threshold (`QA_MIN_COVERAGE`)
- [ ] `./scripts/qa_agent.sh integration` passed on Android emulator
- [ ] `./scripts/qa_agent.sh integration` passed on iOS simulator
- [ ] No tests newly skipped or tagged `flaky` without an approved ticket

## Manual
- [ ] New features tested against their test cases
- [ ] Exploratory session done for each new or changed feature
- [ ] Device matrix covered (at least small Android + small iOS)
- [ ] Offline → online behaviour checked
- [ ] Permissions (location, camera, notifications) checked
- [ ] Khmer / English text displays correctly
- [ ] Dark mode and large font checked

## Release
- [ ] All P1/Critical bugs closed or accepted in writing
- [ ] Known issues listed in release notes
- [ ] Version number and build number bumped
- [ ] API points at the production base URL in the release build
- [ ] Crash reporting enabled

**Go / No-go:** ______  **Signed:** ______
