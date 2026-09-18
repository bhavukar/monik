//
//  DisplayInfo.swift
//  Monik
//

import Foundation
import CoreGraphics

public struct DisplayModeItem: Identifiable, Hashable {
    public var id: String { "\(modeNumber)-\(width)x\(height)@\(refreshRate)-\(isHiDPI)" }
    public let modeNumber: Int32
    public let width: UInt32
    public let height: UInt32
    public let refreshRate: Double
    public let isHiDPI: Bool
    public let isActive: Bool
    
    public var resolutionString: String {
        "\(width) x \(height)"
    }
    
    public var descriptionString: String {
        let hidpiTag = isHiDPI ? " (HiDPI)" : ""
        let rateTag = refreshRate > 0 ? " @ \(Int(round(refreshRate)))Hz" : ""
        return "\(width)x\(height)\(hidpiTag)\(rateTag)"
    }
}

public class DisplayInfo: ObservableObject, Identifiable {
    public let id: CGDirectDisplayID
    @Published public var name: String
    public let vendorID: UInt32
    public let productID: UInt32
    public let serialNumber: UInt32
    
    public let isBuiltIn: Bool
    @Published public var isMain: Bool
    @Published public var isMirrored: Bool
    @Published public var isVirtual: Bool
    @Published public var isDummy: Bool
    @Published public var isPoweredOn: Bool = true
    
    @Published public var badge: String = "" // "C", "M"
    @Published public var combinedBrightness: Double = 1.0 // 0.0 - 1.0
    @Published public var volume: Double = 1.0 // 0.0 - 1.0
    @Published public var contrast: Double = 0.5 // 0.0 - 1.0
    @Published public var currentResolution: String = "1920x1080"
    @Published public var currentRefreshRate: Double = 60.0
    @Published public var rotation: Int = 0 // 0, 90, 180, 270
    @Published public var isHiDPI: Bool = false
    @Published public var currentInputSource: String = "HDMI 1"
    @Published public var currentColorProfile: String = "Default"
    
    @Published public var availableModes: [DisplayModeItem] = []
    @Published public var availableRefreshRates: [Double] = [60, 75, 120, 144]
    
    // UI state
    @Published public var isExpanded: Bool = false
    @Published public var expandedSubmenu: String? = nil // e.g. "displayMode", "refreshRate", etc.
    
    public init(
        id: CGDirectDisplayID,
        name: String,
        vendorID: UInt32 = 0,
        productID: UInt32 = 0,
        serialNumber: UInt32 = 0,
        isBuiltIn: Bool = false,
        isMain: Bool = false,
        isMirrored: Bool = false,
        isVirtual: Bool = false,
        isDummy: Bool = false,
        badge: String = ""
    ) {
        self.id = id
        self.name = name
        self.vendorID = vendorID
        self.productID = productID
        self.serialNumber = serialNumber
        self.isBuiltIn = isBuiltIn
        self.isMain = isMain
        self.isMirrored = isMirrored
        self.isVirtual = isVirtual
        self.isDummy = isDummy
        self.badge = badge
    }
}
