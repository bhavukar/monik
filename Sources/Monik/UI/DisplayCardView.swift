//
//  DisplayCardView.swift
//  Manage Your Display
//

import SwiftUI
import CoreGraphics
import AppKit

struct DisplayCardView: View {
    @ObservedObject var display: DisplayInfo
    @ObservedObject var displayManager = DisplayManager.shared
    
    var body: some View {
        VStack(spacing: 12) {
            // Header Row: Icon, Name, Badges, and Power Toggle
            HStack(spacing: 8) {
                Image(systemName: display.isBuiltIn ? "laptopcomputer" : "display")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(display.isPoweredOn ? .primary : .secondary)
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(display.name)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(display.isPoweredOn ? .primary : .secondary)
                            .lineLimit(1)
                        
                        if display.isMain {
                            Text("Main")
                                .font(.system(size: 9, weight: .semibold))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1.5)
                                .background(Color.blue.opacity(0.15))
                                .foregroundColor(.blue)
                                .cornerRadius(4)
                        }
                    }
                    
                    HStack(spacing: 4) {
                        Circle()
                            .fill(display.isPoweredOn ? Color.green : Color.secondary)
                            .frame(width: 6, height: 6)
                        Text(display.isPoweredOn ? "Active" : "Off")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(display.isPoweredOn ? .primary : .secondary)
                        
                        if !display.currentResolution.isEmpty {
                            Text("• \(display.currentResolution) @ \(Int(round(display.currentRefreshRate)))Hz")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                // Hardware / Software Power Toggle
                Toggle("", isOn: Binding(
                    get: { display.isPoweredOn },
                    set: { displayManager.setPower(for: display, powerOn: $0) }
                ))
                .labelsHidden()
                .toggleStyle(SwitchToggleStyle())
                .scaleEffect(0.8)
                .help(display.isPoweredOn ? "Turn off display" : "Turn on display")
            }
            .padding(.bottom, 2)
            
            if display.isPoweredOn {
                VStack(spacing: 10) {
                    // Brightness Slider (0–100%)
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Image(systemName: "sun.max.fill")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                            Text("Brightness")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.primary)
                            Spacer()
                            Text("\(Int(round(display.combinedBrightness * 100)))%")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                        
                        Slider(
                            value: Binding(
                                get: { display.combinedBrightness },
                                set: { displayManager.setCombinedBrightness(for: display, value: $0) }
                            ),
                            in: 0.0...1.0
                        )
                        .tint(.blue)
                    }
                    
                    // Contrast Slider (0–100%)
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Image(systemName: "circle.lefthalf.filled")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                            Text("Contrast")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.primary)
                            Spacer()
                            Text("\(Int(round(display.contrast * 100)))%")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                        
                        Slider(
                            value: Binding(
                                get: { display.contrast },
                                set: { displayManager.setContrast(for: display, value: $0) }
                            ),
                            in: 0.0...1.0
                        )
                        .tint(.blue)
                    }
                    
                    // Volume Slider (only if external or supported)
                    if !display.isBuiltIn {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Image(systemName: display.volume > 0 ? "speaker.wave.2.fill" : "speaker.slash.fill")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                                Text("Volume")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.primary)
                                Spacer()
                                Text("\(Int(round(display.volume * 100)))%")
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                            
                            Slider(
                                value: Binding(
                                    get: { display.volume },
                                    set: { displayManager.setVolume(for: display, value: $0) }
                                ),
                                in: 0.0...1.0
                            )
                            .tint(.blue)
                        }
                    }
                    
                    Divider()
                        .padding(.vertical, 2)
                    
                    // Resolution & Refresh Rate Pickers
                    HStack(spacing: 8) {
                        // Resolution Menu
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Resolution")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.secondary)
                            
                            Menu {
                                if display.availableModes.isEmpty {
                                    Text("No modes available")
                                } else {
                                    let uniqueModes = uniqueResolutionModes(for: display.availableModes)
                                    ForEach(uniqueModes) { mode in
                                        Button(action: {
                                            displayManager.setDisplayMode(for: display, mode: mode)
                                        }) {
                                            HStack {
                                                if mode.isActive {
                                                    Image(systemName: "checkmark")
                                                }
                                                Text(mode.descriptionString)
                                            }
                                        }
                                    }
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Text(display.currentResolution)
                                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                        .lineLimit(1)
                                    if display.isHiDPI {
                                        Text("HiDPI")
                                            .font(.system(size: 8, weight: .bold))
                                            .padding(.horizontal, 3)
                                            .padding(.vertical, 1)
                                            .background(Color.blue.opacity(0.2))
                                            .foregroundColor(.blue)
                                            .cornerRadius(3)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.up.chevron.down")
                                        .font(.system(size: 9))
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                                .background(Color(NSColor.controlBackgroundColor))
                                .cornerRadius(6)
                            }
                            .menuStyle(BorderlessButtonMenuStyle())
                        }
                        
                        // Refresh Rate Menu
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Refresh Rate")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.secondary)
                            
                            Menu {
                                ForEach(display.availableRefreshRates, id: \.self) { rate in
                                    Button(action: {
                                        displayManager.setRefreshRate(for: display, targetRate: rate)
                                    }) {
                                        HStack {
                                            if abs(display.currentRefreshRate - rate) < 1.0 {
                                                Image(systemName: "checkmark")
                                            }
                                            Text("\(Int(round(rate))) Hz")
                                        }
                                    }
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Text("\(Int(round(display.currentRefreshRate))) Hz")
                                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                    Spacer()
                                    Image(systemName: "chevron.up.chevron.down")
                                        .font(.system(size: 9))
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                                .background(Color(NSColor.controlBackgroundColor))
                                .cornerRadius(6)
                            }
                            .menuStyle(BorderlessButtonMenuStyle())
                            .frame(width: 95)
                        }
                    }
                    
                    // Rotation Selector
                    HStack(spacing: 6) {
                        Text("Rotation")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary)
                        Spacer()
                        
                        ForEach([0, 90, 180, 270], id: \.self) { deg in
                            Button(action: {
                                displayManager.setRotation(for: display, degrees: deg)
                            }) {
                                Text("\(deg)°")
                                    .font(.system(size: 10, weight: display.rotation == deg ? .bold : .regular))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(display.rotation == deg ? Color.blue : Color(NSColor.controlBackgroundColor))
                                    .foregroundColor(display.rotation == deg ? .white : .primary)
                                    .cornerRadius(4)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                    // Quick Action Buttons
                    if !display.isMain {
                        HStack {
                            Button(action: {
                                displayManager.setAsMainDisplay(for: display)
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "star")
                                        .font(.system(size: 10))
                                    Text("Set as Main Display")
                                        .font(.system(size: 10, weight: .medium))
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(NSColor.controlBackgroundColor))
                                .cornerRadius(5)
                            }
                            .buttonStyle(.plain)
                            
                            Spacer()
                        }
                        .padding(.top, 2)
                    }
                }
            }
        }
        .padding(12)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.6))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(NSColor.separatorColor), lineWidth: 0.5)
        )
    }
    
    private func uniqueResolutionModes(for modes: [DisplayModeItem]) -> [DisplayModeItem] {
        var seen = Set<String>()
        var result: [DisplayModeItem] = []
        for m in modes {
            let key = "\(m.width)x\(m.height)-\(m.isHiDPI)"
            if !seen.contains(key) {
                seen.insert(key)
                result.append(m)
            }
        }
        return result
    }
}
