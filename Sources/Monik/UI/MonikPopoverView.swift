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
                
                HStack(spacing: 10) {
                    // Pro Status Badge
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.white)
                        Text("Manage Your Display Pro")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
                    
                    Spacer()
                    
                    // Settings Gear Button
                    Button(action: {
                        PreferencesWindowController.shared.show()
                    }) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                    .help("Settings")
                    
                    // More (...) Button
                    Button(action: {
                        PreferencesWindowController.shared.show()
                    }) {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                    .help("More")
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.black.opacity(0.25))
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
