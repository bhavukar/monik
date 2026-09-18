//
//  PreferencesWindow.swift
//  Manage Your Display
//

import SwiftUI
import AppKit
import CoreGraphics

public class PreferencesWindowController {
    public static let shared = PreferencesWindowController()
    private var window: NSWindow?
    
    public func show() {
        if let existing = window {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        let newWindow = NSWindow(
            contentRect: NSRect(x: 150, y: 150, width: 780, height: 580),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        newWindow.title = "Manage Your Display Settings"
        newWindow.center()
        newWindow.isReleasedWhenClosed = false
        newWindow.contentView = NSHostingView(rootView: FullSettingsView())
        newWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        self.window = newWindow
    }
}

enum SettingsTab: String, CaseIterable, Identifiable {
    case displays = "Displays"
    case groups = "Groups"
    case application = "Application"
    case menu = "Menu"
    case keyboard = "Keyboard"
    case presets = "Presets"
    case pro = "Pro"
    case about = "About"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .displays: return "display"
        case .groups: return "rectangle.3.group"
        case .application: return "switch.2"
        case .menu: return "text.bubble"
        case .keyboard: return "keyboard"
        case .presets: return "slider.horizontal.below.rectangle"
        case .pro: return "checkmark.shield"
        case .about: return "tag"
        }
    }
}

struct FullSettingsView: View {
    @State private var selectedTab: SettingsTab = .displays
    @State private var selectedDisplaySegment: String = "overview"
    @State private var showDetails: Bool = true
    @State private var selectedLanguage: String = "English (United States)"
    
    @ObservedObject var displayManager = DisplayManager.shared
    @ObservedObject var groupManager = DisplayGroupManager.shared
    @ObservedObject var virtualManager = VirtualDisplayManager.shared
    @ObservedObject var hotkeyManager = HotkeyManager.shared
    @ObservedObject var presetManager = PresetManager.shared
    @ObservedObject var launchAtLogin = LaunchAtLoginService.shared
    
