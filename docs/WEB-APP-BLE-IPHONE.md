# Web app ↔ Landmann thermometer over BLE (iPhone)

Investigation of how a web app could talk to the Landmann smart barbecue thermometer using the iPhone’s Bluetooth Low Energy stack, with a recommendation for iPhone production use.

## Current native baseline

This repo already implements a working iPhone BLE central in [`Landmann Smart Temperature/BluetoothManager.swift`](../Landmann%20Smart%20Temperature/BluetoothManager.swift):

| Item | Value |
|------|--------|
| Role | BLE central (phone) → peripheral (thermometer) |
| Service UUID | `1000` (Bluetooth Base UUID short form) |
| Characteristic | `1002` (notifications) |
| Payload | ≥ 7 bytes |
| Probe 1 °C | `byte[3] * 10 + (byte[4] >> 4)` |
| Probe 2 °C | `byte[5] * 10 + (byte[6] >> 4)` |
| Disconnected sentinel | `1440` → treat as `0` |

Full 128-bit forms (for Web Bluetooth filters):

- Service: `00001000-0000-1000-8000-00805f9b34fb`
- Characteristic: `00001002-0000-1000-8000-00805f9b34fb`

There is no Web Bluetooth code in the repo today. Safari on iOS does not expose `navigator.bluetooth`.

## Constraint: Safari cannot do BLE

| Runtime | Web Bluetooth (`navigator.bluetooth`) |
|---------|----------------------------------------|
| Safari iOS / iPadOS | Not supported (WebKit: not considering) |
| Chrome / Edge / Firefox on iOS | Not supported (forced to WebKit) |
| Chrome / Edge on Android, macOS, Windows | Supported |
| Third-party iOS browsers with their own BLE stack | Partial / non-standard (see below) |

So a **standalone PWA opened in Safari cannot** use the iPhone BLE interface to reach this sensor. Any iPhone solution needs either a native BLE layer or a third-party browser/extension that bridges to CoreBluetooth.

## Options evaluated

### A. Pure Web Bluetooth PWA (Safari)

**How it would work:** Page calls `navigator.bluetooth.requestDevice`, connects GATT, subscribes to `1002`, parses bytes like the Swift code.

**iPhone reality:** Impossible in Safari without add-ons. Not a viable App Store or consumer path.

**Verdict:** Reject for iPhone.

### B. Third-party Web Bluetooth on iPhone (Bluefy, WebBLE, beacio)

