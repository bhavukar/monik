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
            if let img = NSImage(systemSymbolName: "display", accessibilityDescription: "Manage Your Display")?.withSymbolConfiguration(config) {
                img.isTemplate = true
                button.image = img
            }
            button.target = self
            button.action = #selector(statusBarButtonClicked(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        
        // Setup popover
        popover = NSPopover()
        popover.contentSize = NSSize(width: 360, height: 580)
        popover.behavior = .transient
        popover.delegate = self
        popover.contentViewController = NSHostingController(rootView: MonikPopoverView())
    }
    
    @objc private func statusBarButtonClicked(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent
        if event?.type == .rightMouseUp || (event?.modifierFlags.contains(.control) ?? false) {
            showContextMenu(button: sender)
        } else {
            togglePopover()
        }
    }
    
    private func showContextMenu(button: NSStatusBarButton) {
        closePopover()
        DisplayManager.shared.refreshDisplays()
        
        let menu = NSMenu()
        
        let headerItem = NSMenuItem(title: "Manage Your Display", action: nil, keyEquivalent: "")
        headerItem.isEnabled = false
        menu.addItem(headerItem)
        
        menu.addItem(NSMenuItem.separator())
        
        for display in DisplayManager.shared.displays {
            let desc = "\(display.name): \(display.currentResolution) @ \(Int(round(display.currentRefreshRate)))Hz\(display.isHiDPI ? " (HiDPI)" : "")"
            let item = NSMenuItem(title: desc, action: nil, keyEquivalent: "")
            item.isEnabled = false
            menu.addItem(item)
        }
        
        menu.addItem(NSMenuItem.separator())
        
        let fontSmoothingItem = NSMenuItem(title: "Fix Blurry Text (Enable Font Smoothing)", action: #selector(fixFontSmoothing), keyEquivalent: "")
        fontSmoothingItem.target = self
        menu.addItem(fontSmoothingItem)
        
        let restoreItem = NSMenuItem(title: "Restore All Displays (Crisp Modes & Gamma)", action: #selector(restoreDisplays), keyEquivalent: "")
        restoreItem.target = self
        menu.addItem(restoreItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let prefsItem = NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ",")
        prefsItem.target = self
        menu.addItem(prefsItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: "Quit Manage Your Display", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem.menu = menu
        button.performClick(nil)
        statusItem.menu = nil
    }
    
    @objc private func fixFontSmoothing() {
        DisplayManager.shared.enableMacFontSmoothing()
    }
    
    @objc private func restoreDisplays() {
        DisplayManager.shared.restoreAllDisplays()
    }
    
    @objc private func openSettings() {
        PreferencesWindowController.shared.show()
    }
    
    @objc public func quitApp() {
        NSApplication.shared.terminate(nil)
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
