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
    
    private var underscanWindows: [CGDirectDisplayID: [NSWindow]] = [:]
    
    public func setUnderscanBorder(displayID: CGDirectDisplayID, paddingPercent: Double) {
        DispatchQueue.main.async {
            // Remove previous borders for this display
            if let old = self.underscanWindows[displayID] {
                for w in old { w.orderOut(nil) }
                self.underscanWindows[displayID] = nil
            }
            
            guard paddingPercent > 0.001 else { return }
            guard let screen = NSScreen.screens.first(where: {
                ($0.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID) == displayID
            }) else { return }
            
            let frame = screen.frame
            let padW = frame.width * CGFloat(paddingPercent) / 2.0
            let padH = frame.height * CGFloat(paddingPercent) / 2.0
            
            let topRect = NSRect(x: frame.minX, y: frame.maxY - padH, width: frame.width, height: padH)
            let bottomRect = NSRect(x: frame.minX, y: frame.minY, width: frame.width, height: padH)
            let leftRect = NSRect(x: frame.minX, y: frame.minY, width: padW, height: frame.height)
            let rightRect = NSRect(x: frame.maxX - padW, y: frame.minY, width: padW, height: frame.height)
            
            var borders: [NSWindow] = []
            for rect in [topRect, bottomRect, leftRect, rightRect] {
                let win = NSWindow(contentRect: rect, styleMask: [.borderless], backing: .buffered, defer: false)
                win.isOpaque = true
                win.backgroundColor = .black
                win.ignoresMouseEvents = true
                win.level = NSWindow.Level(Int(CGWindowLevelForKey(.mainMenuWindow)) - 1)
                win.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
                win.hasShadow = false
                win.orderFrontRegardless()
                borders.append(win)
            }
            self.underscanWindows[displayID] = borders
        }
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
            for (_, windows) in self.underscanWindows {
                for w in windows { w.orderOut(nil) }
            }
            self.overlayWindows.removeAll()
            self.blackoutWindows.removeAll()
            self.underscanWindows.removeAll()
            self.blackedOutDisplays.removeAll()
        }
    }
}
