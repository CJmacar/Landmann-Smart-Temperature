# Landmann Smart Temperature (iOS)

SwiftUI app that connects to a Landmann smart barbecue thermometer over Bluetooth Low Energy and displays live temperature readings.

## Requirements

- macOS with Xcode 15.2 or later
- Apple Developer Program membership (for App Store or TestFlight distribution)
- A physical iPhone running iOS 17.2 or later (Bluetooth does not work in Simulator)

## Open the project

```bash
open "Landmann Smart Temperature.xcodeproj"
```

In Xcode, select the **Landmann Smart Temperature** scheme and your iPhone as the run destination.

## Signing

1. Open the project in Xcode.
2. Select the **Landmann Smart Temperature** target.
3. Open **Signing & Capabilities**.
4. Choose your **Team** (the project currently references team `7FM6FWB8JC`).
5. Confirm the bundle identifier: `Island-Creatives.Landmann-Smart-Temperature`.

Automatic signing is enabled for Debug and Release builds.

## Build and run on device

1. Connect your iPhone.
2. Trust the developer certificate on the device if prompted.
3. Press **Run** in Xcode.

The app requests Bluetooth permission on first launch so it can scan for and connect to the thermometer.

## Archive for App Store / TestFlight

### Option A: Xcode UI

1. Select **Any iOS Device (arm64)** as the destination.
2. Choose **Product → Archive**.
3. In the Organizer, click **Distribute App** and follow the App Store Connect upload flow.

### Option B: Command line

```bash
chmod +x scripts/archive-ios.sh
./scripts/archive-ios.sh
```

This creates an `.xcarchive` under `build/` and exports an `.ipa` using `ExportOptions.plist`.

Upload the `.ipa` with [Transporter](https://apps.apple.com/app/transporter/id1450874784) or Xcode Organizer.

## App Store checklist

Before submitting, confirm:

- [ ] App icon is present in `Assets.xcassets/AppIcon.appiconset` (1024×1024 required)
- [ ] Bluetooth usage strings are set in the target Info settings
- [ ] `ITSAppUsesNonExemptEncryption` is set to `NO` (standard HTTPS/BLE only)
- [ ] Screenshots and metadata are prepared in App Store Connect
- [ ] Privacy policy URL is added if required by App Review

## Project layout

| Path | Purpose |
|------|---------|
| `Landmann Smart Temperature/` | Main app source and assets |
| `Landmann Smart Temperature.xcodeproj/xcshareddata/xcschemes/` | Shared scheme for CI/archive builds |
| `ExportOptions.plist` | App Store export settings |
| `scripts/archive-ios.sh` | Command-line archive helper |

## Notes

- The app targets iPhone and iPad (`TARGETED_DEVICE_FAMILY = 1,2`) with minimum iOS 17.2.
- macOS builds use separate entitlements in `Landmann_Smart_Temperature_macOS.entitlements`.
- iOS builds use an empty entitlements file; Bluetooth access is declared via Info.plist privacy keys.