**How it would work:** Same Web Bluetooth JS as desktop Chrome. User opens the page in [Bluefy](https://apps.apple.com/us/app/bluefy-web-ble-browser/id1492822055) / WebBLE, or installs a Safari extension such as [beacio](https://ioswebble.com/) that polyfills `navigator.bluetooth` via CoreBluetooth.

**Pros**

- Closest to “real web app” code sharing with Android/desktop Chrome
- Useful for demos and internal testing

**Cons**

- Extra install and setup for every user
- Not your App Store product; UX and reliability depend on a third party
- Extensions can break across iOS updates
- Poor fit for a thermometer product meant for casual cooks

**Verdict:** Fine for prototypes; not recommended for production iPhone use.

### C. Capacitor / Cordova hybrid (web UI + native BLE plugin)

**How it would work:** Ship an iOS app whose UI is HTML/JS. A plugin (e.g. Capacitor Community Bluetooth LE) wraps CoreBluetooth and exposes JS APIs. Port the existing GATT/parse logic into that JS layer (or keep a thin native plugin).

**Pros**

- Web stack for UI; works offline as a real app
- Uses the same CoreBluetooth path Safari lacks
- Can share UI code with a desktop Web Bluetooth build (with an adapter)

**Cons**

- Effectively a new native shell; signing, store review, and BLE privacy strings still required
- Duplicates or replaces much of the existing SwiftUI app
- Plugin quality and background BLE behavior vary

**Verdict:** Reasonable if the goal is “rewrite UI in web tech” and abandon or freeze the SwiftUI UI.

### D. WKWebView + JS bridge inside this Swift app (recommended)

**How it would work:** Keep [`BluetoothManager`](../Landmann%20Smart%20Temperature/BluetoothManager.swift) as the BLE owner. Embed the web UI in `WKWebView`. Expose a small bridge, for example:

1. Native → JS: push temperature updates (`window.onTemperatureUpdate({ p1, p2 })` or `webkit.messageHandlers` + injected script).
2. JS → Native: `scan`, `connect(deviceId)`, `disconnect` via `WKScriptMessageHandler`.

```mermaid
flowchart LR
  WebUI[Web_UI_in_WKWebView] -->|scan_connect| Bridge[WKScriptMessageHandler]
  Bridge --> BLE[BluetoothManager_CoreBluetooth]
  BLE -->|notify_1002| Bridge
  Bridge -->|evaluateJavaScript| WebUI
  BLE --> Sensor[Landmann_thermometer]
```

**Pros**

- Reuses the proven GATT UUIDs and parse logic already shipping
- No dependency on Safari Web Bluetooth or third-party browsers
- App Store distribution and Bluetooth permission flow stay as they are today
- Web team can iterate on UI without reimplementing BLE
- Clear security boundary: only the bridge methods you expose are callable

**Cons**

- Not a URL you open in Safari; it is still a native app container
- Must maintain the bridge contract and load web assets (bundled or remote with care)

**Verdict:** Best production path for iPhone given this codebase.

### E. Desktop / Android Web Bluetooth only

**How it would work:** Implement Web Bluetooth against service `1000` / char `1002` for Chrome on laptop or Android phone. iPhone users keep the native app.

**Pros**

- Fast to prototype on platforms that support Web Bluetooth
- Validates protocol independently of iOS

**Cons**

- Does not solve iPhone

**Verdict:** Useful companion target; not an iPhone solution.

## Recommendation (iPhone)

**Use option D: keep CoreBluetooth in this Swift app and drive a web UI through a WKWebView JavaScript bridge.**

Rationale:

1. iPhone Safari cannot access BLE; any pure-web claim would rely on Bluefy/beacio and fail for normal users.
2. This project already has a working central, correct UUIDs, and temperature decoding — the risky part of the problem is solved.
3. A WKWebView bridge delivers a web-authored UI without giving up App Store packaging, Bluetooth permissions, or reliability.
4. Capacitor (option C) is a secondary choice only if you intentionally want to replace the SwiftUI shell with a cross-platform web shell; it is more migration cost for the same BLE outcome.

Do **not** plan production iPhone UX around Safari PWA + Web Bluetooth.

## Suggested next implementation (when ready)

1. Extract temperature parsing from `BluetoothManager` into a small shared pure function (easier to mirror in JS tests).
2. Add a `WKWebView` host screen and `WKScriptMessageHandler` for `scan` / `connect` / `disconnect`.
3. Push `{ p1, p2 }` updates into the page on each notify.
4. Optionally add a separate Chrome Web Bluetooth page for desktop/Android that shares the same parse/UI modules — not required for iPhone.

## Reference: Web Bluetooth sketch (non-iPhone)

Illustrative only; runs where `navigator.bluetooth` exists (not Safari iPhone):

```js
const SERVICE = '00001000-0000-1000-8000-00805f9b34fb';
const CHAR = '00001002-0000-1000-8000-00805f9b34fb';

function parseTemps(dataView) {
  if (dataView.byteLength < 7) return null;
  const p1 = dataView.getUint8(3) * 10 + (dataView.getUint8(4) >> 4);
  const p2 = dataView.getUint8(5) * 10 + (dataView.getUint8(6) >> 4);
  return {
    p1: p1 === 1440 ? 0 : p1,
    p2: p2 === 1440 ? 0 : p2,
  };
}

async function connectLandmann() {
  const device = await navigator.bluetooth.requestDevice({
    // Prefer filters once the advertised name/services are confirmed on hardware.
    acceptAllDevices: true,
    optionalServices: [SERVICE],
  });
  const server = await device.gatt.connect();
  const service = await server.getPrimaryService(SERVICE);
  const characteristic = await service.getCharacteristic(CHAR);
  await characteristic.startNotifications();
  characteristic.addEventListener('characteristicvaluechanged', (event) => {
    const temps = parseTemps(event.target.value);
    if (temps) console.log(temps);
  });
}
```

On iPhone, the equivalent calls would go to the native bridge instead of `navigator.bluetooth`.
