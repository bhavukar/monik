#!/usr/bin/env python3
"""
DisplayCraft Linux Engine
Full hardware display controller for Linux (X11 & Wayland).
Controls brightness, volume, input sources, resolutions, rotation, and power via DDC/CI, xrandr, and sysfs.
"""

import os
import re
import subprocess
import json
from typing import List, Dict, Optional

class LinuxDisplay:
    def __init__(self, display_id: int, name: str, is_builtin: bool = False):
        self.display_id = display_id
        self.name = name
        self.is_builtin = is_builtin
        self.brightness = 100
        self.volume = 100
        self.contrast = 50
        self.current_resolution = "1920x1080"
        self.refresh_rate = 60.0
        self.rotation = "normal"
        self.is_powered_on = True
        self.available_resolutions = []
        self.available_inputs = ["HDMI-1", "HDMI-2", "DisplayPort-1", "DisplayPort-2", "USB-C"]

    def to_dict(self):
        return {
            "id": self.display_id,
            "name": self.name,
            "is_builtin": self.is_builtin,
            "brightness": self.brightness,
            "volume": self.volume,
            "contrast": self.contrast,
            "current_resolution": self.current_resolution,
            "refresh_rate": self.refresh_rate,
            "rotation": self.rotation,
            "is_powered_on": self.is_powered_on,
            "available_resolutions": self.available_resolutions
        }

class DisplayCraftLinux:
    def __init__(self):
        self.displays: List[LinuxDisplay] = []
        self.is_wayland = bool(os.environ.get("WAYLAND_DISPLAY"))
        self.refresh_displays()

    def refresh_displays(self):
        self.displays = []
        
        # 1. Detect external monitors via ddcutil
        try:
            res = subprocess.run(["ddcutil", "detect", "--terse"], capture_output=True, text=True, timeout=5)
            if res.returncode == 0:
                lines = res.stdout.splitlines()
                current_id = None
                current_model = "External Monitor"
                for line in lines:
                    if line.startswith("Display"):
                        parts = line.split()
                        if len(parts) >= 2 and parts[1].isdigit():
                            current_id = int(parts[1])
                    elif "Model:" in line and current_id is not None:
                        current_model = line.split("Model:", 1)[1].strip()
                        self.displays.append(LinuxDisplay(current_id, current_model, is_builtin=False))
                        current_id = None
        except Exception:
            pass

        # 2. Detect built-in display via /sys/class/backlight
        backlight_dir = "/sys/class/backlight"
        if os.path.exists(backlight_dir):
            devices = os.listdir(backlight_dir)
            if devices:
                builtin = LinuxDisplay(display_id=0, name="Built-in Laptop Display", is_builtin=True)
                self.displays.insert(0, builtin)

        # 3. Query resolutions via xrandr or wlr-randr
        if not self.is_wayland:
            try:
                xrandr_out = subprocess.run(["xrandr", "--query"], capture_output=True, text=True).stdout
                self._parse_xrandr(xrandr_out)
            except Exception:
                pass

        # If no display found, create default placeholder
        if not self.displays:
            self.displays.append(LinuxDisplay(display_id=1, name="Default Linux Screen", is_builtin=False))

    def _parse_xrandr(self, output: str):
        current_disp = None
        for line in output.splitlines():
            if " connected" in line:
                tokens = line.split()
                name = tokens[0]
                # Match or create display
                matching = next((d for d in self.displays if d.name in line or name in d.name), None)
                if not matching:
                    matching = LinuxDisplay(len(self.displays) + 1, name, is_builtin="eDP" in name)
                    self.displays.append(matching)
                current_disp = matching
            elif current_disp and re.match(r"^\s+\d+x\d+", line):
                res_match = re.search(r"(\d+x\d+)", line)
                if res_match:
                    res_str = res_match.group(1)
                    if res_str not in current_disp.available_resolutions:
                        current_disp.available_resolutions.append(res_str)
                    if "*" in line:
                        current_disp.current_resolution = res_str

    # Hardware Control Methods
    def set_brightness(self, display_id: int, value: int) -> bool:
        val = max(0, min(100, value))
        display = next((d for d in self.displays if d.display_id == display_id), None)
        if not display:
            return False
        
        display.brightness = val
        if display.is_builtin:
            # Set backlight in /sys/class/backlight
            backlight_dir = "/sys/class/backlight"
            if os.path.exists(backlight_dir) and os.listdir(backlight_dir):
                dev = os.listdir(backlight_dir)[0]
                max_path = f"{backlight_dir}/{dev}/max_brightness"
                set_path = f"{backlight_dir}/{dev}/brightness"
                if os.path.exists(max_path):
                    with open(max_path, "r") as f:
                        max_b = int(f.read().strip())
                    target_b = int((val / 100.0) * max_b)
                    try:
                        with open(set_path, "w") as f:
                            f.write(str(target_b))
                        return True
                    except PermissionError:
                        subprocess.run(["brightnessctl", "s", f"{val}%"], capture_output=True)
                        return True
        else:
            # DDC/CI
            ret = subprocess.run(["ddcutil", "--display", str(display_id), "setvcp", "10", str(val)], capture_output=True)
            return ret.returncode == 0
        return False

    def set_volume(self, display_id: int, value: int) -> bool:
        val = max(0, min(100, value))
        display = next((d for d in self.displays if d.display_id == display_id), None)
        if not display:
            return False
        
        display.volume = val
        # DDC/CI Audio Volume (0x62)
        subprocess.run(["ddcutil", "--display", str(display_id), "setvcp", "62", str(val)], capture_output=True)
        # Also sync system pulse/pipewire audio
        subprocess.run(["pactl", "set-sink-volume", "@DEFAULT_SINK@", f"{val}%"], capture_output=True)
        return True

    def set_input_source(self, display_id: int, source_code: int) -> bool:
        ret = subprocess.run(["ddcutil", "--display", str(display_id), "setvcp", "60", str(source_code)], capture_output=True)
        return ret.returncode == 0

    def set_power(self, display_id: int, power_on: bool) -> bool:
        display = next((d for d in self.displays if d.display_id == display_id), None)
        if display:
            display.is_powered_on = power_on
        vcp_val = "1" if power_on else "4"
        ret = subprocess.run(["ddcutil", "--display", str(display_id), "setvcp", "d6", vcp_val], capture_output=True)
        return ret.returncode == 0

    def set_resolution(self, output_name: str, resolution: str, rate: float = 60.0) -> bool:
        if not self.is_wayland:
            ret = subprocess.run(["xrandr", "--output", output_name, "--mode", resolution, "--rate", str(rate)], capture_output=True)
            return ret.returncode == 0
        return False
