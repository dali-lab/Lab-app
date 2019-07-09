//
//  BeaconController.swift
//  dali
//
//  Created by John Kotz on 7/1/17.
//  Copyright © 2017 Facebook. All rights reserved.
//

import Foundation
import CoreLocation
import GoogleSignIn
import DALI
import FutureKit
import Log
import EmitterKit

/**
 Handles all beacon activity for the application. It tracks at all times, even in the background,
 the beacon's nearby to get an accurate understanding of position

Functions:
 -

Properties:
- currentLocation: String?
	Generated property
 */
class BeaconController: NSObject, CLLocationManagerDelegate {
    static var _shared: BeaconController?
    static var shared: BeaconController {
        if _shared == nil {
            _shared = BeaconController()
        }
        return _shared!
    }
    let logger: Logger
    
	var locationManager = CLLocationManager()
	
	var backgroundTask: UIBackgroundTaskIdentifier = UIBackgroundTaskIdentifier.invalid
	
	var numToRange = 0
	
    let rangeEvent = Event<(beacons: [CLBeacon], region: DALIRegion)>()
    let locationChangedEvent = Event<String?>()
//    private var ranged: Set<RPKBeacon> = []
//    private var targetRegion: RPKRegion?
	
//    var refreshTimers = [RPKRegion: Timer]()
	
	var currentLocation: String? {
        return DALIRegion.highestPriority(in: regions)?.name
	}
	
    private var regions = Set<DALIRegion>()
	
    // MARK: - Basic data
    
	private override init() {
        logger = Logger()
		super.init()
        locationManager.delegate = self
		updateLocation()
	}
    
    deinit {
        dismantle(shouldSubmitLocation: false)
    }
    
    // MARK: - Statup and breakdown
    
    func assemble() {
        DALIRegion.all.forEach { (region) in
            self.locationManager.startMonitoring(for: region.region)
        }
    }
	
    func dismantle(shouldSubmitLocation: Bool = true) {
        self.stopRangingBeacons()
        DALIRegion.all.forEach { (region) in
            self.locationManager.stopMonitoring(for: region.region)
        }
        
        if shouldSubmitLocation {
            let submitLocation = { () -> Future<Any> in
                if userIsTim() {
                    return DALILocation.Tim.submit(inDALI: false, inOffice: false).futureAny
                } else if DALIapi.isSignedIn {
                    return DALILocation.Shared.submit(inDALI: false, entering: false).futureAny
                }
                return Future<Any>(cancelled: ())
            }
            
//            if UIApplication.shared.applicationState == .background {
//                registerBackgroundTask {
//                    submitLocation().onSuccess { (_) in
//                        self.endBackgroundTask()
//                    }.onFail { (error) in
//                        self.logger.error("Failed to submit dismantle location report to server in background", error)
//                    }
//                }
//            } else {
                // Submit to the server that we are leaving all places
                submitLocation().onFail { (error) in
                    self.logger.error("Failed to submit dismantle location report to server", error)
                }
                
                let package = ["entered": false]
                DALIRegion.all.forEach { (region) in
                    NotificationCenter.default.post(name: region.notificationName, object: nil, userInfo: package)
                    region.stateEvent.emit((change: .none, now: .outside))
                }
//            }
        }
	}
    
    // MARK: - API
    
    func startRangingBeacons() {
        DALIRegion.all.forEach { (region) in
            self.locationManager.startRangingBeacons(in: CLBeaconRegion(proximityUUID: region.uuid,
                                                                        identifier: region.rawValue))
        }
    }
    
    func stopRangingBeacons() {
        DALIRegion.all.forEach { (region) in
            self.locationManager.stopRangingBeacons(in: CLBeaconRegion(proximityUUID: region.uuid,
                                                                       identifier: region.rawValue))
        }
    }
	
	func updateLocation() {
		// A good buffer to find all the beacons possible
		numToRange = 50
        startRangingBeacons()
	}
	
