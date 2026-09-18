#!/bin/bash
set -e

echo "🐧 Installing DisplayCraft for Linux..."

# Install required system packages
if command -v apt-get &>/dev/null; then
    sudo apt-get update
    sudo apt-get install -y ddcutil i2c-tools x11-xserver-utils brightnessctl python3-pyqt6
elif command -v dnf &>/dev/null; then
    sudo dnf install -y ddcutil i2c-tools xorg-x11-server-utils brightnessctl python3-qt6
elif command -v pacman &>/dev/null; then
    sudo pacman -S --noconfirm ddcutil i2c-tools xorg-xrandr brightnessctl python-pyqt6
fi

# Load i2c-dev kernel module
echo "🔌 Configuring I2C kernel module..."
sudo modprobe i2c-dev || true
echo "i2c-dev" | sudo tee /etc/modules-load.d/i2c-dev.conf

# Add current user to i2c group
sudo usermod -aG i2c $USER || true

# Install CLI binary
sudo cp linux/displaycraft_cli.py /usr/local/bin/displaycraft
sudo chmod +x /usr/local/bin/displaycraft

echo "✅ DisplayCraft successfully installed on Linux!"
echo "Run 'displaycraft detect' to test your monitors."
