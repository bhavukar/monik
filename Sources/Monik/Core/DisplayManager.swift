//
//  DisplayManager.swift
//  Monik
//

import Foundation
import CoreGraphics
import AppKit
import MonikBridge

public class DisplayManager: ObservableObject {
    public static let shared = DisplayManager()
    
    @Published public var displays: [DisplayInfo] = []
    @Published public var selectedDisplayID: CGDirectDisplayID = 0
    
    private init() {
        refreshDisplays()
        setupListeners()
    }
    
    private func setupListeners() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenParametersChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
        
        CGDisplayRegisterReconfigurationCallback({ _, _, _ in
            DispatchQueue.main.async {
                DisplayManager.shared.refreshDisplays()
            }
        }, nil)
    }
    
    @objc private func screenParametersChanged() {
        DispatchQueue.main.async {
            self.refreshDisplays()
        }
    }
    
    public func refreshDisplays() {
        // 1. Gather all online displays
        var onlineDisplays = [CGDirectDisplayID](repeating: 0, count: 16)
        var count: UInt32 = 0
        _ = CGGetOnlineDisplayList(16, &onlineDisplays, &count)
        var discoveredIDs = Set(Array(onlineDisplays.prefix(Int(count))))
        
        // 2. Also scan potential CoreDisplay IDs (e.g. built-in display in clamshell mode)
        for candidateID in 1...20 {
            let id = CGDirectDisplayID(candidateID)
            if let unmanagedDict = CoreDisplay_DisplayCreateInfoDictionary(id) {
                let dict = unmanagedDict.takeRetainedValue() as NSDictionary
                if dict["DisplayProductName"] != nil || CGDisplayIsBuiltin(id) != 0 {
                    discoveredIDs.insert(id)
                }
            }
        }
        
        var updatedList: [DisplayInfo] = []
        let sortedIDs = Array(discoveredIDs).sorted { id1, id2 in
            // Place main display first, then other online displays, then built-in, then others
            let isMain1 = CGDisplayIsMain(id1) != 0
            let isMain2 = CGDisplayIsMain(id2) != 0
            if isMain1 != isMain2 { return isMain1 }
            let isOnline1 = CGDisplayIsOnline(id1) != 0
            let isOnline2 = CGDisplayIsOnline(id2) != 0
            if isOnline1 != isOnline2 { return isOnline1 }
            return id1 < id2
        }
        
        for (index, displayID) in sortedIDs.enumerated() {
            let isBuiltIn = CGDisplayIsBuiltin(displayID) != 0
            let isMain = CGDisplayIsMain(displayID) != 0
            let isMirrored = CGDisplayIsInMirrorSet(displayID) != 0
            let isOnline = CGDisplayIsOnline(displayID) != 0
            let name = resolveDisplayName(displayID: displayID, isBuiltIn: isBuiltIn, index: index)
            
            var badge = ""
            if isMain {
                badge = "M"
            } else if isBuiltIn {
                badge = "Built-in"
            } else if index == 0 || index == 1 {
                badge = "C"
            }
            
            let display = DisplayInfo(
                id: displayID,
                name: name,
                isBuiltIn: isBuiltIn,
                isMain: isMain,
                isMirrored: isMirrored,
                badge: badge
            )
            
            display.isPoweredOn = isOnline && !SoftwareDimmer.shared.isDisplayBlackedOut(displayID: displayID)
            
            // Populate modes
            let modes = DisplayModesService.shared.getAvailableModes(for: displayID)
            display.availableModes = modes
            if let active = modes.first(where: { $0.isActive }) {
                display.currentResolution = active.resolutionString
                display.currentRefreshRate = active.refreshRate
                display.isHiDPI = active.isHiDPI
            } else if isOnline {
                display.currentResolution = "\(CGDisplayPixelsWide(displayID))x\(CGDisplayPixelsHigh(displayID))"
            } else if isBuiltIn {
                display.currentResolution = "3024 x 1964 (Built-in Retina)"
            }
            
            display.rotation = Int(CGDisplayRotation(displayID))
            
            // Read built-in brightness
            if isBuiltIn {
                let br = CoreDisplay_Display_GetUserBrightness(displayID)
                if br > 0 {
                    display.combinedBrightness = br
                }
            }
            
            updatedList.append(display)
        }
        
        // Preserve open UI state across refreshes
        for newDisplay in updatedList {
            if let existing = self.displays.first(where: { $0.id == newDisplay.id }) {
                newDisplay.isExpanded = existing.isExpanded
                newDisplay.expandedSubmenu = existing.expandedSubmenu
                newDisplay.combinedBrightness = existing.combinedBrightness
                newDisplay.volume = existing.volume
                newDisplay.isPoweredOn = existing.isPoweredOn
            }
        }
        
        self.displays = updatedList
        if selectedDisplayID == 0, let first = updatedList.first {
            selectedDisplayID = first.id
        }
        DDCService.shared.refreshServices()
    }
    
    private func resolveDisplayName(displayID: CGDirectDisplayID, isBuiltIn: Bool, index: Int) -> String {
        if let unmanagedDict = CoreDisplay_DisplayCreateInfoDictionary(displayID) {
            let dict = unmanagedDict.takeRetainedValue() as NSDictionary
            if let names = dict["DisplayProductName"] as? [String: String] {
                if let name = names["en_US"] ?? names.values.first {
                    if isBuiltIn || name == "Färg-LCD" || name == "Color LCD" {
                        return "MacBook Display"
                    }
                    return name
                }
            }
        }
        
        if isBuiltIn {
            return "MacBook Display (Built-in)"
        }
        return "Display \(index + 1)"
    }
    
    // Core Actions
    public func setCombinedBrightness(for display: DisplayInfo, value: Double) {
        display.combinedBrightness = value
        
        if display.isBuiltIn {
            CoreDisplay_Display_SetUserBrightness(display.id, value)
        } else {
            let hardwareVal = Int(round(value * 100))
            _ = DDCService.shared.setBrightness(displayID: display.id, value: hardwareVal)
        }
        
        SoftwareDimmer.shared.setDimming(displayID: display.id, brightness: value)
    }
    
    public func setVolume(for display: DisplayInfo, value: Double) {
        display.volume = value
        let val = Int(round(value * 100))
        _ = DDCService.shared.setVolume(displayID: display.id, value: val)
    }
    
    public func setDisplayMode(for display: DisplayInfo, mode: DisplayModeItem) {
        if DisplayModesService.shared.setDisplayMode(displayID: display.id, modeNumber: mode.modeNumber) {
            display.currentResolution = mode.resolutionString
            display.currentRefreshRate = mode.refreshRate
            display.isHiDPI = mode.isHiDPI
        }
    }
    
    public func setRotation(for display: DisplayInfo, degrees: Int) {
        if DisplayModesService.shared.setRotation(displayID: display.id, rotationDegrees: degrees) {
            display.rotation = degrees
            refreshDisplays()
        }
    }
    
    public func setAsMainDisplay(for display: DisplayInfo) {
        if DisplayModesService.shared.setAsMainDisplay(displayID: display.id) {
            refreshDisplays()
        }
    }
    
    public func setPower(for display: DisplayInfo, powerOn: Bool) {
        display.isPoweredOn = powerOn
        
        if powerOn {
            // Power ON / Connect / Wake
            SoftwareDimmer.shared.setBlackout(displayID: display.id, isBlackout: false)
            if display.isBuiltIn {
                let targetB = display.combinedBrightness > 0.05 ? display.combinedBrightness : 0.8
                CoreDisplay_Display_SetUserBrightness(display.id, targetB)
            } else {
                _ = DDCService.shared.setPower(displayID: display.id, powerOn: true)
                let targetB = display.combinedBrightness > 0.05 ? display.combinedBrightness : 0.75
                _ = DDCService.shared.setBrightness(displayID: display.id, value: Int(round(targetB * 100)))
            }
        } else {
            // Power OFF / Disconnect / Sleep
            if display.isBuiltIn {
                CoreDisplay_Display_SetUserBrightness(display.id, 0.0)
            } else {
                _ = DDCService.shared.setPower(displayID: display.id, powerOn: false)
                _ = DDCService.shared.setBrightness(displayID: display.id, value: 0)
            }
            SoftwareDimmer.shared.setBlackout(displayID: display.id, isBlackout: true)
        }
    }
    
    public func connectAllDisplays() {
        for display in displays {
            setPower(for: display, powerOn: true)
        }
    }
    
    public func setInputSource(for display: DisplayInfo, code: UInt16, name: String) {
        display.currentInputSource = name
        _ = DDCService.shared.setInputSource(displayID: display.id, code: code)
    }
}