	func updateLocation(with callback: @escaping (BeaconController) -> Void) {
		updateLocation()
        var listener: Listener?
        listener = rangeEvent.on { (_) in
            if self.numToRange == 0 {
                listener?.isListening = false
                callback(self)
            }
        }
	}
    
    func inside(_ region: DALIRegion) -> Bool {
        return regions.contains(region)
    }
    
    // MARK: - CLLocationManagerDelegate
    
    var seenDuringUpdate = Set<DALIRegion>()
    func locationManager(_ manager: CLLocationManager,
                         didRangeBeacons beacons: [CLBeacon],
                         in beaconRegion: CLBeaconRegion) {
        if numToRange <= 0 && numToRange != -1 {
            stopRangingBeacons()
            return
        }
        numToRange -= 1
        
        guard let region = DALIRegion.with(uuid: beaconRegion.proximityUUID) else {
            return
        }
        print("beacons in \(region): \(beacons.count)")
        if beacons.count > 0 {
            if seenDuringUpdate.insert(region).inserted {
                self.locationManager(self.locationManager, didDetermineState: .inside, for: beaconRegion)
            }
        }
        
        if numToRange == 0 {
            DALIRegion.all.forEach { (region) in
                let state: CLRegionState = seenDuringUpdate.contains(region) ? .inside : .outside
                self.locationManager(self.locationManager, didDetermineState: state, for: region.region)
            }
            seenDuringUpdate.removeAll()
        }
        
        rangeEvent.emit((beacons: beacons, region: region))
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        self.locationManager(manager, didDetermineState: .outside, for: region)
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        self.locationManager(manager, didDetermineState: .inside, for: region)
    }
    
    func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for clregion: CLRegion) {
        guard let beaconRegion = clregion as? CLBeaconRegion,
              let region = DALIRegion.with(uuid: beaconRegion.proximityUUID) else {
            return
        }
        var stateChange: DALIRegion.State.Change = .none
        if state == .inside {
            stateChange = regions.insert(region).inserted ? .entering : .none
        } else {
            stateChange = regions.remove(region) != nil ? .exiting : .none
        }
        let regionState = DALIRegion.State.from(state)

        func go() {
            region.emit(change: stateChange, state: regionState)
            
            if stateChange != .none {
                if userIsTim(), region == .DALI || region == .timsOffice {
                    var inDALI = regions.contains(.DALI)
                    var inOffice = regions.contains(.timsOffice)
                    
                    if inDALI && inOffice {
                        inDALI = region == .DALI
                        inOffice = region == .timsOffice
                    }

                    _ = DALILocation.Tim.submit(inDALI: inDALI, inOffice: inOffice)
                } else if region == .DALI {
                    _ = DALILocation.Shared.submit(inDALI: regionState == .inside,
                                               entering: stateChange == .entering)
                }
            }
        }
        
//        if UIApplication.shared.applicationState == .background {
//            registerBackgroundTask {
//                go()
//            }
//        } else {
            go()
            
            // TODO: Fix voting event
            NotificationCenter.default.post(name: NSNotification.Name.Custom.LocationUpdated, object: nil)
            locationChangedEvent.emit(currentLocation)
//        }
    }
    
    // MARK: - Background tasks
    
//    func registerBackgroundTask(_ callback: () -> Void) {
//        print("Registering for background...")
//        backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
//            print("Force killing...")
//            self?.endBackgroundTask()
//        }
//        assert(backgroundTask != UIBackgroundTaskIdentifier.invalid)
//        print("Background task begun...")
//        callback()
//    }
//
//    func endBackgroundTask() {
//        if backgroundTask == UIBackgroundTaskIdentifier.invalid {
//            return
//        }
//        UIApplication.shared.endBackgroundTask(backgroundTask)
//        backgroundTask = UIBackgroundTaskIdentifier.invalid
//        print("Background task ended.")
//    }
    
    // MARK: - Enums
	
	enum BeaconError: Error {
		case duplicateController
	}
}