    var body: some View {
        HStack(spacing: 0) {
            // Sidebar
            VStack(alignment: .leading, spacing: 4) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(SettingsTab.allCases) { tab in
                            Button(action: { selectedTab = tab }) {
                                HStack(spacing: 10) {
                                    Image(systemName: tab.icon)
                                        .font(.system(size: 14))
                                        .foregroundColor(selectedTab == tab ? .white : .blue)
                                        .frame(width: 20)
                                    
                                    Text(tab.rawValue)
                                        .font(.system(size: 13, weight: selectedTab == tab ? .semibold : .regular))
                                        .foregroundColor(selectedTab == tab ? .white : .primary)
                                    
                                    Spacer()
                                    
                                    if tab == .pro {
                                        Image(systemName: "checkmark.seal.fill")
                                            .font(.system(size: 11))
                                            .foregroundColor(.green)
                                    }
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 7)
                                .background(selectedTab == tab ? Color.accentColor.opacity(0.85) : Color.clear)
                                .cornerRadius(6)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(8)
                }
                
                Divider()
                
                // Sidebar Footer
                VStack(alignment: .leading, spacing: 8) {
                    Toggle("Show details", isOn: $showDetails)
                        .font(.system(size: 11))
                    
                    Button(action: {
                        MenuBarController.shared.togglePopover()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.forward.circle")
                                .font(.system(size: 11))
                            Text("App Menu")
                                .font(.system(size: 11))
                        }
                        .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "globe")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        Text(selectedLanguage)
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(10)
            }
            .frame(width: 195)
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // Content Area
            VStack(spacing: 0) {
                switch selectedTab {
                case .displays:
                    displaysTabView
                case .groups:
                    groupsTabView
                case .application:
                    applicationTabView
                case .menu:
                    menuTabView
                case .keyboard:
                    keyboardTabView
                case .presets:
                    presetsTabView
                case .pro:
                    proTabView
                case .about:
                    aboutTabView
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(NSColor.controlBackgroundColor))
        }
        .frame(minWidth: 780, minHeight: 560)
    }
    
    // MARK: - Displays Tab
    private var displaysTabView: some View {
        VStack(spacing: 0) {
            // Top Display Picker Bar
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    displaySegmentButton(
                        id: "overview",
                        title: "Overview",
                        icon: "list.bullet.circle.fill"
                    )
                    
                    ForEach(displayManager.displays) { d in
                        displaySegmentButton(
                            id: "\(d.id)",
                            title: d.name,
                            icon: d.isBuiltIn ? "laptopcomputer" : "display"
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(Color(NSColor.windowBackgroundColor).opacity(0.5))
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    if selectedDisplaySegment == "overview" {
                        displaysOverviewSection
                    } else if let disp = displayManager.displays.first(where: { "\($0.id)" == selectedDisplaySegment }) {
                        singleDisplayDetailSection(display: disp)
                    }
                }
                .padding(20)
            }
        }
    }
    
    private func displaySegmentButton(id: String, title: String, icon: String) -> some View {
        Button(action: { selectedDisplaySegment = id }) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(selectedDisplaySegment == id ? .blue : .secondary)
                Text(title)
                    .font(.system(size: 11, weight: selectedDisplaySegment == id ? .semibold : .regular))
                    .foregroundColor(selectedDisplaySegment == id ? .primary : .secondary)
                    .lineLimit(1)
            }
            .frame(width: 85, height: 58)
            .background(selectedDisplaySegment == id ? Color.accentColor.opacity(0.12) : Color.clear)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(selectedDisplaySegment == id ? Color.accentColor.opacity(0.4) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    private var displaysOverviewSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Virtual Screens
            VStack(alignment: .leading, spacing: 8) {
                Text("Virtual Screens")
                    .font(.headline)
                
                Text("(memory). Create virtual displays to stream in a PiP window, screen recording, or mirror to physical displays for HiDPI Retina scaling.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    Spacer()
                    Button("Create New Virtual Screen...") {
                        if let preset = virtualManager.presets.first {
                            _ = virtualManager.createVirtualDisplay(preset: preset)
                        }
                    }
                }
                
                DisclosureGroup("Advanced virtual screen settings...") {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(virtualManager.presets) { p in
                            HStack {
                                Text(p.name).font(.caption)
                                Spacer()
                                Button("Create") {
                                    _ = virtualManager.createVirtualDisplay(preset: p)
                                }
                                .font(.caption)
                            }
                        }
                    }
                    .padding(.top, 4)
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            .padding(14)
            .background(Color(NSColor.windowBackgroundColor))
            .cornerRadius(10)
            
            // Pro Display Connections
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    Text("Pro")
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(4)
                    
                    Text("Display Connections")
                        .font(.headline)
                }
                
                HStack {
                    Image(systemName: "power.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.red)
                    
                    Text("Enable connect/disconnect option for displays")
                        .font(.system(size: 13, weight: .semibold))
                    
                    Spacer()
                    
                    Toggle("", isOn: .constant(true))
                        .labelsHidden()
                        .toggleStyle(SwitchToggleStyle(tint: .blue))
                }
                
                Text("Disconnecting a display puts the display into sleep mode and removes it from the display layout. Connecting it restores the display. Disconnected displays can be reconnected with the header toggle, by turning the display on/off or closing and opening the lid for MacBook displays.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    Button("Connect All Displays Now") {
                        displayManager.connectAllDisplays()
                    }
                    .font(.caption)
                }
            }
            .padding(14)
            .background(Color(NSColor.windowBackgroundColor))
            .cornerRadius(10)
        }
    }
    
