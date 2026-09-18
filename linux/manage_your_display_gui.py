#!/usr/bin/env python3
"""
Manage Your Display - Linux System Tray & Hardware Display Controller
Provides a full BetterDisplay Pro style system tray popover and multi-monitor controller for Linux.
"""

import sys
import os
from displaycraft_core import DisplayCraftLinux

try:
    from PyQt6.QtWidgets import (
        QApplication, QSystemTrayIcon, QMenu, QWidget, QVBoxLayout,
        QHBoxLayout, QLabel, QSlider, QPushButton, QTabWidget,
        QScrollArea, QFrame, QCheckBox, QComboBox
    )
    from PyQt6.QtCore import Qt, QSize, QTimer
    from PyQt6.QtGui import QIcon, QFont, QColor, QPalette, QAction, QPainter, QBrush
except ImportError:
    print("PyQt6 is required for the Linux GUI. Run './linux/install.sh' to install dependencies.")
    sys.exit(0)

class DisplayCard(QFrame):
    def __init__(self, display, engine, parent=None):
        super().__init__(parent)
        self.display = display
        self.engine = engine
        self.setFrameShape(QFrame.Shape.StyledPanel)
        self.setStyleSheet("""
            QFrame {
                background-color: rgba(255, 255, 255, 0.08);
                border: 1px solid rgba(255, 255, 255, 0.15);
                border-radius: 12px;
                padding: 10px;
                color: white;
            }
            QLabel {
                color: #f0f0f0;
                font-family: sans-serif;
            }
            QSlider::groove:horizontal {
                height: 4px;
                background: rgba(255, 255, 255, 0.2);
                border-radius: 2px;
            }
            QSlider::sub-page:horizontal {
                background: #3584e4;
                border-radius: 2px;
            }
            QSlider::handle:horizontal {
                background: white;
                width: 14px;
                margin-top: -5px;
                margin-bottom: -5px;
                border-radius: 7px;
            }
        """)

        layout = QVBoxLayout(self)
        layout.setSpacing(8)

        # Header
        header_layout = QHBoxLayout()
        name_label = QLabel(f"🖥️ {self.display.name}")
        name_label.setStyleSheet("font-weight: bold; font-size: 13px;")
        header_layout.addWidget(name_label)
        header_layout.addStretch()

        self.power_btn = QPushButton("ON" if self.display.is_powered_on else "OFF")
        self.power_btn.setCheckable(True)
        self.power_btn.setChecked(self.display.is_powered_on)
        self.power_btn.setStyleSheet("""
            QPushButton {
                background-color: #3584e4;
                color: white;
                border-radius: 6px;
                padding: 4px 10px;
                font-weight: bold;
                font-size: 11px;
            }
            QPushButton:!checked {
                background-color: #e01b24;
            }
        """)
        self.power_btn.clicked.connect(self.toggle_power)
        header_layout.addWidget(self.power_btn)
        layout.addLayout(header_layout)

        # Brightness
        b_label_layout = QHBoxLayout()
        b_title = QLabel("Brightness (Combined)")
        b_title.setStyleSheet("font-size: 11px; opacity: 0.8;")
        self.b_val_label = QLabel(f"{self.display.brightness}%")
        self.b_val_label.setStyleSheet("font-size: 11px; font-weight: bold;")
        b_label_layout.addWidget(b_title)
        b_label_layout.addStretch()
        b_label_layout.addWidget(self.b_val_label)
        layout.addLayout(b_label_layout)

        self.b_slider = QSlider(Qt.Orientation.Horizontal)
        self.b_slider.setRange(0, 100)
        self.b_slider.setValue(self.display.brightness)
        self.b_slider.valueChanged.connect(self.on_brightness_change)
        layout.addWidget(self.b_slider)

        # Volume
        v_label_layout = QHBoxLayout()
        v_title = QLabel("Volume")
        v_title.setStyleSheet("font-size: 11px; opacity: 0.8;")
        self.v_val_label = QLabel(f"{self.display.volume}%")
        self.v_val_label.setStyleSheet("font-size: 11px; font-weight: bold;")
        v_label_layout.addWidget(v_title)
        v_label_layout.addStretch()
        v_label_layout.addWidget(self.v_val_label)
        layout.addLayout(v_label_layout)

        self.v_slider = QSlider(Qt.Orientation.Horizontal)
        self.v_slider.setRange(0, 100)
        self.v_slider.setValue(self.display.volume)
        self.v_slider.valueChanged.connect(self.on_volume_change)
        layout.addWidget(self.v_slider)

        # Input Switcher
        input_layout = QHBoxLayout()
        input_title = QLabel("Input Source:")
        input_title.setStyleSheet("font-size: 11px;")
        input_layout.addWidget(input_title)
        
        self.input_combo = QComboBox()
        self.input_combo.addItems(self.display.available_inputs)
        self.input_combo.setStyleSheet("background: rgba(0,0,0,0.4); color: white; border-radius: 4px; padding: 2px;")
        self.input_combo.currentIndexChanged.connect(self.on_input_change)
        input_layout.addWidget(self.input_combo)
        layout.addLayout(input_layout)

    def on_brightness_change(self, val):
        self.b_val_label.setText(f"{val}%")
        self.engine.set_brightness(self.display.display_id, val)

    def on_volume_change(self, val):
        self.v_val_label.setText(f"{val}%")
        self.engine.set_volume(self.display.display_id, val)

    def on_input_change(self, idx):
        code_map = [0x11, 0x12, 0x0F, 0x10, 0x1B]
        if idx < len(code_map):
            self.engine.set_input_source(self.display.display_id, code_map[idx])

    def toggle_power(self):
        power_state = self.power_btn.isChecked()
        self.power_btn.setText("ON" if power_state else "OFF")
        self.engine.set_power(self.display.display_id, power_state)

