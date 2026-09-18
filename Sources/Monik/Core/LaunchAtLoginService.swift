//
//  LaunchAtLoginService.swift
//  DisplayCraft
//

import Foundation
import ServiceManagement

public class LaunchAtLoginService: ObservableObject {
    public static let shared = LaunchAtLoginService()
    
    @Published public var isEnabled: Bool {
        didSet {
            updateLaunchAtLogin(isEnabled)
        }
    }
    
    private init() {
        if #available(macOS 13.0, *) {
            self.isEnabled = SMAppService.mainApp.status == .enabled
        } else {
            self.isEnabled = UserDefaults.standard.bool(forKey: "launchAtLogin")
        }
    }
    
    private func updateLaunchAtLogin(_ enable: Bool) {
        UserDefaults.standard.set(enable, forKey: "launchAtLogin")
        if #available(macOS 13.0, *) {
            do {
                if enable {
                    if SMAppService.mainApp.status != .enabled {
                        try SMAppService.mainApp.register()
                    }
                } else {
                    if SMAppService.mainApp.status == .enabled {
                        try SMAppService.mainApp.unregister()
                    }
                }
            } catch {
                print("⚠️ LaunchAtLoginService error: \(error)")
            }
        }
    }
}
