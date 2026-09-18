#!/usr/bin/env python3
"""
DisplayCraft Linux CLI
Command line interface for managing displays and hardware DDC on Linux.
"""

import sys
import argparse
from displaycraft_core import DisplayCraftLinux

def main():
    parser = argparse.ArgumentParser(description="DisplayCraft - Digital KVM & Display Hardware Controller for Linux")
    subparsers = parser.add_subparsers(dest="command", help="Available commands")

    # detect
    subparsers.add_parser("detect", help="Detect all connected displays")

    # set-brightness
    b_parser = subparsers.add_parser("set-brightness", help="Set brightness (0-100)")
    b_parser.add_argument("-d", "--display", type=int, default=1, help="Display ID")
    b_parser.add_argument("value", type=int, help="Brightness level (0-100)")

    # set-volume
    v_parser = subparsers.add_parser("set-volume", help="Set volume (0-100)")
    v_parser.add_argument("-d", "--display", type=int, default=1, help="Display ID")
    v_parser.add_argument("value", type=int, help="Volume level (0-100)")

    # set-power
    p_parser = subparsers.add_parser("set-power", help="Set display power (on/off)")
    p_parser.add_argument("-d", "--display", type=int, default=1, help="Display ID")
    p_parser.add_argument("state", choices=["on", "off"], help="Power state")

    # set-input
    i_parser = subparsers.add_parser("set-input", help="Switch input source")
    i_parser.add_argument("-d", "--display", type=int, default=1, help="Display ID")
    i_parser.add_argument("source", choices=["hdmi1", "hdmi2", "dp1", "dp2", "usbc"], help="Input source")

    args = parser.parse_args()
    engine = DisplayCraftLinux()

    if args.command == "detect":
        print(f"🖥️  Found {len(engine.displays)} Display(s):")
        for d in engine.displays:
            builtin_tag = " [Built-in]" if d.is_builtin else " [External DDC/CI]"
            print(f" • Display {d.display_id}: {d.name}{builtin_tag} (Resolution: {d.current_resolution})")
    elif args.command == "set-brightness":
        success = engine.set_brightness(args.display, args.value)
        print(f"☀️ Brightness for Display {args.display} set to {args.value}%: {'Success' if success else 'Failed'}")
    elif args.command == "set-volume":
        success = engine.set_volume(args.display, args.value)
        print(f"🔊 Volume for Display {args.display} set to {args.value}%: {'Success' if success else 'Failed'}")
    elif args.command == "set-power":
        success = engine.set_power(args.display, args.state == "on")
        print(f"⚡ Power for Display {args.display} set to {args.state}: {'Success' if success else 'Failed'}")
    elif args.command == "set-input":
        code_map = {"hdmi1": 0x11, "hdmi2": 0x12, "dp1": 0x0F, "dp2": 0x10, "usbc": 0x1B}
        code = code_map[args.source]
        success = engine.set_input_source(args.display, code)
        print(f"🔌 Input for Display {args.display} switched to {args.source.upper()}: {'Success' if success else 'Failed'}")
    else:
        parser.print_help()

if __name__ == "__main__":
    main()
