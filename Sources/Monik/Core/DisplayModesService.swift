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
        
        var seenResolutions = Set<String>()
        
        if numberOfModes > 0 {
            var modeDesc = CGSDisplayMode()
            let modeLength = Int32(MemoryLayout<CGSDisplayMode>.size)
            
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
        }
        
        // Fallback to CoreGraphics modes if SkyLight returned 0
        if items.isEmpty {
            let opt = [kCGDisplayShowDuplicateLowResolutionModes: kCFBooleanTrue] as CFDictionary
            if let cgModes = CGDisplayCopyAllDisplayModes(displayID, opt) as? [CGDisplayMode] {
                for (idx, m) in cgModes.enumerated() {
                    let w = UInt32(m.width)
                    let h = UInt32(m.height)
                    let refresh = m.refreshRate
                    let isHiDPI = (m.pixelWidth > m.width || m.pixelHeight > m.height)
                    let key = "\(w)x\(h)@\(Int(refresh))-\(isHiDPI)"
                    if !seenResolutions.contains(key) {
                        seenResolutions.insert(key)
                        items.append(DisplayModeItem(
                            modeNumber: Int32(idx),
                            width: w,
                            height: h,
                            refreshRate: refresh,
                            isHiDPI: isHiDPI,
                            isActive: (w == CGDisplayPixelsWide(displayID) && h == CGDisplayPixelsHigh(displayID))
                        ))
                    }
                }
            }
        }
        
        // Sort: Active first, then by resolution width descending, then refresh rate descending
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
    
    public func setDisplayEnabled(displayID: CGDirectDisplayID, enabled: Bool) -> Bool {
        // 1. Try native SkyLight CGSConfigureDisplayEnabled
        var config: CGDisplayConfigRef?
        if CGBeginDisplayConfiguration(&config) == .success, let cfg = config {
            let sym = dlsym(UnsafeMutableRawPointer(bitPattern: -2), "CGSConfigureDisplayEnabled")
            if let sym = sym {
                typealias CGSConfigureDisplayEnabled_Func = @convention(c) (CGDisplayConfigRef, CGDirectDisplayID, Bool) -> CGError
                let fn = unsafeBitCast(sym, to: CGSConfigureDisplayEnabled_Func.self)
                let cgsErr = fn(cfg, displayID, enabled)
                if cgsErr == .success {
                    let result = CGCompleteDisplayConfiguration(cfg, .permanently)
                    if result == .success {
                        return true
                    }
                }
            }
            CGCancelDisplayConfiguration(cfg)
        }
        
        // 2. Try CLI displayplacer integration
        if let uuid = getDisplayUUID(for: displayID) {
            let displayplacerPaths = ["/opt/homebrew/bin/displayplacer", "/usr/local/bin/displayplacer"]
            for path in displayplacerPaths {
                if FileManager.default.fileExists(atPath: path) {
                    let task = Process()
                    task.executableURL = URL(fileURLWithPath: path)
                    task.arguments = ["id:\(uuid) enabled:\(enabled ? "true" : "false")"]
                    try? task.run()
                    task.waitUntilExit()
                    if task.terminationStatus == 0 {
                        return true
                    }
                }
            }
        }
        
        return false
    }
    
    public func getDisplayUUID(for displayID: CGDirectDisplayID) -> String? {
        let sym = dlsym(UnsafeMutableRawPointer(bitPattern: -2), "CGDisplayCreateUUIDFromDisplayID")
        if let sym = sym {
            typealias CGDisplayCreateUUIDFromDisplayID_Func = @convention(c) (CGDirectDisplayID) -> CFUUID?
            let fn = unsafeBitCast(sym, to: CGDisplayCreateUUIDFromDisplayID_Func.self)
            if let cfUuid = fn(displayID) {
                return CFUUIDCreateString(kCFAllocatorDefault, cfUuid) as String
            }
        }
        return nil
    }
}
