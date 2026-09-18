<div align="center">

# 🖥️ Manage Your Display

### **The Ultimate Open-Source Hardware Display Controller**
#### *A 100% Free, Full-Featured Alternative to BetterDisplay Pro for macOS, Linux, and Windows.*

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![macOS](https://img.shields.io/badge/macOS-Apple%20Silicon%20%26%20Intel-black?logo=apple)](https://github.com/bhavukarora/monik)
[![Linux](https://img.shields.io/badge/Linux-X11%20%26%20Wayland-orange?logo=linux)](https://github.com/bhavukarora/monik)
[![Windows](https://img.shields.io/badge/Windows-10%20%26%2011-0078D6?logo=windows)](https://github.com/bhavukarora/monik)
[![Open Source](https://img.shields.io/badge/Free%20%26%20Open%20Source-Forever-emerald)](https://github.com/bhavukarora/monik)

---

</div>

## 🌟 Overview

**Manage Your Display** is a fast, lightweight, and completely open-source hardware display controller. It gives you full low-level control over every connected external monitor and laptop screen directly from your **Menu Bar (macOS)** and **System Tray (Linux & Windows)**.

Control hardware brightness, contrast, volume, input sources, custom resolutions, refresh rates, display scaling, underscan/overscan, and discrete screen power—**without $20 paywalls or subscription restrictions**.

---

## ✨ Key Features

### 🍏 macOS (Native Swift & Apple Silicon DDC Engine)
* **Frosted Glass Menu Bar Popover**: Instant access to all monitors with smooth macOS vibrancy.
* **Apple Silicon & Intel DDC/CI**: Direct hardware I2C control for brightness (`0x10`), contrast (`0x12`), audio volume (`0x62`), mute (`0x8D`), input sources (`0x60`), and DPMS power (`0xD6`).
* **Native Resolution Picker**: Dropdown resolution switcher fetching all hardware modes (HiDPI, Retina pixel doubling, up to 144Hz+).
* **True Display Power & Clamshell Isolation**: Turn individual displays ON/OFF cleanly using SkyLight window-server disconnection (`CGSConfigureDisplayEnabled`), hardware DPMS power off, and zero-gamma LUT blackout (`CGSetDisplayTransferByTable`).
* **Underscan & Overscan Sizing**: Adjustable 0%–25% underscan padding and hardware VCP geometry scaling to eliminate TV and projector edge cropping.
* **Smart Panel Intelligence**: Automated calculation of physical diagonal size, pixel density (PPI), aspect ratio, and optimal color profiles (Display P3 vs sRGB IEC61966-2.1) with 1-click calibration.
* **Global Hotkeys & Translucent Bezel OSD**: Native on-screen display HUD overlay on keypress with customizable shortcuts.
* **Multi-Monitor Presets & Group Sync**: 1-Click modes (*Work & Day*, *Ultra-Dim Night*, *Gaming 144Hz*, *Single Screen Focus*) and grouped monitor sync.
* **Launch on Startup**: Native macOS login item registration via `SMAppService`.

### 🐧 Linux (PyQt6 System Tray & CLI)
* **System Tray GUI**: Dark-mode popover matching the macOS interface.
* **Hardware DDC via `ddcutil`**: Real-time control of I2C bus monitors and `/sys/class/backlight` laptop screens.
* **Display Server Support**: X11 and Wayland resolution and refresh rate switching.
* **Full CLI Suite (`displaycraft`)**: Scriptable CLI for automated terminal workflows.

### 🪟 Windows (Flutter & DXVA2)
* **System Tray Integration**: Background tray menu with click-to-open controller.
* **Hardware DXVA2 DDC/CI**: Direct communication with Windows monitor APIs (`SetVCPFeature`, `GetVCPFeatureAndVCPFeatureReply`).

---

## 📊 Feature Comparison

| Feature | **Manage Your Display** | **BetterDisplay Pro** | **MonitorControl** | **Lunar Pro** |
| :--- | :---: | :---: | :---: | :---: |
| **Price** | 🟢 **100% Free (MIT)** | 🔴 **$20.00 Paywall** | 🟢 Free | 🔴 **$23.00 Paywall** |
| **Apple Silicon DDC Brightness & Volume** | ✅ | ✅ | ✅ | ✅ |
| **Native Resolution Dropdown & HiDPI** | ✅ | ✅ | ❌ | ❌ |
| **Discrete Screen Power ON/OFF (SkyLight)** | ✅ | ✅ | ❌ | ✅ |
| **Underscan & Overscan Sizing** | ✅ | ✅ | ❌ | ❌ |
| **Smart Panel Intelligence & PPI Math** | ✅ | ❌ | ❌ | ❌ |
| **Cross-Platform (macOS, Linux, Windows)** | ✅ | ❌ (Mac Only) | ❌ (Mac Only) | ❌ (Mac Only) |
| **Global Hotkeys & Floating OSD HUD** | ✅ | ✅ | ✅ | ✅ |
| **Multi-Monitor Presets & Group Sync** | ✅ | ✅ | ❌ | ✅ |

---

## 🚀 Installation & Quick Start

### 🍏 macOS

```bash
# Clone the repository
git clone https://github.com/bhavukarora/monik.git
cd monik

# Build the native .app bundle
./scripts/build_app.sh

# Launch Manage Your Display
open "build/Manage Your Display.app"
```

### 🐧 Linux

```bash
# Install dependencies & configure I2C permissions
chmod +x linux/install.sh
./linux/install.sh

# Run System Tray GUI
python3 linux/manage_your_display_gui.py

# Or use CLI
displaycraft detect
```

### 🪟 Windows

```bash
# Run Windows Flutter app
flutter run -d windows
```

---

## 🌐 Animated Landing Page (Vercel Ready)

The project includes an interactive animated landing page in [`web/`](./web) featuring a live simulator widget.

### Local Preview:
```bash
cd web
npx serve .
```

### Deploy to Vercel:
```bash
# Inside web/ directory
vercel --prod
```

---

## ⌨️ Default Keyboard Shortcuts

| Action | Shortcut |
| :--- | :--- |
| **Increase Brightness** | `Cmd + Opt + ↑` |
| **Decrease Brightness** | `Cmd + Opt + ↓` |
| **Increase Volume** | `Cmd + Opt + →` |
| **Decrease Volume** | `Cmd + Opt + ←` |
| **Toggle Display Power** | `Cmd + Opt + Ctrl + P` |
| **Cycle Display Preset** | `Cmd + Opt + Ctrl + S` |

---

## 📝 License

Distributed under the **MIT License**. Free for personal and commercial use forever.

Contributions and pull requests are warmly welcomed!
