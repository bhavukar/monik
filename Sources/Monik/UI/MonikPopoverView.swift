//
//  MonikPopoverView.swift
//  Manage Your Display
//

import SwiftUI
import AppKit

public struct MonikPopoverView: View {
    @ObservedObject var displayManager = DisplayManager.shared
    @ObservedObject var presetManager = PresetManager.shared
    
    public init() {}
    
    public var body: some View {
        ZStack {
            VisualEffectBackground(material: .popover, blendingMode: .behindWindow)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 12) {
                        // Quick Optimization Action Bar for External Monitors
                        HStack(spacing: 6) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 11))
                                .foregroundColor(.yellow)
                            VStack(alignment: .leading, spacing: 1) {
                                Text("Crisp Text & Native HiDPI")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(.white)
                                Text("Font smoothing & high refresh")
                                    .font(.system(size: 8))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            Spacer()
                            Button(action: {
                                displayManager.restoreAllDisplays()
                            }) {
                                HStack(spacing: 3) {
                                    Image(systemName: "wand.and.stars")
                                        .font(.system(size: 9))
                                    Text("Fix Displays")
                                        .font(.system(size: 10, weight: .bold))
                                }
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(Color.blue)
                                .cornerRadius(5)
                                .foregroundColor(.white)
                            }
                            .buttonStyle(.plain)
                            .help("Restore crisp text antialiasing and optimal HiDPI modes on all external monitors")
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(7)
                        .padding(.horizontal, 10)
                        
                        // Presets Quick Bar
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(presetManager.presets) { p in
                                    Button(action: {
                                        presetManager.applyPreset(p)
                                    }) {
                                        HStack(spacing: 4) {
                                            Image(systemName: p.icon)
                                                .font(.system(size: 10))
                                            Text(p.name)
                                                .font(.system(size: 10, weight: .medium))
                                        }
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.white.opacity(0.1))
                                        .cornerRadius(6)
                                        .foregroundColor(.white.opacity(0.9))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 10)
                        }
                        .padding(.top, 4)
                        
                        // Display Cards
                        ForEach(displayManager.displays) { display in
                            DisplayCardView(display: display)
                        }
                        
                        // Tools Section
                        ToolsSectionView()
                    }
                    .padding(.vertical, 10)
                }
                .frame(maxHeight: 650)
                
                // Bottom Bar
                Divider()
                    .background(Color.white.opacity(0.15))
                
                HStack(spacing: 8) {
                    // Pro Status Badge
                    HStack(spacing: 5) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.white)
                        Text("Manage Your Display Pro")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
                    
                    Spacer()
                    
                    // Fix Font Smoothing
                    Button(action: {
                        displayManager.enableMacFontSmoothing()
                    }) {
                        Image(systemName: "textformat.size")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.85))
                    }
                    .buttonStyle(.plain)
                    .help("Fix Blurry Text (Font Smoothing)")
                    
                    // Settings Gear Button
                    Button(action: {
                        PreferencesWindowController.shared.show()
                    }) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.85))
                    }
                    .buttonStyle(.plain)
                    .help("Settings")
                    
                    // Prominent Quit Button
                    Button(action: {
                        NSApplication.shared.terminate(nil)
                    }) {
                        HStack(spacing: 3) {
                            Image(systemName: "power")
                                .font(.system(size: 10, weight: .bold))
                            Text("Quit")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 4)
                        .background(Color.red.opacity(0.85))
                        .cornerRadius(5)
                    }
                    .buttonStyle(.plain)
                    .help("Quit Manage Your Display (Cmd+Q)")
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(Color.black.opacity(0.3))
            }
        }
        .frame(width: 350)
        .preferredColorScheme(.dark)
    }
}

// NSVisualEffectView Wrapper for SwiftUI
struct VisualEffectBackground: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        view.appearance = NSAppearance(named: .vibrantDark)
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}
