//
//  VirtualDisplayManager.swift
//  Monik
//

import Foundation
import CoreGraphics
import MonikBridge

public struct VirtualPreset: Identifiable {
    public var id: String { name }
    public let name: String
    public let width: UInt32
    public let height: UInt32
    public let aspectString: String
}

public class VirtualDisplayItem: Identifiable, ObservableObject {
    public var id: UInt32 { serialNum }
    public let name: String
    public let serialNum: UInt32
    public let preset: VirtualPreset
    @Published public var isConnected: Bool = false
    @Published public var displayID: CGDirectDisplayID = 0
    
    fileprivate var virtualDisplay: CGVirtualDisplay?
    
    public init(name: String, serialNum: UInt32, preset: VirtualPreset) {
        self.name = name
        self.serialNum = serialNum
        self.preset = preset
    }
}

public class VirtualDisplayManager: ObservableObject {
    public static let shared = VirtualDisplayManager()
    
    @Published public var virtualDisplays: [VirtualDisplayItem] = []
    
    public let presets: [VirtualPreset] = [
        VirtualPreset(name: "16:9 Standard (1080p)", width: 1920, height: 1080, aspectString: "16:9"),
        VirtualPreset(name: "16:9 2K QHD (1440p)", width: 2560, height: 1440, aspectString: "16:9"),
        VirtualPreset(name: "16:9 4K UHD", width: 3840, height: 2160, aspectString: "16:9"),
        VirtualPreset(name: "16:10 MacBook Pro (14\")", width: 3024, height: 1964, aspectString: "16:10"),
        VirtualPreset(name: "16:10 MacBook Pro (16\")", width: 3456, height: 2234, aspectString: "16:10"),
        VirtualPreset(name: "21:9 Ultrawide (UWQHD)", width: 3440, height: 1440, aspectString: "21:9"),
        VirtualPreset(name: "32:9 Super Ultrawide", width: 5120, height: 1440, aspectString: "32:9"),
        VirtualPreset(name: "4:3 Classic", width: 1600, height: 1200, aspectString: "4:3"),
        VirtualPreset(name: "1:1 Square", width: 1440, height: 1440, aspectString: "1:1")
    ]
    
    private init() {}
    
    public func createVirtualDisplay(preset: VirtualPreset, hiDPI: Bool = true) -> VirtualDisplayItem? {
        let serial = UInt32.random(in: 1000...99999)
        let name = "Monik Virtual (\(preset.aspectString))"
        
        guard let descriptor = CGVirtualDisplayDescriptor() else { return nil }
        descriptor.queue = DispatchQueue.global(qos: .userInteractive)
        descriptor.name = name
        descriptor.whitePoint = CGPoint(x: 0.950, y: 1.000)
        descriptor.redPrimary = CGPoint(x: 0.454, y: 0.242)
        descriptor.greenPrimary = CGPoint(x: 0.353, y: 0.674)
        descriptor.bluePrimary = CGPoint(x: 0.157, y: 0.084)
        descriptor.maxPixelsWide = preset.width * (hiDPI ? 2 : 1)
        descriptor.maxPixelsHigh = preset.height * (hiDPI ? 2 : 1)
        descriptor.sizeInMillimeters = CGSize(width: 531.0, height: 298.0) // ~24" diagonal
        descriptor.serialNum = serial
        descriptor.productID = UInt32(preset.width & 0xFFFF)
        descriptor.vendorID = 0xF0F0
        
        guard let display = CGVirtualDisplay(descriptor: descriptor) else { return nil }
        
        // Setup modes (60Hz, 75Hz, 120Hz)
        var modes: [CGVirtualDisplayMode] = []
        for rate in [60.0, 75.0, 120.0] {
            if let mode = CGVirtualDisplayMode(width: preset.width, height: preset.height, refreshRate: rate) {
                modes.append(mode)
            }
        }
        
        guard let settings = CGVirtualDisplaySettings() else { return nil }
        settings.hiDPI = hiDPI ? 1 : 0
        settings.modes = modes
        
        guard display.applySettings(settings) else { return nil }
        
        let item = VirtualDisplayItem(name: name, serialNum: serial, preset: preset)
        item.virtualDisplay = display
        item.displayID = display.displayID
        item.isConnected = true
        
        virtualDisplays.append(item)
        return item
    }
    
    public func disconnect(item: VirtualDisplayItem) {
        item.virtualDisplay = nil
        item.isConnected = false
    }
    
    public func remove(item: VirtualDisplayItem) {
        disconnect(item: item)
        virtualDisplays.removeAll { $0.id == item.id }
    }
}
