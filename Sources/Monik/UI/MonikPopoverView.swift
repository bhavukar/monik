//
//  MonikPopoverView.swift
//  Manage Your Display
//

import SwiftUI
import AppKit

public struct MonikPopoverView: View {
    @ObservedObject var displayManager = DisplayManager.shared
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            HStack(spacing: 8) {
                Image(systemName: "display.2")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 1) {
                    Text("Manage Your Display")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.primary)
                    Text("\(displayManager.displays.count) Displays Connected")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Action icons
                HStack(spacing: 4) {
                    Button(action: {
                        displayManager.refreshDisplays()
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 11))
                            .frame(width: 26, height: 26)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                    .help("Rescan Displays")
                    
                    Button(action: {
                        displayManager.enableMacFontSmoothing()
                    }) {
                        Image(systemName: "textformat.size")
                            .font(.system(size: 11))
                            .frame(width: 26, height: 26)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                    .help("Fix Blurry Text (Enable macOS Subpixel Font Smoothing)")
                    
                    Button(action: {
                        PreferencesWindowController.shared.show()
                    }) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 11))
                            .frame(width: 26, height: 26)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                    .help("Settings")
                    
                    Button(action: {
                        NSApplication.shared.terminate(nil)
                    }) {
                        Image(systemName: "power")
                            .font(.system(size: 11))
                            .foregroundColor(.red)
                            .frame(width: 26, height: 26)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                    .help("Quit Manage Your Display (⌘Q)")
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // Scrollable List of Display Cards
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 12) {
                    if displayManager.displays.isEmpty {
                        VStack(spacing: 10) {
                            Image(systemName: "display.trianglebadge.exclamationmark")
                                .font(.system(size: 32))
                                .foregroundColor(.secondary)
                            Text("No Displays Detected")
                                .font(.system(size: 13, weight: .semibold))
                            Text("Check your monitor cables and connections.")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                            Button("Scan Again") {
                                displayManager.refreshDisplays()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding(.vertical, 40)
                    } else {
                        ForEach(displayManager.displays) { display in
                            DisplayCardView(display: display)
                        }
                    }
                }
                .padding(12)
            }
            .frame(maxHeight: 560)
            
            Divider()
            
            // Bottom Bar
            HStack(spacing: 8) {
                Button(action: {
                    if let url = URL(string: "x-apple.systempreferences:com.apple.Displays-Settings.extension") {
                        NSWorkspace.shared.open(url)
                    } else {
                        NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/System Settings.app"))
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "display")
                            .font(.system(size: 10))
                        Text("macOS Displays...")
                            .font(.system(size: 11))
                    }
                    .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Button(action: {
                    displayManager.restoreAllDisplays()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 10))
                        Text("Reset All")
                            .font(.system(size: 11))
                    }
                    .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Reset brightness, gamma, and restore crisp modes")
                
                Divider()
                    .frame(height: 12)
                
                Button(action: {
                    NSApplication.shared.terminate(nil)
                }) {
                    HStack(spacing: 3) {
                        Text("Quit")
                            .font(.system(size: 11, weight: .medium))
                        Text("⌘Q")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    .foregroundColor(.red.opacity(0.85))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(width: 360)
    }
}
