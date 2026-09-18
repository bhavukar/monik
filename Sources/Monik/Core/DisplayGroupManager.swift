//
//  DisplayGroupManager.swift
//  Monik
//

import Foundation
import CoreGraphics

public struct DisplayGroup: Identifiable, Codable {
    public var id: UUID = UUID()
    public var name: String
    public var displayIDs: [UInt32]
    public var syncBrightness: Bool = true
    public var syncVolume: Bool = true
    public var syncPower: Bool = true
    
    public init(name: String, displayIDs: [UInt32] = [], syncBrightness: Bool = true, syncVolume: Bool = true, syncPower: Bool = true) {
        self.name = name
        self.displayIDs = displayIDs
        self.syncBrightness = syncBrightness
        self.syncVolume = syncVolume
        self.syncPower = syncPower
    }
}

public class DisplayGroupManager: ObservableObject {
    public static let shared = DisplayGroupManager()
    
    @Published public var groups: [DisplayGroup] = [
        DisplayGroup(name: "All Displays", displayIDs: [], syncBrightness: true, syncVolume: true, syncPower: true)
    ]
    
    private init() {}
    
    public func addGroup(name: String) {
        groups.append(DisplayGroup(name: name))
    }
    
    public func removeGroup(id: UUID) {
        groups.removeAll { $0.id == id }
    }
    
    public func syncBrightness(from sourceDisplayID: CGDirectDisplayID, value: Double) {
        for group in groups where group.syncBrightness {
            if group.displayIDs.isEmpty || group.displayIDs.contains(UInt32(sourceDisplayID)) {
                for display in DisplayManager.shared.displays where display.id != sourceDisplayID {
                    if group.displayIDs.isEmpty || group.displayIDs.contains(UInt32(display.id)) {
                        DisplayManager.shared.setCombinedBrightness(for: display, value: value)
                    }
                }
            }
        }
    }
    
    public func syncVolume(from sourceDisplayID: CGDirectDisplayID, value: Double) {
        for group in groups where group.syncVolume {
            if group.displayIDs.isEmpty || group.displayIDs.contains(UInt32(sourceDisplayID)) {
                for display in DisplayManager.shared.displays where display.id != sourceDisplayID {
                    if group.displayIDs.isEmpty || group.displayIDs.contains(UInt32(display.id)) {
                        DisplayManager.shared.setVolume(for: display, value: value)
                    }
                }
            }
        }
    }
    
    public func syncPower(from sourceDisplayID: CGDirectDisplayID, powerOn: Bool) {
        for group in groups where group.syncPower {
            if group.displayIDs.isEmpty || group.displayIDs.contains(UInt32(sourceDisplayID)) {
                for display in DisplayManager.shared.displays where display.id != sourceDisplayID {
                    if group.displayIDs.isEmpty || group.displayIDs.contains(UInt32(display.id)) {
                        DisplayManager.shared.setPower(for: display, powerOn: powerOn)
                    }
                }
            }
        }
    }
}
