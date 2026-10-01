# Codemagic iPhone test build

This repository contains a manual Codemagic workflow for installing an
unsigned iPhone test build through Sideloadly. It is intentionally separate
from production signing and does not deploy or merge anything.

## Workflow

- Branch: `feat/content-api-guest-vi`
- Workflow: `shortigo-ios-test`
- Configuration: `/codemagic.yaml`
- Trigger: manual only; choose the branch above in Codemagic when starting a
  build.
- Artifact: `build/ios/ipa/*.ipa`

The workflow runs Flutter dependency installation, analysis, tests, and an
unsigned IPA build. It has no iOS signing configuration and does not use
TestFlight or an Apple distribution certificate.

The workflow explicitly disables Flutter Swift Package Manager for this build.
The current `google_mobile_ads` and `better_player_plus` versions use
CocoaPods, so this keeps the build dependency mode consistent without changing
the app's dependency versions or native project files.

The workflow also refreshes the RevenueCat transitive pod
`PurchasesHybridCommon` before the IPA build. This is required because the
checked-in CocoaPods lock can lag behind the resolved `purchases_flutter`
plugin version; the update is performed only on the disposable Codemagic
runner.

## Test build flags

The build command passes:

```text
--dart-define=VIP_TEST_MODE=true
--dart-define=CONTENT_API_BASE_URL=
```

Therefore a fresh installation starts with no Content API source configured.
The app should show the unconfigured state until a user opens Settings, enters
an HTTPS Content API URL, runs Test Connection, and saves it. Restore Default
returns to the blank build-time default, so it removes the active source again.
No production or preview API URL is embedded in this repository.

## VIP test mode

When `VIP_TEST_MODE=true`, ShortiGo selects the local `TestIapGateway`:

- monthly and yearly local test offerings are shown;
- purchase succeeds locally without Apple StoreKit or RevenueCat;
- the entitlement is persisted in the existing local Drift database;
- guest, account A, and account B use separate local entitlement keys;
- Restore and Reset VIP Test operate on that local state;
- provider source locks and unavailable episodes still block playback before
  any ShortiGo VIP entitlement is considered.

Production builds omit `VIP_TEST_MODE` (or set it to `false`) and continue to
use the existing RevenueCat gateway. The test gateway, test packages, and
reset control are not used in production mode. Firebase Auth and Firestore
remain unchanged and are not used to store the local test entitlement.

## Sideloadly

Download the IPA artifact from the Codemagic build and install it with
Sideloadly using the normal Apple ID signing flow. This is a device-test IPA,
not a production-signed release. The first app launch should be able to use
Guest Mode without Firebase; configure the Content API later from Settings if
content is needed.
