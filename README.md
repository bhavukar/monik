# Manage Your Display - The Ultimate Multi-Platform Display Controller

[![Platform macOS](https://img.shields.io/badge/platform-macOS-black?style=for-the-badge&logo=apple)](https://apple.com/)
[![Platform Linux](https://img.shields.io/badge/platform-Linux-orange?style=for-the-badge&logo=linux)](https://kernel.org/)
[![Platform Windows](https://img.shields.io/badge/platform-windows-brightgreen?style=for-the-badge&logo=windows)](https://www.microsoft.com/windows/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)

**Manage Your Display** is a complete, open-source display hardware controller, virtual screen manager, and digital KVM utility for **macOS**, **Linux**, and **Windows**.

It runs seamlessly from your **menu bar / system tray** across all platforms with instant hardware controls, customizable hotkeys, presets, and auto-start on boot.

---

## 🍏 macOS Features

* **Menu Bar Popover (Frosted Dark Vibrancy):**
  * Instant access to all connected & built-in displays (`MacBook Display`, `Acer KG271 C`, `Acer KG271`).
  * Real-time sliders for **Brightness (Combined)**, **Volume**, and **Resolution**.
* **Hardware DDC/CI & Power Control:**
  * Direct DDC/CI hardware brightness (`0x10`), contrast (`0x12`), and speaker volume (`0x62`).
  * Soft-disconnect and power state switching (`0xD6`) per display.
  * Clamshell & built-in MacBook display backlight control down to 0%.
* **Launch on Startup (Login Items):**
  * Native `SMAppService` background service toggle in Settings.
* **Customizable Global Hotkeys & OSD HUD:**
  * Assign hotkeys to toggle display power, cycle resolutions, switch inputs, or adjust brightness/volume.
  * Floating translucent OSD HUD overlay providing live visual feedback on keypress.
* **Display Presets & Group Sync:**
  * 1-Click presets: "Work & Day", "Ultra-Dim Night", "Gaming / Media", and "Single Screen Focus".
  * Synchronize brightness, volume, and power across display groups.
* **Virtual Screens (BetterDummy Engine):**
  * Generate custom virtual displays (16:9, 16:10 MacBook ratio, 21:9 UWQHD, 32:9 Super Ultrawide, 4:3, 1:1) up to 16K.
* **Multi-Tab Settings Window:**
  * Displays overview, per-display register inspectors, Display Groups, Application settings, Menu layout customization, Keyboard shortcuts editor, and System specs.

---

## 🐧 Linux Features (System Tray & CLI)

* **System Tray App (`linux/manage_your_display_gui.py`):**
  * System tray icon with dark popover window matching the macOS design.
  * Real-time sliders for Brightness, Volume, and Input Switching.
  * Multi-monitor cards with ON/OFF power toggles.
* **Hardware DDC/CI via `ddcutil`:**
  * Adjust hardware brightness, volume, input sources (HDMI/DisplayPort/USB-C), and power states.
* **Multi-Display Resolution & Refresh Rate Management:**
  * X11 and Wayland support via `xrandr` / `wlr-randr`.
* **Laptop Backlight Control:**
  * Seamless `/sys/class/backlight` hardware brightness adjustments.
* **CLI & Scripting (`displaycraft` / `manage-your-display`):**
  * Full CLI suite with `detect`, `set-brightness`, `set-volume`, `set-power`, `set-input`.

---

## 🪟 Windows Features (System Tray)

* **System Tray Integration:**
  * Background tray icon with click-to-open controller window.
  * DDC/CI communication via Windows DXVA2 APIs (`GetVCPFeatureAndVCPFeatureReply`, `SetVCPFeature`).
  * Multi-monitor brightness, volume, input source switching, and refresh rate adjustments.

---

## 🚀 Building & Running

### macOS:
```bash
# Direct run
swift run

# Build .app bundle
./scripts/build_app.sh
open "build/Manage Your Display.app"
```

### Linux:
```bash
# Install dependencies & configure I2C
chmod +x linux/install.sh
./linux/install.sh

# Run System Tray GUI
python3 linux/manage_your_display_gui.py

# Or use CLI
displaycraft detect
```

### Windows:
```bash
flutter run -d windows
```

---

## 📝 License

Licensed under the **MIT License**. Free and open-source forever.

---

Thank you for using **Manage Your Display**!