class ManageYourDisplayPopover(QWidget):
    def __init__(self, engine, parent=None):
        super().__init__(parent)
        self.engine = engine
        self.setWindowTitle("Manage Your Display")
        self.setWindowFlags(Qt.WindowType.Popup | Qt.WindowType.FramelessWindowHint)
        self.setAttribute(Qt.WidgetAttribute.WA_TranslucentBackground)
        self.setFixedSize(360, 580)
        self.setup_ui()

    def setup_ui(self):
        main_layout = QVBoxLayout(self)
        main_layout.setContentsMargins(10, 10, 10, 10)

        # Background Container with dark frosted blur style
        container = QFrame(self)
        container.setStyleSheet("""
            QFrame {
                background-color: rgba(25, 25, 30, 0.95);
                border: 1px solid rgba(255, 255, 255, 0.18);
                border-radius: 16px;
            }
        """)
        container_layout = QVBoxLayout(container)
        container_layout.setContentsMargins(12, 12, 12, 12)
        container_layout.setSpacing(10)

        # Header Title
        title_bar = QHBoxLayout()
        title = QLabel("Manage Your Display")
        title.setStyleSheet("font-size: 14px; font-weight: bold; color: white;")
        badge = QLabel("PRO")
        badge.setStyleSheet("background: #3584e4; color: white; border-radius: 4px; padding: 2px 6px; font-size: 10px; font-weight: bold;")
        title_bar.addWidget(title)
        title_bar.addWidget(badge)
        title_bar.addStretch()
        container_layout.addLayout(title_bar)

        # Scrollable Display Cards
        scroll = QScrollArea()
        scroll.setWidgetResizable(True)
        scroll.setStyleSheet("background: transparent; border: none;")
        
        scroll_content = QWidget()
        scroll_layout = QVBoxLayout(scroll_content)
        scroll_layout.setContentsMargins(0, 0, 0, 0)
        scroll_layout.setSpacing(10)

        for disp in self.engine.displays:
            card = DisplayCard(disp, self.engine)
            scroll_layout.addWidget(card)

        scroll_layout.addStretch()
        scroll.setWidget(scroll_content)
        container_layout.addWidget(scroll)

        # Presets Bar
        preset_layout = QHBoxLayout()
        for p_name, icon in [("Work", "☀️"), ("Night", "🌙"), ("Gaming", "🎮"), ("Focus", "🎯")]:
            p_btn = QPushButton(f"{icon} {p_name}")
            p_btn.setStyleSheet("""
                QPushButton {
                    background: rgba(255,255,255,0.1);
                    color: white;
                    border-radius: 6px;
                    padding: 5px;
                    font-size: 11px;
                }
                QPushButton:hover {
                    background: rgba(255,255,255,0.2);
                }
            """)
            preset_layout.addWidget(p_btn)
        container_layout.addLayout(preset_layout)

        # Bottom Bar
        bottom_bar = QHBoxLayout()
        refresh_btn = QPushButton("🔄 Refresh")
        refresh_btn.setStyleSheet("background: transparent; color: #3584e4; font-size: 11px;")
        refresh_btn.clicked.connect(self.refresh_ui)
        bottom_bar.addWidget(refresh_btn)
        bottom_bar.addStretch()

        quit_btn = QPushButton("Quit")
        quit_btn.setStyleSheet("background: transparent; color: #e01b24; font-size: 11px;")
        quit_btn.clicked.connect(QApplication.instance().quit)
        bottom_bar.addWidget(quit_btn)

        container_layout.addLayout(bottom_bar)
        main_layout.addWidget(container)

    def refresh_ui(self):
        self.engine.refresh_displays()

class LinuxTrayApp:
    def __init__(self):
        self.app = QApplication(sys.argv)
        self.engine = DisplayCraftLinux()
        
        self.popover = ManageYourDisplayPopover(self.engine)
        
        # System Tray Icon
        self.tray = QSystemTrayIcon()
        # Fallback system display icon
        icon = QIcon.fromTheme("video-display", QIcon.fromTheme("display"))
        self.tray.setIcon(icon)
        self.tray.setVisible(True)
        self.tray.setToolTip("Manage Your Display (Digital KVM & Hardware Control)")

        self.tray.activated.connect(self.on_tray_activated)

    def on_tray_activated(self, reason):
        if reason == QSystemTrayIcon.ActivationReason.Trigger:
            if self.popover.isVisible():
                self.popover.hide()
            else:
                pos = self.tray.geometry().center()
                self.popover.move(pos.x() - 180, pos.y() + 20)
                self.popover.show()
                self.popover.activateWindow()

    def run(self):
        sys.exit(self.app.exec())

if __name__ == "__main__":
    app = LinuxTrayApp()
    app.run()
