//
//  PresetManager.swift
//  Manage Your Display
//

import Foundation
import CoreGraphics

public struct DisplayPresetItem: Identifiable, Codable {
    public var id: String
    public var name: String
    public var icon: String
    public var brightness: Double
    public var volume: Double
    public var onlyPrimaryActive: Bool
    
    public init(id: String, name: String, icon: String, brightness: Double, volume: Double, onlyPrimaryActive: Bool = false) {
        self.id = id
        self.name = name
        self.icon = icon
        self.brightness = brightness
        self.volume = volume
        self.onlyPrimaryActive = onlyPrimaryActive
    }
}

public class PresetManager: ObservableObject {
    public static let shared = PresetManager()
    
    @Published public var presets: [DisplayPresetItem] = [
        DisplayPresetItem(id: "work", name: "Work & Day", icon: "sun.max.fill", brightness: 1.0, volume: 0.8),
        DisplayPresetItem(id: "night", name: "Ultra-Dim Night", icon: "moon.stars.fill", brightness: 0.15, volume: 0.4),
        DisplayPresetItem(id: "gaming", name: "Gaming / Media", icon: "gamecontroller.fill", brightness: 0.9, volume: 1.0),
        DisplayPresetItem(id: "focus", name: "Single Screen Focus", icon: "target", brightness: 1.0, volume: 0.5, onlyPrimaryActive: true)
    ]
    
    private init() {}
    
    public func applyPreset(_ preset: DisplayPresetItem) {
        let displayManager = DisplayManager.shared
        for display in displayManager.displays {
            if preset.onlyPrimaryActive && !display.isMain {
                displayManager.setPower(for: display, powerOn: false)
            } else {
                displayManager.setPower(for: display, powerOn: true)
                displayManager.setCombinedBrightness(for: display, value: preset.brightness)
                displayManager.setVolume(for: display, value: preset.volume)
            }
        }
        
        OSDHUDController.shared.show(
            icon: preset.icon,
            title: "Preset Applied",
            valueText: preset.name
        )
    }
}
