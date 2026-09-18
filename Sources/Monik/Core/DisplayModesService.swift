//
//  DisplayModesService.swift
//  Monik
//

import Foundation
import CoreGraphics
import AppKit
import MonikBridge

public class DisplayModesService {
    public static let shared = DisplayModesService()
    
    private init() {}
    
    public func getAvailableModes(for displayID: CGDirectDisplayID) -> [DisplayModeItem] {
        var items: [DisplayModeItem] = []
        var numberOfModes: Int32 = 0
        var currentModeNum: Int32 = 0
        
        CGSGetNumberOfDisplayModes(displayID, &numberOfModes)
        CGSGetCurrentDisplayMode(displayID, &currentModeNum)
        
        guard numberOfModes > 0 else { return items }
        
        var modeDesc = CGSDisplayMode()
        let modeLength = Int32(MemoryLayout<CGSDisplayMode>.size)
        
        var seenResolutions = Set<String>()
        
        for i in 0..<numberOfModes {
            CGSGetDisplayModeDescriptionOfLength(displayID, i, &modeDesc, modeLength)
            
            let isHiDPI = modeDesc.density > 1.0
            let refresh = Double(modeDesc.freq)
            let key = "\(modeDesc.width)x\(modeDesc.height)@\(Int(refresh))-\(isHiDPI)"
            
            if !seenResolutions.contains(key) {
                seenResolutions.insert(key)
                let item = DisplayModeItem(
                    modeNumber: Int32(modeDesc.modeNumber),
                    width: modeDesc.width,
                    height: modeDesc.height,
                    refreshRate: refresh,
                    isHiDPI: isHiDPI,
                    isActive: (i == currentModeNum)
                )
                items.append(item)
            }
        }
        
        // Sort: Active first, then by resolution descending
        return items.sorted {
            if $0.isActive != $1.isActive {
                return $0.isActive
            }
            if $0.width != $1.width {
                return $0.width > $1.width
            }
            return $0.refreshRate > $1.refreshRate
        }
    }
    
    public func setDisplayMode(displayID: CGDirectDisplayID, modeNumber: Int32) -> Bool {
        var config: CGDisplayConfigRef?
        guard CGBeginDisplayConfiguration(&config) == .success, let cfg = config else {
            return false
        }
        CGSConfigureDisplayMode(cfg, displayID, modeNumber)
        let result = CGCompleteDisplayConfiguration(cfg, .permanently)
        return result == .success
    }
    
    public func setRotation(displayID: CGDirectDisplayID, rotationDegrees: Int) -> Bool {
        // SLSSetDisplayRotation takes 0, 90, 180, 270
        let err = SLSSetDisplayRotation(displayID, Int32(rotationDegrees))
        return err == .success
    }
    
    public func setMirroring(displayID: CGDirectDisplayID, mirrorTarget: CGDirectDisplayID?) -> Bool {
        var config: CGDisplayConfigRef?
        guard CGBeginDisplayConfiguration(&config) == .success, let cfg = config else {
            return false
        }
        if let target = mirrorTarget {
            CGConfigureDisplayMirrorOfDisplay(cfg, displayID, target)
        } else {
            CGConfigureDisplayMirrorOfDisplay(cfg, displayID, kCGNullDirectDisplay)
        }
        let result = CGCompleteDisplayConfiguration(cfg, .permanently)
        return result == .success
    }
    
    public func setAsMainDisplay(displayID: CGDirectDisplayID) -> Bool {
        var config: CGDisplayConfigRef?
        guard CGBeginDisplayConfiguration(&config) == .success, let cfg = config else {
            return false
        }
        // Origin (0,0) denotes the main display in CoreGraphics
        CGConfigureDisplayOrigin(cfg, displayID, 0, 0)
        let result = CGCompleteDisplayConfiguration(cfg, .permanently)
        return result == .success
    }
}
