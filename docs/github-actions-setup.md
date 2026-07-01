# GitHub Actions setup for iOS deployment

GitHub can build and deploy this app using **macOS runners** (Xcode is not available on Linux runners).

Two workflows are included:

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| `ios-build.yml` | Push/PR to `main` | Compile-check on iOS Simulator (no signing secrets) |
| `ios-deploy.yml` | Manual run or `v*` tag | Archive, export `.ipa`, upload to TestFlight |

## 1. Create App Store Connect API key

1. Open [App Store Connect → Users and Access → Integrations → App Store Connect API](https://appstoreconnect.apple.com/access/integrations/api).
2. Create a key with **App Manager** or **Admin** access.
3. Download the `.p8` file once and store it safely.

You will need:

- **Issuer ID**
- **Key ID**
- **Private key** (contents of the `.p8` file)

## 2. Create signing assets in Apple Developer

In [Apple Developer → Certificates, Identifiers & Profiles](https://developer.apple.com/account/resources):

1. Create an **Apple Distribution** certificate.
2. Export it from Keychain Access as a `.p12` file with a password.
3. Create an **App Store** provisioning profile for bundle ID:
   `Island-Creatives.Landmann-Smart-Temperature`
4. Download the `.mobileprovision` file.

## 3. Add GitHub repository secrets

Go to **Settings → Secrets and variables → Actions** and add:

| Secret | Value |
|--------|-------|
| `APPLE_TEAM_ID` | Your 10-character team ID (e.g. `7FM6FWB8JC`) |
| `BUILD_CERTIFICATE_BASE64` | Base64 of your `.p12` file |
| `P12_PASSWORD` | Password used when exporting the `.p12` |
| `KEYCHAIN_PASSWORD` | Any strong random string for the CI keychain |
| `PROVISIONING_PROFILE_BASE64` | Base64 of your `.mobileprovision` file |
| `PROVISIONING_PROFILE_NAME` | Exact profile name from Apple Developer |
| `APPSTORE_ISSUER_ID` | App Store Connect API issuer ID |
| `APPSTORE_API_KEY_ID` | App Store Connect API key ID |
| `APPSTORE_API_PRIVATE_KEY` | Full contents of the `.p8` private key |

### Encode files as base64 (run on your Mac)

```bash
base64 -i Certificates.p12 | pbcopy
base64 -i Landmann.mobileprovision | pbcopy
```

## 4. Optional: protect production deploys

Create a GitHub **environment** named `production` under **Settings → Environments** and require approval before deploy jobs run.

The deploy workflow already references `environment: production`.

## 5. Run a deployment

### Manual TestFlight upload

1. Open **Actions → iOS Deploy**.
2. Click **Run workflow**.
3. Leave **Upload build to TestFlight** enabled.

### Tag-based release

```bash
git tag v1.0.0
git push origin v1.0.0
```

This archives the app, uploads the `.ipa` as a workflow artifact, and sends it to TestFlight.

## What each workflow does

### Build (`ios-build.yml`)

- Runs on `macos-15`
- Builds for iOS Simulator with `CODE_SIGNING_ALLOWED=NO`
- Validates that the project compiles on every PR

### Deploy (`ios-deploy.yml`)

- Installs distribution certificate and provisioning profile from secrets
- Archives with `xcodebuild`
- Exports an App Store `.ipa`
- Uploads to TestFlight via App Store Connect API
- Saves the `.ipa` as a downloadable artifact

## Troubleshooting

| Error | Fix |
|-------|-----|
| `No signing certificate "iOS Distribution" found` | Re-export the distribution `.p12` and update `BUILD_CERTIFICATE_BASE64` |
| `Provisioning profile doesn't match` | Regenerate the App Store profile for the correct bundle ID |
| TestFlight upload auth failure | Verify API key role and `.p8` secret contents |
| Simulator destination not found | GitHub runner image/Xcode version changed; update the simulator name in `ios-build.yml` |

## Cost note

macOS GitHub Actions minutes consume more quota than Linux runners. The build workflow is lightweight; deploy runs only when you trigger them.
