# Monik - Your Digital KVM & Display Control Hub for Windows

[![Platform Windows](https://img.shields.io/badge/platform-windows-brightgreen?style=for-the-badge&logo=windows)](https://www.microsoft.com/windows/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)
**Monik** is a lightweight Windows application that gives you convenient control over your monitor's settings and provides insights into your system hardware. It acts as a software-based alternative for common KVM switch functionalities, display adjustments, and system information utilities. Easily manage brightness, switch input sources, adjust refresh rates, and view detailed system specifications directly from your desktop.

Currently, Monik is available for **Windows**, with future plans to support macOS and Linux.

## ✨ Features

* **Monitor Control:**
    * **Brightness Adjustment:** Quickly adjust the brightness levels of your connected monitor(s) without fumbling with physical buttons.
    * **Input Source Switching:** Seamlessly switch between different input sources on your monitor (e.g., HDMI-1, HDMI-2, DisplayPort).
    * **Refresh Rate Configuration:** Change the refresh rate of your display for smoother visuals or battery saving.
    * **(Planned) Contrast Adjustment:** Fine-tune monitor contrast.
    * **(Planned) Volume Control:** Adjust built-in monitor speaker volume (if applicable).
    * **(Planned) Power Management:** Control monitor power states.
* **System Information:**
    * **Hardware Details:** Fetch and display comprehensive system information, similar to CPU-Z (e.g., CPU, GPU, RAM, Motherboard details).
* **Usability:**
    * **Monitor Detection:** Automatically identifies connected displays compatible with DDC/CI.
    * **(Planned) Custom Profiles:** Save and load your preferred display and system settings.

## 🚀 Download & Installation

Get the latest version of Monik for Windows from our **[GitHub Releases](https://github.com/bhavukar/monik/releases)** page.
1.  Go to the [Releases](https://github.com/YOUR_USERNAME/YOUR_REPONAME/releases) page.
2.  Download the latest Windows installer (`.exe` or `.msi`) or portable version (`.zip`).
3.  **For the installer:** Run the downloaded installer and follow the on-screen instructions.
4.  **For the portable version:** Extract the ZIP archive to your desired location and run `Monik.exe`.

## 💡 How It Works

Monik communicates with your monitors using the **Display Data Channel/Command Interface (DDC/CI)** protocol for display adjustments. For system information, it utilizes native Windows APIs to query hardware details.

**Requirements:**
* Windows 10 or newer.
* For display control: A monitor that supports DDC/CI (most modern monitors do).

## 🖥️ Supported Platforms

* **Windows:** ✅ (Actively supported)
* **macOS:** 🟡 (Planned for future release)
* **Linux:** 🟡 (Planned for future release)

## 🤝 Contributing & Feedback

While this repository primarily hosts the compiled application, contributions to the underlying source code (if made public/separate) or suggestions for this application are welcome!

* **Found a bug or have a feature request?** Please [open an issue](https://github.com/bhavukar/monik/issues).
* **Want to contribute to development?** (Details for contributing to the source code project would go here, or link to the source code repository if it's different from where the releases are hosted).

## 📝 License

This application is licensed under the **MIT License**. See the `LICENSE.txt` file included with the application for details.
(You'll need to include a `LICENSE.txt` file with the MIT license text in your release archives/installers).

---

Thank you for using Monik! We hope it makes managing your display settings and understanding your system easier.
