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
        // 1. Gather ONLY real online, physically connected displays
        var onlineDisplays = [CGDirectDisplayID](repeating: 0, count: 16)
        var count: UInt32 = 0
        _ = CGGetOnlineDisplayList(16, &onlineDisplays, &count)
        var discoveredIDs = Array(onlineDisplays.prefix(Int(count)))
        if discoveredIDs.isEmpty {
            discoveredIDs = [CGMainDisplayID()]
        }
        
        var updatedList: [DisplayInfo] = []
        
        for (index, displayID) in discoveredIDs.enumerated() {
            let isBuiltIn = CGDisplayIsBuiltin(displayID) != 0
            let isMain = CGDisplayIsMain(displayID) != 0
            let isMirrored = CGDisplayIsInMirrorSet(displayID) != 0
            let isOnline = CGDisplayIsOnline(displayID) != 0
            let isActive = CGDisplayIsActive(displayID) != 0
            let isAsleep = CGDisplayIsAsleep(displayID) != 0
            let isBlackout = SoftwareDimmer.shared.isDisplayBlackedOut(displayID: displayID)
            let name = resolveDisplayName(displayID: displayID, isBuiltIn: isBuiltIn, index: index)
            
            var badge = ""
            if isMain {
                badge = "Main"
            } else if isBuiltIn {
                badge = "Built-in"
            }
            
            let display = DisplayInfo(
                id: displayID,
                name: name,
                isBuiltIn: isBuiltIn,
                isMain: isMain,
                isMirrored: isMirrored,
                badge: badge
            )
            
            // True power state based on hardware and OS state
            display.isPoweredOn = isOnline && isActive && !isAsleep && !isBlackout
            
            // Populate modes
            let modes = DisplayModesService.shared.getAvailableModes(for: displayID)
            display.availableModes = modes
            if let active = modes.first(where: { $0.isActive }) {
                display.currentResolution = active.resolutionString
                display.currentRefreshRate = active.refreshRate
                display.isHiDPI = active.isHiDPI
            } else if isOnline {
                display.currentResolution = "\(CGDisplayPixelsWide(displayID)) x \(CGDisplayPixelsHigh(displayID))"
            } else if isBuiltIn {
                display.currentResolution = "3024 x 1964"
            }
            
            // Populate unique refresh rates
            let rates = modes.map { $0.refreshRate }.filter { $0 > 0 }
            let uniqueRates = Array(Set(rates)).sorted()
            if !uniqueRates.isEmpty {
                display.availableRefreshRates = uniqueRates
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
        
        // Preserve user adjusted settings across refreshes
        for newDisplay in updatedList {
            if let existing = self.displays.first(where: { $0.id == newDisplay.id }) {
                newDisplay.isExpanded = existing.isExpanded
                newDisplay.expandedSubmenu = existing.expandedSubmenu
                if existing.combinedBrightness > 0 {
                    newDisplay.combinedBrightness = existing.combinedBrightness
                }
                newDisplay.volume = existing.volume
                newDisplay.contrast = existing.contrast
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
        let clamped = max(0.0, min(1.0, value))
        display.combinedBrightness = clamped
        
        if display.isBuiltIn {
            CoreDisplay_Display_SetUserBrightness(display.id, clamped)
            _ = CGSetDisplayTransferByFormula(display.id, 0.0, 1.0, 1.0, 0.0, 1.0, 1.0, 0.0, 1.0, 1.0)
            SoftwareDimmer.shared.setDimming(displayID: display.id, brightness: 1.0)
        } else {
            let hardwareVal = Int(round(clamped * 100))
            let ddcOk = DDCService.shared.setBrightness(displayID: display.id, value: hardwareVal)
            if ddcOk {
                _ = CGSetDisplayTransferByFormula(display.id, 0.0, 1.0, 1.0, 0.0, 1.0, 1.0, 0.0, 1.0, 1.0)
                SoftwareDimmer.shared.setDimming(displayID: display.id, brightness: 1.0)
            } else {
                // Seamless GPU Hardware Gamma LUT fallback (works across HDMI/dongles/docks)
                let floatVal = Float(clamped)
                _ = CGSetDisplayTransferByFormula(display.id, 0.0, floatVal, 1.0, 0.0, floatVal, 1.0, 0.0, floatVal, 1.0)
                SoftwareDimmer.shared.setDimming(displayID: display.id, brightness: clamped)
            }
        }
    }
    
    public func setContrast(for display: DisplayInfo, value: Double) {
        let clamped = max(0.0, min(1.0, value))
        display.contrast = clamped
        let val = Int(round(clamped * 100))
        let ddcOk = DDCService.shared.setContrast(displayID: display.id, value: val)
        if !ddcOk && !display.isBuiltIn {
            let gamma = Float(0.5 + clamped)
            _ = CGSetDisplayTransferByFormula(display.id, 0.0, Float(display.combinedBrightness), gamma, 0.0, Float(display.combinedBrightness), gamma, 0.0, Float(display.combinedBrightness), gamma)
        }
    }
    
    public func enableMacFontSmoothing() {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/defaults")
        task.arguments = ["-currentHost", "write", "-g", "AppleFontSmoothing", "-int", "2"]
        try? task.run()
        task.waitUntilExit()
        
        let task2 = Process()
        task2.executableURL = URL(fileURLWithPath: "/usr/bin/defaults")
        task2.arguments = ["write", "-g", "CGFontRenderingFontSmoothingDisabled", "-bool", "NO"]
        try? task2.run()
        task2.waitUntilExit()
        
        OSDHUDController.shared.show(
            icon: "textformat.size",
            title: "Font Smoothing Enabled",
            valueText: "Subpixel Text Antialiasing"
        )
    }
    
    public func restoreAllDisplays() {
        SoftwareDimmer.shared.removeAll()
        enableMacFontSmoothing()
        
        for display in displays {
            _ = DisplayModesService.shared.setDisplayEnabled(displayID: display.id, enabled: true)
            resetGeometry(for: display)
            
            // Prefer crisp scaled / HiDPI mode with highest refresh rate
            if let bestMode = display.availableModes.filter({ $0.isHiDPI }).max(by: { $0.refreshRate < $1.refreshRate })
                ?? display.availableModes.max(by: { $0.refreshRate < $1.refreshRate }) {
                setDisplayMode(for: display, mode: bestMode)
            }
            
            setCombinedBrightness(for: display, value: 0.9)
            setContrast(for: display, value: 0.5)
        }
        
        refreshDisplays()
        
        OSDHUDController.shared.show(
            icon: "display",
            title: "Displays Restored",
            valueText: "Optimal Modes & Standard Gamma"
        )
    }
    
    public func setVolume(for display: DisplayInfo, value: Double) {
        let clamped = max(0.0, min(1.0, value))
        display.volume = clamped
        let val = Int(round(clamped * 100))
        _ = DDCService.shared.setVolume(displayID: display.id, value: val)
    }
    
    public func setDisplayMode(for display: DisplayInfo, mode: DisplayModeItem) {
        if DisplayModesService.shared.setDisplayMode(displayID: display.id, modeNumber: mode.modeNumber) {
            display.currentResolution = mode.resolutionString
            display.currentRefreshRate = mode.refreshRate
            display.isHiDPI = mode.isHiDPI
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.refreshDisplays()
            }
        }
    }
    
    public func setRefreshRate(for display: DisplayInfo, targetRate: Double) {
        let curW = CGDisplayPixelsWide(display.id)
        let curH = CGDisplayPixelsHigh(display.id)
        if let mode = display.availableModes.first(where: {
            $0.width == curW && $0.height == curH && abs($0.refreshRate - targetRate) < 1.0
        }) ?? display.availableModes.first(where: { abs($0.refreshRate - targetRate) < 1.0 }) {
            setDisplayMode(for: display, mode: mode)
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
            // 1. Hardware DDC wake
            if !display.isBuiltIn {
                _ = DDCService.shared.setPower(displayID: display.id, powerOn: true)
                let targetB = display.combinedBrightness > 0.05 ? display.combinedBrightness : 0.8
                _ = DDCService.shared.setBrightness(displayID: display.id, value: Int(round(targetB * 100)))
            } else {
                let targetB = display.combinedBrightness > 0.05 ? display.combinedBrightness : 0.8
                CoreDisplay_Display_SetUserBrightness(display.id, targetB)
            }
            
            // 2. Remove software blackout & restore gamma LUT
            SoftwareDimmer.shared.setBlackout(displayID: display.id, isBlackout: false)
            
            // 3. Re-apply current brightness and contrast
            setCombinedBrightness(for: display, value: display.combinedBrightness)
            setContrast(for: display, value: display.contrast)
        } else {
            // 1. Hardware DDC sleep
            if !display.isBuiltIn {
                _ = DDCService.shared.setPower(displayID: display.id, powerOn: false)
            } else {
                CoreDisplay_Display_SetUserBrightness(display.id, 0.0)
            }
            
            // 2. Full blackout (gamma LUT zeroing + black window)
            SoftwareDimmer.shared.setBlackout(displayID: display.id, isBlackout: true)
        }
        
        // Refresh display list after power state change
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.refreshDisplays()
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
    
    // Underscan, Overscan & Geometry
    public func setUnderscan(for display: DisplayInfo, value: Double) {
        display.underscan = value
        
        // 1. Hardware MonitorPanel Underscan if available
        dlopen("/System/Library/PrivateFrameworks/MonitorPanel.framework/MonitorPanel", RTLD_NOW)
        if let MPDisplayClass = NSClassFromString("MPDisplay") as? NSObject.Type {
            let selInit = NSSelectorFromString("initWithCGSDisplayID:")
            if MPDisplayClass.instancesRespond(to: selInit) {
                let alloc = MPDisplayClass.perform(NSSelectorFromString("alloc")).takeUnretainedValue()
                let disp = unsafeBitCast(alloc.perform(selInit, with: display.id), to: AnyObject?.self)
                let selSetU = NSSelectorFromString("setUnderscan:")
                if let d = disp, d.responds(to: selSetU) {
                    _ = d.perform(selSetU, with: Int32(round(value * 100)))
                }
            }
        }
        
        // 2. Hardware DDC size scaling for external monitors
        if !display.isBuiltIn {
            let sizeVal = Int(round((1.0 - (value * 0.4)) * 100))
            _ = DDCService.shared.setHorizontalSize(displayID: display.id, value: sizeVal)
            _ = DDCService.shared.setVerticalSize(displayID: display.id, value: sizeVal)
        }
        
        // 3. Software framing overlay
        SoftwareDimmer.shared.setUnderscanBorder(displayID: display.id, paddingPercent: value)
    }
    
    public func setOverscan(for display: DisplayInfo, enabled: Bool) {
        display.overscanEnabled = enabled
        
        // MonitorPanel overscan
        dlopen("/System/Library/PrivateFrameworks/MonitorPanel.framework/MonitorPanel", RTLD_NOW)
        if let MPDisplayClass = NSClassFromString("MPDisplay") as? NSObject.Type {
            let selInit = NSSelectorFromString("initWithCGSDisplayID:")
            if MPDisplayClass.instancesRespond(to: selInit) {
                let alloc = MPDisplayClass.perform(NSSelectorFromString("alloc")).takeUnretainedValue()
                let disp = unsafeBitCast(alloc.perform(selInit, with: display.id), to: AnyObject?.self)
                let selSetO = NSSelectorFromString("setOverscanEnabled:")
                if let d = disp, d.responds(to: selSetO) {
                    _ = d.perform(selSetO, with: enabled)
                }
            }
        }
        
        if !display.isBuiltIn {
            _ = DDCService.shared.setDisplayScaling(displayID: display.id, modeCode: enabled ? 4 : 1)
        }
    }
    
    public func setHorizontalSize(for display: DisplayInfo, value: Int) {
        display.horizontalSize = value
        _ = DDCService.shared.setHorizontalSize(displayID: display.id, value: value)
    }
    
    public func setVerticalSize(for display: DisplayInfo, value: Int) {
        display.verticalSize = value
        _ = DDCService.shared.setVerticalSize(displayID: display.id, value: value)
    }
    
    public func setHorizontalPosition(for display: DisplayInfo, value: Int) {
        display.horizontalPosition = value
        _ = DDCService.shared.setHorizontalPosition(displayID: display.id, value: value)
    }
    
    public func setVerticalPosition(for display: DisplayInfo, value: Int) {
        display.verticalPosition = value
        _ = DDCService.shared.setVerticalPosition(displayID: display.id, value: value)
    }
    
    public func setDisplayScalingMode(for display: DisplayInfo, mode: String) {
        display.displayScalingMode = mode
        var code: UInt16 = 1
        switch mode {
        case "Aspect Ratio": code = 2
        case "1:1 Pixel Mapping": code = 3
        case "Overscan": code = 4
        default: code = 1 // Full Screen
        }
        _ = DDCService.shared.setDisplayScaling(displayID: display.id, modeCode: code)
    }
    
    public func resetGeometry(for display: DisplayInfo) {
        setUnderscan(for: display, value: 0.0)
        setOverscan(for: display, enabled: false)
        setHorizontalSize(for: display, value: 100)
        setVerticalSize(for: display, value: 100)
        setHorizontalPosition(for: display, value: 50)
        setVerticalPosition(for: display, value: 50)
        setDisplayScalingMode(for: display, mode: "Full Screen")
    }
}
