# Development log

## 2026-09-11 — HarmonyOS native project created

- Created an independent ArkTS/Stage-model application under `Tictoc_HarmonyOS`.
- Based project metadata on Huawei's official Screen Time Guard Kit sample at commit shown by GitCode as `8d2960039bc7654b415304163c4be44c31ba1e8e`.
- Set `compatibleSdkVersion` and `targetSdkVersion` to HarmonyOS 6.0.2(22), matching the official sample.
- Set the app label to Tictoc and retained Apache-2.0 attribution. The current bundle name is `com.derek.tictoc.hm` (see registration correction below).
- Declared restricted ACL permission `ohos.permission.MANAGE_SCREEN_TIME_GUARD` using the same manifest shape as the official sample. Runtime user authorization is requested through Screen Time Guard Kit.
- Implemented user authorization state, system app picker, immediate blocklist restrictions, daily start/end restrictions, shared-duration strategy and release of Tictoc-owned strategies.
- Persisted opaque app tokens and rule inputs locally using Preferences.
- Added a six-digit, salted SHA-256 local management PIN, full-length comparison and a five-attempt/30-second in-memory lockout.
- Persisted the token set used by immediate restrictions separately so changing the current picker selection does not leave an old direct restriction without a release path.
- The UI locks when the page is hidden except during a system authorization or picker flow.
- Removed the original demo screen and helpers from the new project.

### Verification status

- Source structure, module page registration, bundle metadata and restricted permission declarations were checked locally.
- The machine did not have DevEco Studio, HarmonyOS SDK, ohpm, hvigor or hdc installed/discoverable, so no HAP was compiled and no HarmonyOS runtime test is claimed.
- Signing certificate, ACL approval and ACL-enabled Profile are external prerequisites tied to the user's AppGallery Connect application and were not created.
- The project must be synchronized and compiled in DevEco Studio before delivery to a physical device. Address any SDK diagnostics against the exact installed API 22 SDK rather than weakening the permission or strategy logic.

### Required device tests

- User grants, denies and revokes authorization.
- App selection cancellation and token persistence.
- Immediate restriction and release.
- Start/end strategy across midnight and all seven repeat days.
- Shared-duration exhaustion and next-day reset behavior.
- Multiple Tictoc strategies, app restart, device restart and offline execution.
- PIN setup, incorrect attempts, background relock and PIN change.
- Main space versus unsupported spaces, uninstall behavior and system-allowed applications.

## Bundle-name registration correction

- The user's AGC registration screen rejected the original platform-name suffix as a reserved word.
- Changed AppScope/app.json5 bundleName to `com.derek.tictoc.hm` per the user's final naming choice and synchronized README instructions.
- This differs from the Android applicationId `com.derek.tictoc`. AGC availability has not been verified; use this exact value when registering and configuring signing/Profile.
- Verified the JSON configuration and scanned the active project for the old identifier. No HAP build was performed for this metadata-only correction.
- Updated source delivery: `outputs/harmony-package-name-hm/Tictoc_HarmonyOS-source.zip`. Earlier archives remain historical snapshots.
