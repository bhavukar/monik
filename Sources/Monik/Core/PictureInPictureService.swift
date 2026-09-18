//
//  PictureInPictureService.swift
//  Monik
//

import AppKit
import CoreGraphics
import SwiftUI

public class PictureInPictureService: ObservableObject {
    public static let shared = PictureInPictureService()
    
    private var pipWindow: NSPanel?
    private var timer: Timer?
    @Published public var currentImage: NSImage?
    private var targetDisplayID: CGDirectDisplayID = 0
    
    private init() {}
    
    public func togglePiP(for displayID: CGDirectDisplayID) {
        if pipWindow != nil {
            closePiP()
        } else {
            openPiP(for: displayID)
        }
    }
    
    public func openPiP(for displayID: CGDirectDisplayID) {
        closePiP()
        self.targetDisplayID = displayID
        
        let panel = NSPanel(
            contentRect: NSRect(x: 100, y: 100, width: 480, height: 270),
            styleMask: [.titled, .closable, .resizable, .utilityWindow, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        panel.title = "Monik Picture in Picture"
        panel.level = .floating
        panel.isFloatingPanel = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.hidesOnDeactivate = false
        
        let hostingView = NSHostingView(rootView: PiPContentView())
        panel.contentView = hostingView
        panel.orderFrontRegardless()
        
        self.pipWindow = panel
        
        // Start live stream timer (~20 FPS)
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            self?.captureFrame()
        }
    }
    
    public func closePiP() {
        timer?.invalidate()
        timer = nil
        pipWindow?.close()
        pipWindow = nil
    }
    
    private func captureFrame() {
        guard targetDisplayID != 0 else { return }
        if let cgImage = CGDisplayCreateImage(targetDisplayID) {
            let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
            DispatchQueue.main.async {
                self.currentImage = nsImage
            }
        }
    }
}

struct PiPContentView: View {
    @ObservedObject var pip = PictureInPictureService.shared
    
    var body: some View {
        ZStack {
            Color.black
            if let img = pip.currentImage {
                Image(nsImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                ProgressView()
            }
        }
        .frame(minWidth: 240, minHeight: 135)
    }
}
