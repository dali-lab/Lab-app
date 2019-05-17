//
//  DALI Regions.swift
//  iOS
//
//  Created by John Kotz on 5/15/19.
//  Copyright © 2019 BrunchLabs. All rights reserved.
//

import Foundation

/**
 A region monitored by the app
 */
public enum DALIRegion {
    /// Tim's Office
    case timsOffice
    /// The DALI Lab space
    case DALI
    /// An event nearby wants to let users check in
    case checkInEvent
    /// An event nearby wants to let users vote
    case votingEvent
    
    var notificationName: NSNotification.Name {
        switch self {
        case .checkInEvent: return Notification.Name.Custom.CheckInEnteredOrExited
        case .DALI: return Notification.Name.Custom.EnteredOrExitedDALI
        case .timsOffice: return Notification.Name.Custom.TimsOfficeEnteredOrExited
        case .votingEvent: return Notification.Name.Custom.EventVoteEnteredOrExited
        }
    }
}
