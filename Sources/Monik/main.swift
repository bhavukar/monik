//
//  main.swift
//  Monik
//

import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Set accessory policy (menu bar app, no dock icon)
        NSApp.setActivationPolicy(.accessory)
        
        // Initialize Core Services
        DisplayManager.shared.refreshDisplays()
        
        // Setup Menu Bar Extra
        MenuBarController.shared.setup()
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        SoftwareDimmer.shared.removeAll()
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
