//
//  ToolsSectionView.swift
//  Monik
//

import SwiftUI
import AppKit

struct ToolsSectionView: View {
    @ObservedObject var virtualManager = VirtualDisplayManager.shared
    @State private var expandedTool: String? = nil
    
    var body: some View {
        VStack(spacing: 1) {
            // Header Pill
            HStack(spacing: 6) {
                Image(systemName: "ellipsis.circle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.7))
                Text("Tools")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.06))
            .cornerRadius(8)
            
            // Displays and Virtual Screens
            toolSubmenuRow(
                icon: "rectangle.inset.filled.and.person.filled",
                title: "Displays And Virtual Screens",
                key: "virtualScreens"
            ) {
                virtualScreensSubmenu
            }
            
            // Video Filter Window
            toolSubmenuRow(
                icon: "rectangle.dashed.badge.record",
                title: "Video Filter Window",
                key: "videoFilter"
            ) {
                videoFilterSubmenu
            }
            
            // System Colours
            toolSubmenuRow(
                icon: "circle.lefthalf.striped.horizontal",
                title: "System Colours",
                key: "systemColours"
            ) {
                systemColoursSubmenu
            }
            
            // Check for Updates
            Button(action: {
                // Check for updates
            }) {
                HStack {
                    Image(systemName: "arrow.down.circle")
                        .font(.system(size: 11))
                        .frame(width: 18)
                        .foregroundColor(.white.opacity(0.8))
                    Text("Check for Updates")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.9))
                    Spacer()
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
            }
            .buttonStyle(.plain)
            
            // Quit Manage Your Display
            Button(action: {
                NSApplication.shared.terminate(nil)
            }) {
                HStack {
                    Image(systemName: "xmark.circle")
                        .font(.system(size: 11))
                        .frame(width: 18)
                        .foregroundColor(.red.opacity(0.8))
                    Text("Quit Manage Your Display")
                        .font(.system(size: 11))
                        .foregroundColor(.red.opacity(0.9))
                    Spacer()
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
    }
    
    private func toolSubmenuRow<Content: View>(
        icon: String,
        title: String,
        key: String,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        VStack(spacing: 0) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.15)) {
                    expandedTool = (expandedTool == key ? nil : key)
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
                    Image(systemName: expandedTool == key ? "chevron.down" : "chevron.right")
                        .font(.system(size: 9))
                        .foregroundColor(.white.opacity(0.5))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(expandedTool == key ? Color.white.opacity(0.06) : Color.clear)
            }
            .buttonStyle(.plain)
            
            if expandedTool == key {
                VStack(spacing: 3) {
                    content()
                }
                .padding(.leading, 28)
                .padding(.trailing, 10)
                .padding(.vertical, 4)
                .background(Color.black.opacity(0.2))
            }
        }
    }
    
    private var virtualScreensSubmenu: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Create Virtual Screen")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white.opacity(0.5))
                .padding(.top, 2)
            
            ForEach(virtualManager.presets.prefix(5)) { preset in
                Button(action: {
                    _ = virtualManager.createVirtualDisplay(preset: preset)
                }) {
                    HStack {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 10))
                            .foregroundColor(.blue)
                        Text(preset.name)
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.85))
                        Spacer()
                    }
                    .padding(.vertical, 2)
                }
                .buttonStyle(.plain)
            }
            
            if !virtualManager.virtualDisplays.isEmpty {
                Divider().background(Color.white.opacity(0.2)).padding(.vertical, 3)
                Text("Active Virtual Screens")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white.opacity(0.5))
                
                ForEach(virtualManager.virtualDisplays) { item in
                    HStack {
                        Text(item.name)
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.9))
                        Spacer()
                        Button(action: {
                            virtualManager.remove(item: item)
                        }) {
                            Image(systemName: "trash")
                                .font(.system(size: 10))
                                .foregroundColor(.red.opacity(0.8))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }
    
    private var videoFilterSubmenu: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(["Night Warmth Filter", "Anti-Glare Tint", "Full Blackout"], id: \.self) { filter in
                HStack {
                    Text(filter)
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.85))
                    Spacer()
                }
                .padding(.vertical, 2)
                .contentShape(Rectangle())
            }
        }
    }
    
    private var systemColoursSubmenu: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Dark Appearance")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.85))
                Spacer()
                Image(systemName: "checkmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.blue)
            }
            .padding(.vertical, 2)
            
            HStack {
                Text("Night Shift")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.85))
                Spacer()
            }
            .padding(.vertical, 2)
        }
    }
}
