//
//  SettingsController.swift
//  iOS
//
//  Created by John Kotz on 5/22/19.
//  Copyright © 2019 BrunchLabs. All rights reserved.
//

import Foundation

/**
 Simple static class keeping track of settings using UserDefaults as a backend
 */
public class SettingsController {
    private static let defaults = UserDefaults(suiteName: "Settings")!
    
    /// Notifications for entering and exiting regions are enabled
    public static var enterExitNotificationsEnabled: Bool {
        get {
            return defaults.value(forKey: "enterExitNotification") as? Bool ?? false
        }
        set {
            defaults.set(newValue, forKey: "enterExitNotification")
        }
    }
    
    /// Notifications for checking into events are enabled
    public static var checkInNotificationsEnabled: Bool {
        get {
            return defaults.value(forKey: "checkInNotification") as? Bool ?? true
        }
        set {
            defaults.set(newValue, forKey: "checkInNotification")
        }
    }
    
    /// Notifications for voting events are enabled
    public static var votingNotificationsEnabled: Bool {
        get {
            return defaults.value(forKey: "votingNotification") as? Bool ?? true
        }
        set {
            defaults.set(newValue, forKey: "votingNotification")
        }
    }
}
