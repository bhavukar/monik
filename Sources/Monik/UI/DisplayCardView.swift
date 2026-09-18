//
//  DisplayCardView.swift
//  Monik
//

import SwiftUI
import CoreGraphics

struct DisplayCardView: View {
    @ObservedObject var display: DisplayInfo
    @ObservedObject var displayManager = DisplayManager.shared
    
    var body: some View {
        VStack(spacing: 8) {
            // Card Header
            HStack(spacing: 8) {
                Image(systemName: display.isBuiltIn ? "laptopcomputer" : "display")
                    .font(.system(size: 14))
                    .foregroundColor(display.isPoweredOn ? .white : .white.opacity(0.4))
                
                Text(display.name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(display.isPoweredOn ? .white : .white.opacity(0.6))
                    .lineLimit(1)
                
                if !display.badge.isEmpty {
                    Text(display.badge)
                        .font(.system(size: 9, weight: .bold))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Capsule())
                        .foregroundColor(.white.opacity(0.9))
                }
                
                if !display.isPoweredOn {
                    Text("Off")
                        .font(.system(size: 9, weight: .bold))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color.red.opacity(0.3))
                        .clipShape(Capsule())
                        .foregroundColor(.red.opacity(0.9))
                }
                
                Spacer()
                
                // Header action icons
                HStack(spacing: 6) {
                    Button(action: {
                        displayManager.setAsMainDisplay(for: display)
                    }) {
                        Image(systemName: "square.dashed")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                    .help("Set as Main Display")
                    
                    Button(action: {
                        PictureInPictureService.shared.togglePiP(for: display.id)
                    }) {
                        Image(systemName: "pip")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                    .help("Picture in Picture")
                }
                
                Toggle("", isOn: Binding(
                    get: { display.isPoweredOn },
                    set: { displayManager.setPower(for: display, powerOn: $0) }
                ))
                .labelsHidden()
                .toggleStyle(SwitchToggleStyle(tint: .blue))
                .scaleEffect(0.75)
            }
            .padding(.horizontal, 10)
            .padding(.top, 10)
            
            // Brightness (Combined)
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text("Brightness (Combined)")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.8))
                    Spacer()
                    Text("\(Int(round(display.combinedBrightness * 100)))%")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.white.opacity(0.9))
                }
                HStack(spacing: 8) {
                    Image(systemName: "sun.max.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Slider(
                        value: Binding(
                            get: { display.combinedBrightness },
                            set: { displayManager.setCombinedBrightness(for: display, value: $0) }
                        ),
                        in: 0.0...1.0
                    )
                    .tint(.white)
                    .disabled(!display.isPoweredOn)
                }
            }
            .padding(.horizontal, 10)
            .opacity(display.isPoweredOn ? 1.0 : 0.4)
            
            // Volume
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text("Volume")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.8))
                    Spacer()
                    Text("\(Int(round(display.volume * 100)))%")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.white.opacity(0.9))
                }
                HStack(spacing: 8) {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Slider(
                        value: Binding(
                            get: { display.volume },
                            set: { displayManager.setVolume(for: display, value: $0) }
                        ),
                        in: 0.0...1.0
                    )
                    .tint(.white)
                    .disabled(!display.isPoweredOn)
                }
            }
            .padding(.horizontal, 10)
            .opacity(display.isPoweredOn ? 1.0 : 0.4)
            
            // Resolution
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text("Resolution")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.8))
                    Spacer()
                    Text(display.currentResolution)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.white.opacity(0.9))
                }
                HStack(spacing: 8) {
                    Image(systemName: "aspectratio")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.8))
                    
                    // Quick slider between top available resolutions
                    Slider(
                        value: Binding(
                            get: {
                                if let idx = display.availableModes.firstIndex(where: { $0.isActive }) {
                                    return Double(idx)
                                }
                                return 0.0
                            },
                            set: { newIdx in
                                let intIdx = Int(round(newIdx))
                                if intIdx >= 0 && intIdx < display.availableModes.count {
                                    displayManager.setDisplayMode(for: display, mode: display.availableModes[intIdx])
                                }
                            }
                        ),
                        in: 0.0...Double(max(1, display.availableModes.count - 1)),
                        step: 1.0
                    )
                    .tint(.white)
                    .disabled(!display.isPoweredOn)
                }
            }
            .padding(.horizontal, 10)
            .opacity(display.isPoweredOn ? 1.0 : 0.4)
            
            // Expandable Chevron
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    display.isExpanded.toggle()
                }
            }) {
                Image(systemName: display.isExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 3)
            }
            .buttonStyle(.plain)
            
            // Expanded Settings Menu
            if display.isExpanded {
                VStack(spacing: 1) {
                    submenuRow(
                        icon: "rectangle.3.group",
                        title: "Display Mode",
                        submenuKey: "displayMode"
                    ) {
                        displayModesSubmenu
                    }
                    
                    submenuRow(
                        icon: "speedometer",
                        title: "Refresh Rate",
                        submenuKey: "refreshRate"
                    ) {
                        refreshRateSubmenu
                    }
                    
                    submenuRow(
                        icon: "circle.lefthalf.filled",
                        title: "Colour Mode",
                        submenuKey: "colorMode"
                    ) {
                        colorModeSubmenu
                    }
                    
                    submenuRow(
                        icon: "rectangle.on.rectangle",
                        title: "Mirror Display",
                        submenuKey: "mirror"
                    ) {
                        mirrorSubmenu
                    }
                    
                    actionRow(icon: "video", title: "Stream Display") {
                        PictureInPictureService.shared.openPiP(for: display.id)
                    }
                    
                    actionRow(icon: "pip", title: "Picture in Picture") {
                        PictureInPictureService.shared.openPiP(for: display.id)
                    }
                    
                    submenuRow(
                        icon: "arrow.up.and.down.and.arrow.left.and.right",
                        title: "Move Display",
                        submenuKey: "moveDisplay"
                    ) {
                        moveDisplaySubmenu
                    }
                    
                    submenuRow(
                        icon: "rotate.right",
                        title: "Screen Rotation",
                        submenuKey: "rotation"
                    ) {
                        rotationSubmenu
                    }
                    
                    submenuRow(
                        icon: "slider.horizontal.3",
                        title: "Image Adjustments",
                        submenuKey: "imageAdjustments"
                    ) {
                        imageAdjustmentsSubmenu
                    }
                    
                    submenuRow(
                        icon: "power",
                        title: "Device Control",
                        submenuKey: "deviceControl"
                    ) {
                        deviceControlSubmenu
                    }
                    
                    submenuRow(
                        icon: "cable.connector",
                        title: "Input Source",
                        submenuKey: "inputSource"
                    ) {
                        inputSourceSubmenu
                    }
                    
                    submenuRow(
                        icon: "paintpalette",
                        title: "Colour Profile",
                        submenuKey: "colorProfile"
                    ) {
                        colorProfileSubmenu
                    }
                    
                    actionRow(icon: "lock.shield", title: "Configuration Protection") {
                        // Protect configuration
                    }
                    
                    actionRow(icon: "gearshape.2", title: "Manage Display") {
                        PreferencesWindowController.shared.show()
                    }
                    
                    // High Resolution (HiDPI) Toggle
                    HStack {
                        Image(systemName: "sparkles")
                            .font(.system(size: 11))
                            .frame(width: 18)
                            .foregroundColor(.white.opacity(0.8))
                        Text("High Resolution (HiDPI)")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.9))
                        Spacer()
                        if display.isHiDPI {
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if let hidpiMode = display.availableModes.first(where: { $0.isHiDPI && !$0.isActive }) {
                            displayManager.setDisplayMode(for: display, mode: hidpiMode)
                        }
                    }
                    
                    // Set as Main Display Button
                    HStack {
                        Image(systemName: "m.circle")
                            .font(.system(size: 12))
                            .frame(width: 18)
                            .foregroundColor(.white.opacity(0.8))
                        Text("Set as Main Display")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.9))
                        Spacer()
                        if display.isMain {
                            Text("Current")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        displayManager.setAsMainDisplay(for: display)
                    }
                }
                .padding(.bottom, 6)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
        )
        .padding(.horizontal, 10)
    }
    
    // Submenu Row Component
    private func submenuRow<Content: View>(
        icon: String,
        title: String,
        submenuKey: String,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        VStack(spacing: 0) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.15)) {
                    if display.expandedSubmenu == submenuKey {
                        display.expandedSubmenu = nil
                    } else {
                        display.expandedSubmenu = submenuKey
                    }
                }
            }) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 11))
                        .frame(width: 18)
                        .foregroundColor(.white.opacity(0.8))
                    Text(title)
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.9))
                    Spacer()
                    Image(systemName: display.expandedSubmenu == submenuKey ? "chevron.down" : "chevron.right")
                        .font(.system(size: 9))
                        .foregroundColor(.white.opacity(0.5))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(display.expandedSubmenu == submenuKey ? Color.white.opacity(0.06) : Color.clear)
            }
            .buttonStyle(.plain)
            
            if display.expandedSubmenu == submenuKey {
                VStack(spacing: 2) {
                    content()
                }
                .padding(.leading, 28)
                .padding(.trailing, 10)
                .padding(.vertical, 4)
                .background(Color.black.opacity(0.2))
            }
        }
    }
    
    // Action Row Component
    private func actionRow(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 11))
                    .frame(width: 18)
                    .foregroundColor(.white.opacity(0.8))
                Text(title)
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.9))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 9))
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
        }
        .buttonStyle(.plain)
    }
    
    // Display Modes Submenu
    private var displayModesSubmenu: some View {
        ForEach(display.availableModes.prefix(8), id: \.id) { mode in
            HStack {
                Text(mode.descriptionString)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.white.opacity(0.85))
                Spacer()
                if mode.isActive {
                    Image(systemName: "checkmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.blue)
                }
            }
            .padding(.vertical, 3)
            .contentShape(Rectangle())
            .onTapGesture {
                displayManager.setDisplayMode(for: display, mode: mode)
            }
        }
    }
    
    // Refresh Rate Submenu
    private var refreshRateSubmenu: some View {
        ForEach([60.0, 75.0, 120.0, 144.0], id: \.self) { rate in
            HStack {
                Text("\(Int(rate)) Hz")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.85))
                Spacer()
                if Int(display.currentRefreshRate) == Int(rate) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.blue)
                }
            }
            .padding(.vertical, 3)
            .contentShape(Rectangle())
            .onTapGesture {
                if let matchingMode = display.availableModes.first(where: { Int($0.refreshRate) == Int(rate) }) {
                    displayManager.setDisplayMode(for: display, mode: matchingMode)
                }
            }
        }
    }
    
    // Color Mode Submenu
    private var colorModeSubmenu: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(["RGB (Standard)", "YPbPr (Component)", "HDR Mode"], id: \.self) { cm in
                HStack {
                    Text(cm)
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.85))
                    Spacer()
                    if cm.starts(with: "RGB") {
                        Image(systemName: "checkmark")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.blue)
                    }
                }
                .padding(.vertical, 3)
            }
        }
    }
    
    // Mirror Submenu
    private var mirrorSubmenu: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Mirror Off")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.85))
                Spacer()
                if !display.isMirrored {
                    Image(systemName: "checkmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.blue)
                }
            }
            .padding(.vertical, 3)
            .contentShape(Rectangle())
            .onTapGesture {
                _ = DisplayModesService.shared.setMirroring(displayID: display.id, mirrorTarget: nil)
            }
            
            ForEach(displayManager.displays.filter { $0.id != display.id }) { otherDisplay in
                HStack {
                    Text("Mirror with \(otherDisplay.name)")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.85))
                    Spacer()
                    if display.isMirrored {
                        Image(systemName: "checkmark")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.blue)
                    }
                }
                .padding(.vertical, 3)
                .contentShape(Rectangle())
                .onTapGesture {
                    _ = DisplayModesService.shared.setMirroring(displayID: display.id, mirrorTarget: otherDisplay.id)
                }
            }
        }
    }
    
    // Rotation Submenu
    private var rotationSubmenu: some View {
        ForEach([0, 90, 180, 270], id: \.self) { deg in
            HStack {
                Text(deg == 0 ? "Standard (0°)" : "\(deg)°")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.85))
                Spacer()
                if display.rotation == deg {
                    Image(systemName: "checkmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.blue)
                }
            }
            .padding(.vertical, 3)
            .contentShape(Rectangle())
            .onTapGesture {
                displayManager.setRotation(for: display, degrees: deg)
            }
        }
    }
    
    // Move Display Submenu
    private var moveDisplaySubmenu: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(["Move Left", "Move Right", "Move Above", "Move Below"], id: \.self) { dir in
                HStack {
                    Text(dir)
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.85))
                    Spacer()
                }
                .padding(.vertical, 3)
                .contentShape(Rectangle())
                .onTapGesture {
                    // Quick arrangement adjustment
                }
            }
        }
    }
    
    // Image Adjustments Submenu
    private var imageAdjustmentsSubmenu: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Contrast")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.7))
                Spacer()
                Text("\(Int(round(display.contrast * 100)))%")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.white.opacity(0.8))
            }
            Slider(
                value: Binding(
                    get: { display.contrast },
                    set: {
                        display.contrast = $0
                        _ = DDCService.shared.setContrast(displayID: display.id, value: Int(round($0 * 100)))
                    }
                ),
                in: 0.0...1.0
            )
            .tint(.white)
            
            HStack {
                Text("Software Dimming Override")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.7))
                Spacer()
            }
            Slider(value: $display.combinedBrightness, in: 0.0...1.0)
                .tint(.white)
        }
    }
    
    // Device Control Submenu
    private var deviceControlSubmenu: some View {
        VStack(alignment: .leading, spacing: 4) {
            Button(action: {
                displayManager.setPower(for: display, powerOn: false)
            }) {
                HStack {
                    Text("Power Off Monitor (DDC)")
                        .font(.system(size: 11))
                        .foregroundColor(.red.opacity(0.9))
                    Spacer()
                }
                .padding(.vertical, 3)
            }
            .buttonStyle(.plain)
            
            Button(action: {
                _ = DDCService.shared.setMute(displayID: display.id, isMuted: true)
            }) {
                HStack {
                    Text("Mute Audio (DDC)")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.85))
                    Spacer()
                }
                .padding(.vertical, 3)
            }
            .buttonStyle(.plain)
        }
    }
    
    // Input Source Submenu
    private var inputSourceSubmenu: some View {
        let inputs: [(name: String, code: UInt16)] = [
            ("HDMI 1", 0x11),
            ("HDMI 2", 0x12),
            ("DisplayPort 1", 0x0F),
            ("DisplayPort 2", 0x10),
            ("USB-C", 0x1B)
        ]
        return VStack(alignment: .leading, spacing: 4) {
            ForEach(inputs, id: \.name) { item in
                HStack {
                    Text(item.name)
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.85))
                    Spacer()
                    if display.currentInputSource == item.name {
                        Image(systemName: "checkmark")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.blue)
                    }
                }
                .padding(.vertical, 3)
                .contentShape(Rectangle())
                .onTapGesture {
                    displayManager.setInputSource(for: display, code: item.code, name: item.name)
                }
            }
        }
    }
    
    // Color Profile Submenu
    private var colorProfileSubmenu: some View {
        let profiles = ["Display P3", "sRGB IEC61966-2.1", "Adobe RGB (1998)", "Color LCD", "Generic RGB"]
        return VStack(alignment: .leading, spacing: 4) {
            ForEach(profiles, id: \.self) { profile in
                HStack {
                    Text(profile)
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.85))
                    Spacer()
                    if profile == "sRGB IEC61966-2.1" {
                        Image(systemName: "checkmark")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.blue)
                    }
                }
                .padding(.vertical, 3)
                .contentShape(Rectangle())
                .onTapGesture {
                    display.currentColorProfile = profile
                }
            }
        }
    }
}
