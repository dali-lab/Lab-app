//
//  DALIUIError.swift
//  iOS
//
//  Created by John Kotz on 5/22/19.
//  Copyright © 2019 BrunchLabs. All rights reserved.
//

import Foundation

/**
 An error occuring in the UI portion of the app
 */
open class DALIUIError {
    public enum Notifications: Error {
        case notificationsDisabled
        case notificationsDismissed
    }
}
