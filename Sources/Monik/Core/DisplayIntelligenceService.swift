//
//  DisplayIntelligenceService.swift
//  Manage Your Display
//

import Foundation
import CoreGraphics
import AppKit

public struct DisplayProfileRecommendation: Identifiable {
    public var id: CGDirectDisplayID
    public let displayID: CGDirectDisplayID
    public let panelName: String
    public let panelCategory: String // e.g. "27\" Fast Gaming Panel", "14\" Liquid Retina XDR", "Ultra-HD Pro"
    public let diagonalInches: Double
    public let ppi: Double
    public let aspectRatioString: String
    
    public let optimalColorProfile: String
    public let optimalResolution: String
    public let optimalRefreshRate: Double
    public let optimalBrightness: Double
    public let optimalContrast: Double
    
    public let explanation: String
    public let features: [String]
}

public class DisplayIntelligenceService {
    public static let shared = DisplayIntelligenceService()
    
    private init() {}
    
    public func analyzeDisplay(display: DisplayInfo) -> DisplayProfileRecommendation {
        let displayID = display.id
        let sizeMM = CGDisplayScreenSize(displayID)
        let wPixels = CGDisplayPixelsWide(displayID)
        let hPixels = CGDisplayPixelsHigh(displayID)
        
        let widthInches = sizeMM.width > 0 ? sizeMM.width / 25.4 : 24.0
        let heightInches = sizeMM.height > 0 ? sizeMM.height / 25.4 : 13.5
        var diagonal = sqrt(widthInches * widthInches + heightInches * heightInches)
        
        if display.isBuiltIn && (diagonal < 10 || diagonal > 18) {
            diagonal = 14.2
        } else if diagonal < 5 {
            diagonal = 27.0
        }
        
        // Calculate true PPI
        let truePpi = diagonal > 0 ? sqrt(Double(wPixels * wPixels + hPixels * hPixels)) / diagonal : 109.0
        
        // Determine Aspect Ratio
        let ratio = hPixels > 0 ? Double(wPixels) / Double(hPixels) : 1.77
        var aspectString = "16:9 Widescreen"
        if abs(ratio - (16.0 / 10.0)) < 0.05 {
            aspectString = "16:10 MacBook Aspect"
        } else if abs(ratio - (21.0 / 9.0)) < 0.1 {
            aspectString = "21:9 Ultrawide"
        } else if abs(ratio - (32.0 / 9.0)) < 0.1 {
            aspectString = "32:9 Super Ultrawide"
        } else if abs(ratio - (4.0 / 3.0)) < 0.05 {
            aspectString = "4:3 Standard"
        }
        
        // Find highest supported refresh rate and highest resolution
        let modes = display.availableModes
        let maxRefresh = modes.map { $0.refreshRate }.max() ?? 60.0
        let maxResMode = modes.first(where: { $0.isHiDPI }) ?? modes.first
        let optimalRes = maxResMode?.resolutionString ?? "\(wPixels) x \(hPixels)"
        
        var category = "Standard Display"
        var optimalProfile = "sRGB IEC61966-2.1"
        var explanation = ""
        var features: [String] = []
        var optimalBrightness = 0.85
        let optimalContrast = 0.50
        
        if display.isBuiltIn {
            category = "\(String(format: "%.1f", diagonal))\" Liquid Retina XDR (Wide Gamut)"
            optimalProfile = "Display P3"
            optimalBrightness = 0.80
            explanation = "Apple Liquid Retina XDR screen supports native DCI-P3 wide color gamut with high dynamic range. Setting Display P3 delivers accurate color reproduction across photo and video editing."
            features = ["DCI-P3 Wide Color Gamut", "ProMotion Dynamic Refresh", "True Tone Ready", "Retina 2x Scaling"]
        } else if maxRefresh >= 120 {
            category = "\(String(format: "%.1f", diagonal))\" \(Int(round(maxRefresh)))Hz High-Refresh Gaming Monitor"
            optimalProfile = "sRGB IEC61966-2.1"
            optimalBrightness = 0.90
            explanation = "High-refresh display detected (\(Int(round(maxRefresh)))Hz). Configured with calibrated sRGB IEC61966-2.1 for zero color clipping and lowest input latency."
            features = ["\(Int(round(maxRefresh)))Hz Low-Latency Gaming", "Calibrated sRGB Gamut", "1ms MPRT Response", "\(aspectString)"]
        } else if truePpi >= 160 || wPixels >= 3840 {
            category = "\(String(format: "%.1f", diagonal))\" 4K Ultra-HD Precision Display"
            optimalProfile = "Display P3"
            optimalBrightness = 0.80
            explanation = "High-density 4K panel detected (\(Int(round(truePpi))) PPI). Using Display P3 with HiDPI scaling for sharp typography and rich color depth."
            features = ["4K Ultra-HD Resolution", "HiDPI Pixel Doubling", "Wide Color Spectrum", "Photo & Video Grade"]
        } else {
            category = "\(String(format: "%.1f", diagonal))\" \(aspectString)"
            optimalProfile = "sRGB IEC61966-2.1"
            explanation = "Standard SDR desktop monitor. Calibrated sRGB color profile ensures true-to-life web and document viewing without oversaturation."
            features = ["Standard sRGB Gamut", "\(aspectString)", "\(optimalRes) Native", "\(Int(round(maxRefresh)))Hz Refresh"]
        }
        
        return DisplayProfileRecommendation(
            id: displayID,
            displayID: displayID,
            panelName: display.name,
            panelCategory: category,
            diagonalInches: diagonal,
            ppi: truePpi,
            aspectRatioString: aspectString,
            optimalColorProfile: optimalProfile,
            optimalResolution: optimalRes,
            optimalRefreshRate: maxRefresh,
            optimalBrightness: optimalBrightness,
            optimalContrast: optimalContrast,
            explanation: explanation,
            features: features
        )
    }
    
    public func applyRecommendation(display: DisplayInfo, recommendation: DisplayProfileRecommendation) {
        display.currentColorProfile = recommendation.optimalColorProfile
        DisplayManager.shared.setCombinedBrightness(for: display, value: recommendation.optimalBrightness)
        
        // Find best mode matching optimal resolution and refresh rate
        if let bestMode = display.availableModes.first(where: {
            $0.resolutionString == recommendation.optimalResolution &&
            Int(round($0.refreshRate)) == Int(round(recommendation.optimalRefreshRate))
        }) ?? display.availableModes.first(where: { Int(round($0.refreshRate)) == Int(round(recommendation.optimalRefreshRate)) }) {
            DisplayManager.shared.setDisplayMode(for: display, mode: bestMode)
        }
    }
}