    private func singleDisplayDetailSection(display: DisplayInfo) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header Info Card
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(display.name)
                            .font(.title2.bold())
                        if !display.badge.isEmpty {
                            Text(display.badge)
                                .font(.caption.bold())
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(4)
                        }
                    }
                    Text("Display ID: \(display.id) • \(display.currentResolution) @ \(Int(display.currentRefreshRate))Hz")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                
                Toggle("Power / Connected", isOn: Binding(
                    get: { display.isPoweredOn },
                    set: { displayManager.setPower(for: display, powerOn: $0) }
                ))
                .toggleStyle(SwitchToggleStyle(tint: .blue))
            }
            .padding(14)
            .background(Color(NSColor.windowBackgroundColor))
            .cornerRadius(10)
            
            // Adjustments
            VStack(alignment: .leading, spacing: 12) {
                Text("Display Controls")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Combined Brightness")
                            .font(.caption.bold())
                        Spacer()
                        Text("\(Int(round(display.combinedBrightness * 100)))%")
                            .font(.caption.monospaced())
                    }
                    Slider(
                        value: Binding(
                            get: { display.combinedBrightness },
                            set: { displayManager.setCombinedBrightness(for: display, value: $0) }
                        ),
                        in: 0...1
                    )
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Volume")
                            .font(.caption.bold())
                        Spacer()
                        Text("\(Int(round(display.volume * 100)))%")
                            .font(.caption.monospaced())
                    }
                    Slider(
                        value: Binding(
                            get: { display.volume },
                            set: { displayManager.setVolume(for: display, value: $0) }
                        ),
                        in: 0...1
                    )
                }
            }
            .padding(14)
            .background(Color(NSColor.windowBackgroundColor))
            .cornerRadius(10)
            
            // Resolution modes
            VStack(alignment: .leading, spacing: 8) {
                Text("Available Display Modes")
                    .font(.headline)
                
                ForEach(display.availableModes.prefix(6)) { mode in
                    HStack {
                        Text(mode.descriptionString)
                            .font(.system(size: 12, design: .monospaced))
                        Spacer()
                        if mode.isActive {
                            Text("Active")
                                .font(.caption.bold())
                                .foregroundColor(.blue)
                        } else {
                            Button("Apply") {
                                displayManager.setDisplayMode(for: display, mode: mode)
                            }
                            .font(.caption)
                        }
                    }
                    .padding(.vertical, 3)
                    Divider()
                }
            }
            .padding(14)
            .background(Color(NSColor.windowBackgroundColor))
            .cornerRadius(10)
        }
    }
    
    // MARK: - Keyboard & Shortcuts Tab
    private var keyboardTabView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Keyboard Shortcuts & Hotkeys")
                    .font(.title2.bold())
                Text("Set up custom global shortcuts to toggle power, switch resolutions, adjust brightness/volume, and control displays from anywhere.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Configured Shortcuts")
                        .font(.headline)
                    
                    ForEach($hotkeyManager.shortcuts) { $sc in
                        HStack {
                            Toggle("", isOn: $sc.isEnabled)
                                .labelsHidden()
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(sc.title)
                                    .font(.system(size: 13, weight: .medium))
                                Text("Action: \(sc.actionType)")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Text(sc.shortcutDisplayString)
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.15))
                                .cornerRadius(6)
                                .foregroundColor(.blue)
                        }
                        .padding(.vertical, 4)
                        Divider()
                    }
                }
                .padding(14)
                .background(Color(NSColor.windowBackgroundColor))
                .cornerRadius(10)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Media Keys & On-Screen Display (OSD)")
                        .font(.headline)
                    Toggle("Use Apple Keyboard Media Keys (F1/F2 Brightness, F10-F12 Volume)", isOn: .constant(true))
                    Toggle("Show Floating OSD Bezel on Keypress", isOn: .constant(true))
                }
                .padding(14)
                .background(Color(NSColor.windowBackgroundColor))
                .cornerRadius(10)
            }
            .padding(20)
        }
    }
    
    // MARK: - Presets Tab
    private var presetsTabView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Display Presets")
                    .font(.title2.bold())
                Text("Switch entire multi-monitor configurations in a single click or with a hotkey.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(presetManager.presets) { p in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: p.icon)
                                    .font(.title2)
                                    .foregroundColor(.blue)
                                Text(p.name)
                                    .font(.headline)
                                Spacer()
                            }
                            
                            Text("Brightness: \(Int(p.brightness * 100))% • Volume: \(Int(p.volume * 100))%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Button("Apply Preset") {
                                presetManager.applyPreset(p)
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                        }
                        .padding(14)
                        .background(Color(NSColor.windowBackgroundColor))
                        .cornerRadius(10)
                    }
                }
            }
            .padding(20)
        }
    }
    
    // MARK: - Groups Tab
    private var groupsTabView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Display Groups")
                    .font(.title2.bold())
                Text("Synchronize brightness, volume, and power adjustments across multiple monitors simultaneously.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                ForEach($groupManager.groups) { $group in
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text(group.name).font(.headline)
                            Spacer()
                        }
                        Toggle("Sync Brightness across group", isOn: $group.syncBrightness)
                        Toggle("Sync Volume across group", isOn: $group.syncVolume)
                        Toggle("Sync Power on/off across group", isOn: $group.syncPower)
                    }
                    .padding(14)
                    .background(Color(NSColor.windowBackgroundColor))
                    .cornerRadius(10)
                }
                
                Button("Add New Group") {
                    groupManager.addGroup(name: "Group \(groupManager.groups.count + 1)")
                }
            }
            .padding(20)
        }
    }
    
    // MARK: - Application Tab
    private var applicationTabView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Application Settings")
                    .font(.title2.bold())
                
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Launch Manage Your Display at Login (Startup)", isOn: $launchAtLogin.isEnabled)
                    Toggle("Check for Updates Automatically", isOn: .constant(true))
                    Toggle("Show Icon in Menu Bar", isOn: .constant(true))
                }
                .padding(14)
                .background(Color(NSColor.windowBackgroundColor))
                .cornerRadius(10)
            }
            .padding(20)
        }
    }
    
    // MARK: - Menu Tab
    private var menuTabView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Menu & Popover Customization")
                    .font(.title2.bold())
                
                VStack(alignment: .leading, spacing: 10) {
                    Toggle("Show Brightness Slider", isOn: .constant(true))
                    Toggle("Show Volume Slider", isOn: .constant(true))
                    Toggle("Show Resolution Slider", isOn: .constant(true))
                    Toggle("Enable Frosted Glass Vibrancy", isOn: .constant(true))
                }
                .padding(14)
                .background(Color(NSColor.windowBackgroundColor))
                .cornerRadius(10)
            }
            .padding(20)
        }
    }
    
    // MARK: - Pro Tab
    private var proTabView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.title)
                        .foregroundColor(.blue)
                    Text("Manage Your Display Pro — 100% Unlocked & Open Source")
                        .font(.title2.bold())
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("✨ All Pro Features Fully Included:")
                        .font(.headline)
                    Text("• Hardware DDC/CI Control for Apple Silicon & Intel")
                    Text("• Disconnect & Connect Displays (Soft-sleep & layout management)")
                    Text("• Full Built-in MacBook Display Clamshell & Backlight Control")
                    Text("• Virtual Screens (BetterDummy) with custom scaling up to 16K")
                    Text("• Picture-in-Picture (PiP) Live Streaming Window")
                    Text("• Digital KVM Input Source Switching (HDMI/DP/USB-C)")
                    Text("• Global Customizable Hotkeys & Floating OSD HUD")
                    Text("• Presets Manager & Display Groups Sync")
                    Text("• Cross-Platform Linux Display Hardware Support")
                }
                .padding(14)
                .background(Color(NSColor.windowBackgroundColor))
                .cornerRadius(10)
            }
            .padding(20)
        }
    }
    
    // MARK: - About Tab
    private var aboutTabView: some View {
        ScrollView {
            VStack(spacing: 16) {
                Image(systemName: "display.2")
                    .font(.system(size: 56))
                    .foregroundColor(.blue)
                
                Text("Manage Your Display")
                    .font(.title.bold())
                
                Text("The Ultimate Open-Source Display & Hardware Controller")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Architecture: Apple Silicon (ARM64) & Linux")
                    Text("OS: macOS Darwin 27.0")
                    Text("Connected Displays: \(displayManager.displays.count)")
                    Text("License: MIT Open Source")
                }
                .font(.system(size: 12, design: .monospaced))
                .padding(14)
                .background(Color(NSColor.windowBackgroundColor))
                .cornerRadius(10)
            }
            .padding(20)
        }
    }
}
