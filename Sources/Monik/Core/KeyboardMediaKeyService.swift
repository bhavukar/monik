//
//  KeyboardMediaKeyService.swift
//  Monik
//

import AppKit
import CoreGraphics

public class KeyboardMediaKeyService {
    public static let shared = KeyboardMediaKeyService()
    
    private var globalMonitor: Any?
    private var localMonitor: Any?
    @Published public var isEnabled: Bool = true
    
    private init() {
        startMonitoring()
    }
    
    public func startMonitoring() {
        stopMonitoring()
        
        // Monitor global key down events
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyEvent(event)
        }
        
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if self?.handleKeyEvent(event) == true {
                return nil // Consume event
            }
            return event
        }
    }
    
    public func stopMonitoring() {
        if let gm = globalMonitor {
            NSEvent.removeMonitor(gm)
            globalMonitor = nil
        }
        if let lm = localMonitor {
            NSEvent.removeMonitor(lm)
            localMonitor = nil
        }
    }
    
    @discardableResult
    private func handleKeyEvent(_ event: NSEvent) -> Bool {
        guard isEnabled else { return false }
        
        // Check special function keys: F1 (Brightness Down), F2 (Brightness Up), F10 (Mute), F11 (Vol Down), F12 (Vol Up)
        let mainDisplay = DisplayManager.shared.displays.first(where: { $0.isMain }) ?? DisplayManager.shared.displays.first
        guard let target = mainDisplay else { return false }
        
        switch event.keyCode {
        case 144: // Brightness Up
            let newB = min(1.0, target.combinedBrightness + 0.05)
            DisplayManager.shared.setCombinedBrightness(for: target, value: newB)
            DisplayGroupManager.shared.syncBrightness(from: target.id, value: newB)
            return true
        case 145: // Brightness Down
            let newB = max(0.0, target.combinedBrightness - 0.05)
            DisplayManager.shared.setCombinedBrightness(for: target, value: newB)
            DisplayGroupManager.shared.syncBrightness(from: target.id, value: newB)
            return true
        case 111: // F12 (Volume Up)
            let newV = min(1.0, target.volume + 0.05)
            DisplayManager.shared.setVolume(for: target, value: newV)
            DisplayGroupManager.shared.syncVolume(from: target.id, value: newV)
            return true
        case 103: // F11 (Volume Down)
            let newV = max(0.0, target.volume - 0.05)
            DisplayManager.shared.setVolume(for: target, value: newV)
            DisplayGroupManager.shared.syncVolume(from: target.id, value: newV)
            return true
        case 109: // F10 (Mute)
            _ = DDCService.shared.setMute(displayID: target.id, isMuted: true)
            return true
        default:
            return false
        }
    }
}
