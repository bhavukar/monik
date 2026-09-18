//
//  MenuBarController.swift
//  Monik
//

import AppKit
import SwiftUI

public class MenuBarController: NSObject, NSPopoverDelegate {
    public static let shared = MenuBarController()
    
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var eventMonitor: Any?
    
    private override init() {
        super.init()
    }
    
    public func setup() {
        // Create status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .medium)
            if let img = NSImage(systemSymbolName: "display", accessibilityDescription: "Monik")?.withSymbolConfiguration(config) {
                img.isTemplate = true
                button.image = img
            }
            button.target = self
            button.action = #selector(togglePopover)
        }
        
        // Setup popover
        popover = NSPopover()
        popover.contentSize = NSSize(width: 350, height: 620)
        popover.behavior = .transient
        popover.delegate = self
        popover.appearance = NSAppearance(named: .vibrantDark)
        popover.contentViewController = NSHostingController(rootView: MonikPopoverView())
    }
    
    @objc public func togglePopover() {
        guard let button = statusItem.button else { return }
        
        if popover.isShown {
            closePopover()
        } else {
            showPopover(button: button)
        }
    }
    
    private func showPopover(button: NSStatusBarButton) {
        DisplayManager.shared.refreshDisplays()
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        
        // Setup outside-click monitor
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.closePopover()
        }
    }
    
    private func closePopover() {
        popover.performClose(nil)
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }
}
