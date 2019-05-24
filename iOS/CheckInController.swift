//
//  CheckInController.swift
//  iOS
//
//  Created by John Kotz on 5/24/19.
//  Copyright © 2019 BrunchLabs. All rights reserved.
//

import Foundation
import FutureKit
import CoreLocation
import EmitterKit
import DALI

/**
 Controller for the behavior of check in in the app
 */
public class CheckInController {
    private static var _shared: CheckInController?
    /// Shared instance of the check in controller
    public static var shared: CheckInController {
        if _shared == nil {
            _shared = CheckInController()
        }
        return _shared!
    }
    
    private var listener: Listener?
    private init() {}
    /// Dispose of this controller
    deinit { listener?.isListening = false }
    
    /**
     Setup the check in controller so it will opperate correctly when needed
     */
    public func setup() {
        listener = DALIRegion.checkInEvent.stateEvent.on { (tuple) in
            if tuple.change == .entering && tuple.now == .inside {
                self.checkIn()
            }
        }
    }
    
    /**
     The device entered a check in region. Check into whatever event has the nearby
     */
    public func checkIn() {
        self.checkCheckInBeacons().onSuccess { (tuples) in
            return FutureBatch(tuples.map { (tuple) in
                return DALIEvent.checkIn(major: tuple.major, minor: tuple.minor)
            }).future
        }.onSuccess { (_) in
            NotificationsController.shared.checkedInNotification()
        }.onFail { (_) in
            // FIXME: Handle this error
        }
    }
    
    /**
     Get all the beacons nearby that are within the check in region
     
     - returns: Future completed with list of major and minor values
     */
    private func checkCheckInBeacons() -> Future<[(major: Int, minor: Int)]> {
        let promise = Promise<[(major: Int, minor: Int)]>()
        
        BeaconController.shared.numToRange = 15
        BeaconController.shared.startRangingBeacons()
        var listener: Listener?
        listener = BeaconController.shared.rangeEvent.on { (range) in
            if range.region == .checkInEvent, BeaconController.shared.numToRange == 0 {
                guard range.beacons.count > 0 else {
                    promise.completeWithFail("No check in beacons found nearby")
                    return
                }
                
                let tuples = range.beacons.map { (beacon) in
                    return (beacon.major.intValue, beacon.minor.intValue)
                }
                promise.completeWithSuccess(tuples)
                BeaconController.shared.stopRangingBeacons()
                listener?.isListening = false
            }
        }
        
        return promise.future
    }
}
