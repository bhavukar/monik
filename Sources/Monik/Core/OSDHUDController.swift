//
//  OSDHUDController.swift
//  Manage Your Display
//

import AppKit
import SwiftUI

public class OSDHUDController: ObservableObject {
    public static let shared = OSDHUDController()
    
    private var hudWindow: NSWindow?
    private var fadeTimer: Timer?
    
    @Published public var iconName: String = "sun.max.fill"
    @Published public var title: String = "Display"
    @Published public var valueText: String = "100%"
    @Published public var progress: Double = 1.0 // 0.0 to 1.0 or -1 for discrete
    
    private init() {}
    
    public func show(icon: String, title: String, valueText: String, progress: Double = -1) {
        DispatchQueue.main.async {
            self.iconName = icon
            self.title = title
            self.valueText = valueText
            self.progress = progress
            
            self.presentWindow()
            
            self.fadeTimer?.invalidate()
            self.fadeTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { [weak self] _ in
                self?.hideWindow()
            }
        }
    }
    
    private func presentWindow() {
        if hudWindow == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 200, height: 180),
                styleMask: [.borderless],
                backing: .buffered,
                defer: false
            )
            window.isOpaque = false
            window.backgroundColor = .clear
            window.level = .floating
            window.collectionBehavior = [.canJoinAllSpaces, .stationary]
            window.ignoresMouseEvents = true
            window.contentView = NSHostingView(rootView: OSDHUDView())
            hudWindow = window
        }
        
        if let mainScreen = NSScreen.main, let window = hudWindow {
            let screenFrame = mainScreen.frame
            let x = screenFrame.midX - 100
            let y = screenFrame.minY + 140
            window.setFrame(NSRect(x: x, y: y, width: 200, height: 180), display: true)
            window.alphaValue = 1.0
            window.orderFrontRegardless()
        }
    }
    
    private func hideWindow() {
        guard let window = hudWindow else { return }
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.3
            window.animator().alphaValue = 0.0
        }, completionHandler: {
            window.orderOut(nil)
        })
    }
}

struct OSDHUDView: View {
    @ObservedObject var osd = OSDHUDController.shared
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: osd.iconName)
                .font(.system(size: 40))
                .foregroundColor(.white)
            
            Text(osd.title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(1)
            
            if osd.progress >= 0 {
                ProgressView(value: max(0.0, min(1.0, osd.progress)))
                    .progressViewStyle(LinearProgressViewStyle(tint: .white))
                    .frame(width: 130)
            } else {
                Text(osd.valueText)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.9))
            }
        }
        .frame(width: 190, height: 170)
        .background(
            VisualEffectBackground(material: .hudWindow, blendingMode: .behindWindow)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.4), radius: 15, x: 0, y: 8)
    }
}
