//
//  SoftwareDimmer.swift
//  Monik
//

import AppKit
import CoreGraphics

public class SoftwareDimmer {
    public static let shared = SoftwareDimmer()
    
    private var overlayWindows: [CGDirectDisplayID: NSWindow] = [:]
    private var blackoutWindows: [CGDirectDisplayID: NSWindow] = [:]
    private var blackedOutDisplays: Set<CGDirectDisplayID> = []
    
    private init() {}
    
    public func setDimming(displayID: CGDirectDisplayID, brightness: Double) {
        DispatchQueue.main.async {
            let clamped = max(0.0, min(1.0, brightness))
            let dimAlpha = (1.0 - clamped) * 0.85
            
            if dimAlpha <= 0.01 {
                self.overlayWindows[displayID]?.orderOut(nil)
                return
            }
            
            guard let window = self.getOrCreateWindow(for: displayID, isBlackout: false) else { return }
            window.backgroundColor = NSColor.black.withAlphaComponent(CGFloat(dimAlpha))
            window.orderFrontRegardless()
        }
    }
    
    public func setBlackout(displayID: CGDirectDisplayID, isBlackout: Bool) {
        DispatchQueue.main.async {
            if isBlackout {
                self.blackedOutDisplays.insert(displayID)
                
                // 1. Hardware video gamma LUT zeroing (complete physical blackout)
                let blackLUT: [CGGammaValue] = [0.0, 0.0]
                _ = CGSetDisplayTransferByTable(displayID, 2, blackLUT, blackLUT, blackLUT)
                
                // 2. Fullscreen blackout overlay window
                if let window = self.getOrCreateWindow(for: displayID, isBlackout: true) {
                    window.backgroundColor = NSColor.black
                    window.orderFrontRegardless()
                }
            } else {
                self.blackedOutDisplays.remove(displayID)
                
                // 1. Restore hardware ColorSync gamma curve
                CGDisplayRestoreColorSyncSettings()
                
                // 2. Hide blackout window
                self.blackoutWindows[displayID]?.orderOut(nil)
            }
        }
    }
    
    public func isDisplayBlackedOut(displayID: CGDirectDisplayID) -> Bool {
        return blackedOutDisplays.contains(displayID)
    }
    
    private func getOrCreateWindow(for displayID: CGDirectDisplayID, isBlackout: Bool) -> NSWindow? {
        // Find current matching screen
        guard let screen = NSScreen.screens.first(where: {
            ($0.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID) == displayID
        }) else {
            return nil
        }
        
        let targetFrame = screen.frame
        let storage = isBlackout ? blackoutWindows : overlayWindows
        
        if let existing = storage[displayID] {
            existing.setFrame(targetFrame, display: true)
            return existing
        }
        
        let window = NSWindow(
            contentRect: targetFrame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        window.isOpaque = false
        window.backgroundColor = NSColor.clear
        window.ignoresMouseEvents = true
        // Level just below status bar / popover so menu bar controls remain fully accessible
        window.level = NSWindow.Level(Int(CGWindowLevelForKey(.mainMenuWindow)) - 1)
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        window.hasShadow = false
        
        if isBlackout {
            blackoutWindows[displayID] = window
        } else {
            overlayWindows[displayID] = window
        }
        return window
    }
    
    public func removeAll() {
        DispatchQueue.main.async {
            CGDisplayRestoreColorSyncSettings()
            for (_, window) in self.overlayWindows {
                window.orderOut(nil)
            }
            for (_, window) in self.blackoutWindows {
                window.orderOut(nil)
            }
            self.overlayWindows.removeAll()
            self.blackoutWindows.removeAll()
            self.blackedOutDisplays.removeAll()
        }
    }
}
