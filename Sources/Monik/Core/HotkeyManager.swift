//
//  HotkeyManager.swift
//  Manage Your Display
//

import AppKit
import SwiftUI
import CoreGraphics

public struct CustomShortcutItem: Identifiable, Codable {
    public var id: String
    public var title: String
    public var actionType: String
    public var keyCode: UInt16
    public var modifiers: UInt // NSEvent.ModifierFlags raw value
    public var isEnabled: Bool
    
    public init(id: String, title: String, actionType: String, keyCode: UInt16, modifiers: UInt, isEnabled: Bool = true) {
        self.id = id
        self.title = title
        self.actionType = actionType
        self.keyCode = keyCode
        self.modifiers = modifiers
        self.isEnabled = isEnabled
    }
    
    public var shortcutDisplayString: String {
        var str = ""
        let flags = NSEvent.ModifierFlags(rawValue: modifiers)
        if flags.contains(.control) { str += "⌃" }
        if flags.contains(.option) { str += "⌥" }
        if flags.contains(.shift) { str += "⇧" }
        if flags.contains(.command) { str += "⌘" }
        
        switch keyCode {
        case 35: str += "P"
        case 46: str += "M"
        case 0:  str += "A"
        case 15: str += "R"
        case 9:  str += "V"
        case 34: str += "I"
        case 1:  str += "S"
        case 126: str += "↑"
        case 125: str += "↓"
        case 124: str += "→"
        case 123: str += "←"
        default: str += "Key(\(keyCode))"
        }
        return str
    }
}

public class HotkeyManager: ObservableObject {
    public static let shared = HotkeyManager()
    
    private var globalMonitor: Any?
    private var localMonitor: Any?
    
    @Published public var shortcuts: [CustomShortcutItem] = [
        CustomShortcutItem(id: "toggle_main_power", title: "Toggle Main Display Power (On/Off)", actionType: "toggle_power", keyCode: 35, modifiers: NSEvent.ModifierFlags([.command, .option]).rawValue),
        CustomShortcutItem(id: "toggle_macbook", title: "Toggle MacBook Built-in Display", actionType: "toggle_macbook", keyCode: 46, modifiers: NSEvent.ModifierFlags([.command, .option]).rawValue),
        CustomShortcutItem(id: "toggle_all", title: "Toggle All Displays On/Off", actionType: "toggle_all", keyCode: 0, modifiers: NSEvent.ModifierFlags([.command, .option]).rawValue),
        CustomShortcutItem(id: "cycle_resolution", title: "Cycle Display Resolution / HiDPI", actionType: "cycle_resolution", keyCode: 15, modifiers: NSEvent.ModifierFlags([.command, .option]).rawValue),
        CustomShortcutItem(id: "toggle_pip", title: "Toggle Picture-in-Picture (PiP)", actionType: "toggle_pip", keyCode: 9, modifiers: NSEvent.ModifierFlags([.command, .option]).rawValue),
        CustomShortcutItem(id: "switch_input", title: "Switch Input Source (KVM HDMI/DP)", actionType: "switch_input", keyCode: 34, modifiers: NSEvent.ModifierFlags([.command, .option]).rawValue),
        CustomShortcutItem(id: "virtual_screen", title: "Create / Toggle Virtual Screen", actionType: "virtual_screen", keyCode: 1, modifiers: NSEvent.ModifierFlags([.command, .option]).rawValue)
    ]
    
    private init() {
        loadShortcuts()
        startListening()
    }
    
    public func startListening() {
        stopListening()
        
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyEvent(event)
        }
        
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if self?.handleKeyEvent(event) == true {
                return nil
            }
            return event
        }
    }
    
    public func stopListening() {
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
    public func handleKeyEvent(_ event: NSEvent) -> Bool {
        let pressedModifiers = event.modifierFlags.intersection([.command, .option, .control, .shift]).rawValue
        
        for sc in shortcuts where sc.isEnabled {
            if sc.keyCode == event.keyCode && sc.modifiers == pressedModifiers {
                executeAction(sc.actionType)
                return true
            }
        }
        return false
    }
    
    public func executeAction(_ actionType: String) {
        let displayManager = DisplayManager.shared
        let mainDisplay = displayManager.displays.first(where: { $0.isMain }) ?? displayManager.displays.first
        
        switch actionType {
        case "toggle_power":
            if let disp = mainDisplay {
                let newState = !disp.isPoweredOn
                displayManager.setPower(for: disp, powerOn: newState)
                OSDHUDController.shared.show(
                    icon: newState ? "display" : "power",
                    title: disp.name,
                    valueText: newState ? "Connected" : "Disconnected"
                )
            }
        case "toggle_macbook":
            if let macbook = displayManager.displays.first(where: { $0.isBuiltIn }) {
                let newState = !macbook.isPoweredOn
                displayManager.setPower(for: macbook, powerOn: newState)
                OSDHUDController.shared.show(
                    icon: newState ? "laptopcomputer" : "power",
                    title: "MacBook Display",
                    valueText: newState ? "Awake" : "Sleeping"
                )
            }
        case "toggle_all":
            let anyOn = displayManager.displays.contains(where: { $0.isPoweredOn })
            let targetState = !anyOn
            for d in displayManager.displays {
                displayManager.setPower(for: d, powerOn: targetState)
            }
            OSDHUDController.shared.show(
                icon: targetState ? "display.2" : "power",
                title: "All Displays",
                valueText: targetState ? "All Connected" : "All Sleeping"
            )
        case "cycle_resolution":
            if let disp = mainDisplay, !disp.availableModes.isEmpty {
                let curIdx = disp.availableModes.firstIndex(where: { $0.isActive }) ?? 0
                let nextIdx = (curIdx + 1) % disp.availableModes.count
                let nextMode = disp.availableModes[nextIdx]
                displayManager.setDisplayMode(for: disp, mode: nextMode)
                OSDHUDController.shared.show(
                    icon: "aspectratio",
                    title: disp.name,
                    valueText: nextMode.descriptionString
                )
            }
        case "toggle_pip":
            if let disp = mainDisplay {
                PictureInPictureService.shared.togglePiP(for: disp.id)
                OSDHUDController.shared.show(
                    icon: "pip",
                    title: disp.name,
                    valueText: "Picture in Picture"
                )
            }
        case "switch_input":
            if let disp = mainDisplay {
                let nextInput = (disp.currentInputSource == "HDMI 1") ? (name: "DisplayPort 1", code: UInt16(0x0F)) : (name: "HDMI 1", code: UInt16(0x11))
                displayManager.setInputSource(for: disp, code: nextInput.code, name: nextInput.name)
                OSDHUDController.shared.show(
                    icon: "cable.connector",
                    title: disp.name,
                    valueText: nextInput.name
                )
            }
        case "virtual_screen":
            if let preset = VirtualDisplayManager.shared.presets.first {
                let item = VirtualDisplayManager.shared.createVirtualDisplay(preset: preset)
                OSDHUDController.shared.show(
                    icon: "rectangle.badge.plus",
                    title: "Virtual Screen",
                    valueText: item != nil ? "Created (16:9)" : "Failed"
                )
            }
        default:
            break
        }
    }
    
    private func loadShortcuts() {
        if let data = UserDefaults.standard.data(forKey: "custom_shortcuts"),
           let decoded = try? JSONDecoder().decode([CustomShortcutItem].self, from: data) {
            self.shortcuts = decoded
        }
    }
    
    public func saveShortcuts() {
        if let encoded = try? JSONEncoder().encode(shortcuts) {
            UserDefaults.standard.set(encoded, forKey: "custom_shortcuts")
        }
    }
}
