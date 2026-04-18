# 🕌 Salah Time

A beautiful, lightweight macOS menubar app for Islamic prayer time reminders.

![macOS](https://img.shields.io/badge/macOS-14%2B-black?logo=apple)
![Swift](https://img.shields.io/badge/Swift-5.9%2B-orange?logo=swift)
![License](https://img.shields.io/badge/License-MIT-green)

## ✨ Features

- **🕐 Accurate Prayer Times** — Calculated locally using [adhan-swift](https://github.com/batoulapps/adhan-swift) with Aladhan API fallback
- **⏱️ Live Countdown** — Animated countdown to the next prayer with progress ring
- **📅 Hijri Calendar** — Umm Al-Qura astronomical calendar with Arabic display
- **🧭 Qibla Compass** — Direction to Makkah from your current location
- **🔔 Smart Notifications** — Per-prayer toggles with configurable pre-reminders
- **📿 Adhan Playback** — Bundled default + custom audio import
- **📍 Auto Location** — CoreLocation auto-detect with manual override
- **🎨 Islamic Aesthetic** — Dark emerald/gold theme with geometric patterns
- **⚡ Lightweight** — No database, minimal memory footprint, native SwiftUI
- **🚀 Launch at Login** — Always ready when you open your Mac

## 📸 Screenshots

*Coming soon*

## 🛠️ Requirements

- macOS 14 (Sonoma) or later
- Xcode 15+
- Swift 5.9+

## 🚀 Getting Started

### Build from Source

1. Clone the repository:
   ```bash
   git clone https://github.com/YOUR_USERNAME/salah-time.git
   cd salah-time
   ```

2. Open `SalahTime.xcodeproj` in Xcode

3. Add the adhan-swift package dependency:
   - File → Add Package Dependencies
   - Enter: `https://github.com/batoulapps/adhan-swift`
   - Click "Add Package"

4. Build and run (⌘R)

> See [XCODE_SETUP.md](XCODE_SETUP.md) for detailed first-time setup instructions.

### Download

Download the latest `.dmg` from [Releases](https://github.com/YOUR_USERNAME/salah-time/releases).

## 🎛️ Configuration

| Setting | Default | Options |
|---|---|---|
| Calculation Method | Muslim World League | MWL, ISNA, Egyptian, Umm Al-Qura, Karachi, Dubai, Kuwait, Qatar, Singapore, KEMENAG |
| Location | Auto-detect | Auto / Manual coordinates |
| Menubar Display | Icon only | Icon / Icon + Prayer / Icon + Time |
| Pre-reminder | 15 min | Off / 5 / 10 / 15 / 30 min |
| Adhan | Default | Default / Custom audio file |
| Launch at Login | Enabled | On / Off |

## 📦 Dependencies

| Package | Purpose |
|---|---|
| [adhan-swift](https://github.com/batoulapps/adhan-swift) | Prayer time calculation engine |

## 🗺️ Roadmap

- [ ] Dark / Light theme toggle
- [ ] Daily Quran verse with translation
- [ ] Ramadan mode (Suhoor/Iftar countdown)
- [ ] macOS Widget (WidgetKit)
- [ ] Keyboard shortcuts

## 🤝 Contributing

Contributions are welcome! Please open an issue first to discuss what you'd like to change.

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

---

*بسم الله الرحمن الرحيم*
