# CLAUDE.md — Salah Time

> macOS menubar app for Islamic prayer time reminders. Native Swift/SwiftUI, no database, single `adhan-swift` dependency.

## Quick Reference

| Item | Value |
|---|---|
| Language | Swift 5.9+ |
| UI Framework | SwiftUI (macOS 14+) |
| Build System | Xcode 15+ via [xcodegen](https://github.com/yonaskolb/XcodeGen) (`project.yml`) |
| Dependency | [`adhan-swift`](https://github.com/batoulapps/adhan-swift) via Xcode SPM |
| Test Framework | Swift Testing (`@Test`, `@Suite`) |
| CI/CD | GitHub Actions (macOS 14 runner) |
| App Type | Menubar-only (`LSUIElement = YES`) — no Dock icon |

---

## How the App Runs

### Entry Point — `SalahTimeApp.swift`

`@main struct SalahTimeApp: App` creates a `MenuBarExtra` with `.window` style (popover, not menu).

Three `@State` services are created at the app level and injected via `.environment()`:
- `PrayerTimeManager` — prayer calculation + countdown engine
- `LocationManager` — CoreLocation wrapper
- `NotificationManager` — UNUserNotificationCenter + Adhan audio

`AppSettings.shared` (singleton, `@Observable`) is accessed directly — not environment-injected.

On init, `SMAppService.mainApp.register()` is called if Launch at Login is enabled.

### Menubar Label

Controlled by `AppSettings.menuBarDisplayMode` (persisted in UserDefaults):
- `.iconOnly` — just ☪ symbol
- `.iconAndPrayer` — `"Asr 01:23:45"` (name + countdown)
- `.iconAndTime` — `"16:30"` (next prayer time)

---

## Core Logic Flow

```
App Launch
  ├── LocationManager.requestLocation()     ← asks macOS for permission
  ├── NotificationManager.requestPermission() ← asks for notification permission
  └── PopoverView.setupApp()
        ├── Wait for valid coordinates (1s poll timer)
        ├── PrayerTimeManager.calculatePrayerTimes(lat, lng)
        │     ├── PRIMARY: adhan-swift local calculation
        │     │     └── Coordinates + CalculationParameters → PrayerTimes
        │     └── FALLBACK: AladhanAPIClient.fetchPrayerTimes() (async REST)
        ├── NotificationManager.scheduleNotifications(for: prayerTimes)
        └── Listen for:
              ├── .midnightRecalculation → recalculate at 00:00
              └── UserDefaults.didChangeNotification → recalculate on settings change
```

### Prayer Time Calculation (`PrayerTimeManager`)

1. Gets `CalculationParameters` from the user's chosen method (`AppSettings.calculationMethod`)
2. Creates `Adhan.PrayerTimes(coordinates:date:calculationParameters:)` for today
3. Maps to 6 `PrayerTime` structs: Fajr, Sunrise, Dhuhr, Asr, Maghrib, Isha
4. Marks each as `.isPassed` or `.isNext` based on current time
5. Starts a **1-second Timer** for live countdown:
   - Updates `countdownString` (`"HH:mm:ss"`) and `countdownSeconds`
   - Calculates `progress` (0→1) between previous and next prayer
   - When countdown hits 0 → posts `.prayerTimeArrived` notification + recalculates

**KEMENAG/JAKIM** special case: uses `CalculationMethod.other` with custom angles (Fajr 20°, Isha 18°).

### Aladhan API Fallback (`AladhanAPIClient`)

Only used when `adhan-swift` local calculation returns `nil` (rare edge case).

- Endpoint: `https://api.aladhan.com/v1/timings/{dd-MM-yyyy}?latitude=X&longitude=Y&method=N`
- Parses `"HH:mm (TZ)"` format — strips timezone label before parsing
- Same `.isNext` / `.isPassed` marking logic as local calculation

### Location (`LocationManager`)

- `CLLocationManager` with `kCLLocationAccuracyKilometer` + `distanceFilter: 1000m` (low power)
- Gets one fix → stops updating → reverse geocodes for city name
- `effectiveLatitude/Longitude` switches between auto and manual based on `AppSettings.useAutoLocation`

### Notifications (`NotificationManager`)

For each future prayer time (per-prayer toggleable):
1. Schedules a `UNCalendarNotificationTrigger` at exact prayer time
2. Optionally schedules a **pre-reminder** (5/10/15/30 min before)
3. Optionally schedules **Adhan audio playback** via `Timer` → `AVAudioPlayer`

Adhan audio resolution:
1. Custom file (security-scoped bookmark stored in UserDefaults)
2. Bundled `default_adhan.m4a` / `.mp3` from `Resources/`

Also listens to `.prayerTimeArrived` notifications from `PrayerTimeManager` for real-time Adhan triggering.

### Hijri Date (`HijriDateCalculator`)

Uses Apple's built-in `Calendar(identifier: .islamicUmmAlQura)` — no external dependency.

- English format: `"25 Ramadan 1447"`
- Arabic format: `"٢٥ رمضان ١٤٤٧ هـ"` (uses hardcoded Arabic month name lookup)
- Special day detection: Ramadan, both Eids, Ashura, Mawlid, Isra' Mi'raj

### Qibla Direction (`QiblaCalculator`)

Delegates to `Adhan.Qibla(coordinates:).direction` — returns bearing in degrees from North.

Converts to compass label (N, NE, E, etc.) with 45° sectors.

---

## Settings Persistence

All settings use **UserDefaults** with `didSet` auto-save. `AppSettings` is `@Observable` singleton.

| Key | Type | Default |
|---|---|---|
| `calculationMethod` | Int (enum raw) | `.muslimWorldLeague` (0) |
| `menuBarDisplayMode` | Int (enum raw) | `.iconOnly` (0) |
| `useAutoLocation` | Bool | `true` |
| `manualLatitude` / `manualLongitude` | Double | `0.0` |
| `manualCityName` | String | `""` |
| `preReminderMinutes` | Int | `15` |
| `prayerNotifications` | JSON Data | Per-prayer enabled/adhan flags |
| `customAdhanBookmark` | Data | Security-scoped bookmark |
| `launchAtLogin` | Bool | `true` |

---

## Architecture & Design Patterns

- **No database** — all state in UserDefaults + computed at runtime
- **`@Observable` (Observation framework)** — not Combine's `@Published`/`ObservableObject`
- **Environment injection** for services, singleton for settings
- **`NotificationCenter.default`** for internal events (prayer arrived, midnight recalc)
- **`UNUserNotificationCenter`** for system notifications
- **Security-scoped bookmarks** for sandboxed file access to custom Adhan audio

---

## Project Structure

```
prayer-reminder/
├── SalahTime/
│   ├── SalahTimeApp.swift              # @main entry, MenuBarExtra
│   ├── Models/
│   │   ├── Prayer.swift                # Prayer enum (6 prayers) + PrayerTime struct
│   │   └── AppSettings.swift           # @Observable singleton, UserDefaults-backed
│   ├── Services/
│   │   ├── PrayerTimeManager.swift     # Calculation engine + countdown timer
│   │   ├── AladhanAPIClient.swift      # REST API fallback
│   │   ├── LocationManager.swift       # CoreLocation + reverse geocoding
│   │   ├── NotificationManager.swift   # UNNotifications + AVAudioPlayer
│   │   ├── HijriDateCalculator.swift   # Umm Al-Qura calendar conversion
│   │   └── QiblaCalculator.swift       # Bearing to Makkah
│   ├── Views/
│   │   ├── PopoverView.swift           # Main container (orchestrates setup)
│   │   ├── HeaderView.swift            # Hijri/Gregorian dates + location
│   │   ├── NextPrayerView.swift        # Countdown + progress ring
│   │   ├── PrayerTimesListView.swift   # All 6 prayer rows
│   │   ├── QiblaCompassView.swift      # Compass with animated bearing
│   │   └── SettingsView.swift          # Inline settings panel
│   ├── Theme/
│   │   ├── DesignSystem.swift          # Colors, typography, layout constants, view modifiers
│   │   └── IslamicPatternView.swift    # Procedural geometric pattern + crescent
│   └── Resources/
│       └── README.md                   # Placeholder for bundled assets
├── SalahTimeTests/
│   ├── HijriDateCalculatorTests.swift  # Hijri format, Arabic suffix, month names
│   ├── QiblaCalculatorTests.swift      # Known city bearings, compass sectors
│   ├── AladhanAPIClientTests.swift     # Time parsing, JSON decoding, errors
│   ├── PrayerModelTests.swift          # Prayer enum props, PrayerTime formatting
│   └── AppSettingsTests.swift          # Defaults, notification helpers, enums
├── .github/workflows/
│   ├── ci.yml                          # Build + test on push/PR
│   └── release.yml                     # DMG + GitHub Release on v* tag
├── scripts/
│   └── build-dmg.sh                    # Manual release DMG builder
├── project.yml                         # xcodegen project spec
├── XCODE_SETUP.md                      # First-time Xcode project setup guide
├── CLAUDE.md                           # This file
├── README.md
└── LICENSE                             # MIT
```

---

## Design System — `Theme/DesignSystem.swift`

Color palette (dark emerald base):
- Backgrounds: `deepEmerald (#0A1F1A)`, `darkEmerald (#0F2B23)`, `emeraldGlow (#1B4D3E)`
- Accents: `tealAccent (#2DD4BF)`, `goldAccent (#F59E0B)`, `warmGold (#D4A853)`
- Text: `pureWhite`, `softWhite (#F3F4F6)`, `softGray (#9CA3AF)`, `dimGray (#6B7280)`

View modifiers:
- `.glassCard()` — glassmorphism with emerald gradient + teal border
- `.goldCard()` — gold-bordered card for next prayer highlight

Layout constants: popover 320×520, corner radius 12/8, card padding 14.

---

## Building & Running

```bash
# Option A: xcodegen (recommended)
brew install xcodegen
xcodegen generate         # Creates SalahTime.xcodeproj from project.yml
open SalahTime.xcodeproj  # Then ⌘R to build and run

# Option B: Manual Xcode setup (see XCODE_SETUP.md)

# Build release DMG
chmod +x scripts/build-dmg.sh
./scripts/build-dmg.sh
# Output: dist/SalahTime.dmg
```

**Required Info.plist keys** (auto-configured by `project.yml`):
- `LSUIElement = YES` — menubar-only, no Dock icon
- `NSLocationWhenInUseUsageDescription` — location permission prompt

---

## Known Gotchas

1. **`onPrayerTimeArrived` creates a new `LocationManager()`** — this is a TODO; should use the injected instance from app-level environment
2. **No `.xcodeproj` in git** — generated via `xcodegen generate` from `project.yml`
3. **Adhan audio file not bundled in repo** — app works without it, user imports via Settings or adds `default_adhan.m4a` to Resources
4. **`observeLocationChanges` uses a polling Timer** — works for initial setup but could be replaced with observation-based approach
5. **All `NotificationCenter.default` observers in `PopoverView.setupApp()`** are never removed — acceptable for a menubar app that lives for the process lifetime
6. **Tests use app-hosted test bundle** — `SalahTimeTests` target depends on the app being built; tests run inside the app process

---

## Testing

Uses **Swift Testing** framework (`@Test`, `@Suite` macros — not XCTest).

### Test Suites

| Suite | File | What it tests |
|---|---|---|
| `HijriDateCalculator` | `HijriDateCalculatorTests.swift` | Output format, Arabic suffix `هـ`, valid month names, special day detection |
| `QiblaCalculator` | `QiblaCalculatorTests.swift` | Known city→Makkah bearings (Jakarta, NYC, London, Cairo, KL), all 8 compass sectors, format output |
| `AladhanAPIClient` | `AladhanAPIClientTests.swift` | Time string parsing (`"HH:mm"`, `"HH:mm (WIB)"`), JSON response decoding, error types |
| `Prayer / PrayerTime` | `PrayerModelTests.swift` | Enum properties (names, icons, `isActualPrayer`), `formattedTime` (midnight, afternoon), UUID uniqueness |
| `AppSettings` | `AppSettingsTests.swift` | Singleton identity, notification helpers, calculation method enum (count, API number uniqueness), Codable round-trip |

### Running Tests Locally

```bash
# Generate project (if not already done)
xcodegen generate

# Run all tests
xcodebuild test \
  -project SalahTime.xcodeproj \
  -scheme SalahTimeTests \
  -destination 'platform=macOS' \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGNING_REQUIRED=NO

# Or via Xcode: ⌘U
```

### Test Architecture Notes

- Tests use `@testable import SalahTime` — app-hosted test bundle
- Pure logic services tested directly: `HijriDateCalculator`, `QiblaCalculator`, `AladhanAPIClient`
- `AladhanAPIClient.parseTimeString` is private — tests mirror the parsing logic locally
- `AppSettings` tests use the shared singleton (tests may be affected by user-changed defaults)
- No mocking framework — tests focus on pure functions and value types
- SwiftUI views have `#Preview` macros but no snapshot tests yet

---

## CI/CD

### CI Pipeline (`.github/workflows/ci.yml`)

**Trigger**: Push to `main` or PR against `main`

```
Checkout → Install xcodegen → Generate xcodeproj → Resolve SPM → Build → Test → Upload results
```

- Runs on `macos-14` (Sonoma) with Xcode 15
- SPM packages cached in `.spm-cache/` directory
- Test results uploaded as artifacts (`.xcresult` bundle, 7-day retention)
- Concurrency group cancels in-progress runs on new pushes

### Release Pipeline (`.github/workflows/release.yml`)

**Trigger**: Push tag matching `v*` (e.g., `git tag v1.0.0 && git push --tags`)

```
Checkout → xcodegen → SPM → Test → Archive (Release) → Export .app → Create DMG → GitHub Release
```

- Runs full test suite before building release
- Extracts version from tag (`v1.2.3` → `1.2.3`)
- Creates versioned DMG: `SalahTime-1.2.3.dmg`
- Auto-generates release notes from git log
- Publishes GitHub Release with DMG attached
- **Unsigned build** — release notes include Gatekeeper bypass instructions

### Creating a Release

```bash
# 1. Update version in project.yml if needed
# 2. Commit and push
git add -A && git commit -m "release: v1.0.0"
git push origin main

# 3. Tag and push
git tag v1.0.0
git push --tags

# 4. GitHub Actions builds DMG and creates release automatically
```

---

## Deployment

| Method | Command | Output |
|---|---|---|
| **Local dev** | `xcodegen generate && open SalahTime.xcodeproj` → ⌘R | Runs in menubar |
| **Manual DMG** | `./scripts/build-dmg.sh` | `dist/SalahTime.dmg` |
| **CI Release** | `git tag v1.x.x && git push --tags` | GitHub Release + DMG |
| **Notarization** | See `build-dmg.sh` footer | Requires Apple Developer account |

### Signing & Notarization (Optional)

The default build is **unsigned** (`CODE_SIGN_IDENTITY="-"`). For proper distribution:

1. Get an Apple Developer account ($99/year)
2. Create a Developer ID Application certificate
3. Add signing secrets to GitHub repo settings:
   - `APPLE_CERTIFICATE_P12` — base64-encoded .p12
   - `APPLE_CERTIFICATE_PASSWORD`
   - `APPLE_ID`, `APPLE_TEAM_ID`, `APPLE_APP_PASSWORD`
4. Update `release.yml` to use proper signing and `xcrun notarytool submit`

---

## Calculation Methods Reference

| Enum Case | Adhan Library Method | Aladhan API # |
|---|---|---|
| `.muslimWorldLeague` | `.muslimWorldLeague` | 3 |
| `.northAmerica` | `.northAmerica` | 2 |
| `.egyptian` | `.egyptian` | 5 |
| `.ummAlQura` | `.ummAlQura` | 4 |
| `.karachi` | `.karachi` | 1 |
| `.dubai` | `.dubai` | 12 |
| `.kuwait` | `.kuwait` | 9 |
| `.qatar` | `.qatar` | 10 |
| `.singapore` | `.singapore` | 11 |
| `.kemenag` | `.other` (Fajr 20°, Isha 18°) | 20 |
