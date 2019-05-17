//
//  BeaconController.swift
//  dali
//
//  Created by John Kotz on 7/1/17.
//  Copyright © 2017 Facebook. All rights reserved.
//

import Foundation
import ProximityKit
import GoogleSignIn
import DALI

/**
 Handles all beacon activity for the application. It tracks at all times, even in the background,
 the beacon's nearby to get an accurate understanding of position

Functions:
 -

Properties:
- currentLocation: String?
	Generated property
 */
class BeaconController: NSObject, RPKManagerDelegate, CLLocationManagerDelegate {
    static var shared: BeaconController {
        return current ?? BeaconController()
    }
	static var current: BeaconController?
    
	var beaconManager: RPKManager = RPKManager()
	var locationManager = CLLocationManager()
	
	var backgroundTask: UIBackgroundTaskIdentifier = UIBackgroundTaskIdentifier.invalid
	func registerBackgroundTask(_ callback: () -> Void) {
		print("Registering for background...")
		backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
			print("Force killing...")
			self?.endBackgroundTask()
		}
		assert(backgroundTask != UIBackgroundTaskIdentifier.invalid)
		print("Background task begun...")
		callback()
	}
	
	func endBackgroundTask() {
		if backgroundTask == UIBackgroundTaskIdentifier.invalid {
			return
		}
		UIApplication.shared.endBackgroundTask(convertToUIBackgroundTaskIdentifier(backgroundTask.rawValue))
		backgroundTask = UIBackgroundTaskIdentifier.invalid
		print("Background task ended.")
	}
	
	var numToRange = 0
	
	private var rangeDone: (() -> Void)?
	private var ranged: Set<RPKBeacon> = []
	private var targetRegion: RPKRegion?
	private var onRange: (() -> Void)?
	
	var refreshTimers = [RPKRegion: Timer]()
	
	var currentLocation: String? {
		let region = regions.filter({ region in
            return (Int(region.attributes["locationPriority"] as! String))! > 0
        }).sorted(by: { (region1, region2) -> Bool in
            let region1Priority = Int(region1.attributes["locationPriority"] as! String)
            let region2Priority = Int(region2.attributes["locationPriority"] as! String)
			return region1Priority! > region2Priority!
		}).first
        
        return region?.name.replacingOccurrences(of: " Region", with: "").replacingOccurrences(of: "\\", with: "")
	}
	
	var inDALI: Bool {
		return regions.filter({ (region) -> Bool in
			return region.name == "DALI Lab Region"
		}).count >= 1
	}
	var inOffice: Bool {
		return regions.filter({ (region) -> Bool in
			return region.name == "Tims Office Region"
		}).count >= 1
	}
	var inVotingEvent: Bool {
		return regions.filter({ (region) -> Bool in
			return region.name == "Event Vote Region"
		}).count >= 1
	}
	
	private var regions = Set<RPKRegion>()
	
	override init() {
		super.init()
		
		do {
			try self.staticSetup()
		} catch {
			fatalError("Already have one!")
		}
		
		self.beaconManager = RPKManager(delegate: self, andConfig: [
			"kit_url": "https://proximitykit.radiusnetworks.com/api/kits/9339",
			"api_token": "753b54a6bf172823b68c10c9966c4d6da40ff85f57ef65ad0e155fcb40d0ccb2",
			"allow_cellular_data": true
			])
		
		updateLocation()
	}
	
	func breakdown() {
		BeaconController.current = nil
		
		self.beaconManager.stopRangingIBeacons()
		self.beaconManager.stopAdvertising()
		self.beaconManager.stop()
		
        if UIApplication.shared.applicationState == .background {
            registerBackgroundTask {
                if userIsTim() {
                    _ = DALILocation.Tim.submit(inDALI: false, inOffice: false).onSuccess { (_) in
                        self.endBackgroundTask()
                    }
                } else if DALIapi.isSignedIn {
                    _ = DALILocation.Shared.submit(inDALI: false, entering: false).onSuccess(block: { (_) in
                        self.endBackgroundTask()
                    })
                }
            }
        } else {
            if userIsTim() {
                _ = DALILocation.Tim.submit(inDALI: false, inOffice: false).onSuccess { (_) in
                    self.endBackgroundTask()
                }
            } else if DALIapi.isSignedIn {
                _ = DALILocation.Shared.submit(inDALI: false, entering: false).onSuccess { (_) in
                    self.endBackgroundTask()
                }
            }
        }
		
		if UIApplication.shared.applicationState != .background {
			NotificationCenter.default.post(name: Notification.Name.Custom.EnteredOrExitedDALI,
                                            object: nil,
                                            userInfo: ["entered": false])
			NotificationCenter.default.post(name: Notification.Name.Custom.EventVoteEnteredOrExited,
                                            object: nil, userInfo: ["entered": false])
			NotificationCenter.default.post(name: Notification.Name.Custom.TimsOfficeEnteredOrExited,
                                            object: nil,
                                            userInfo: ["entered": false])
		}
	}
	
	func updateLocation() {
		self.beaconManager.start()
		// A good buffer to find all the beacons possible
		numToRange = 50
		self.beaconManager.startRangingBeacons()
	}
	
	func updateLocation(with callback: @escaping (BeaconController) -> Void) {
		updateLocation()
		rangeDone = {
			callback(self)
			self.rangeDone = nil
		}
	}
	
	func proximityKit(_ manager: RPKManager!, didDetermineState state: RPKRegionState, for region: RPKRegion!) {
		var entered = false
		var exited = false
		if state == .inside {
			entered = regions.insert(region!).inserted
		} else {
			exited = regions.remove(region!) != nil
		}
		
		if region.name == "DALI Lab Region", exited || entered {
			func go(background: Bool) {
				if userIsTim() {
                    _ = DALILocation.Tim.submit(inDALI: entered, inOffice: entered ? false : inOffice).onSuccess { _ in
                        if background {
                            self.endBackgroundTask()
                        }
                    }
				} else if DALIapi.isSignedIn {
                    _ = DALILocation.Shared.submit(inDALI: entered, entering: entered).onSuccess { (_) in
                        if background {
                            self.endBackgroundTask()
                        }
                    }
				}
			}
			
			if UIApplication.shared.applicationState == .background {
				registerBackgroundTask {
					if UserDefaults.standard.bool(forKey: "inDALI") != entered {
						AppDelegate.shared.enterExitHappened(entered: entered)
					}
					UserDefaults.standard.set(entered, forKey: "inDALI")
					go(background: true)
				}
			} else {
				go(background: false)
				UserDefaults.standard.set(entered, forKey: "inDALI")
				NotificationCenter.default.post(name: Notification.Name.Custom.EnteredOrExitedDALI,
                                                object: nil,
                                                userInfo: ["entered": entered])
			}
		} else if region.name.replacingOccurrences(of: "'", with: "") == "Tims Office Region" && userIsTim() {
			if UIApplication.shared.applicationState == .background {
				registerBackgroundTask {
                    _ = DALILocation.Tim.submit(inDALI: inDALI, inOffice: entered).onSuccess { (_) in
                        self.endBackgroundTask()
                    }
				}
			} else {
				if entered || exited {
					_ = DALILocation.Tim.submit(inDALI: entered ? false : inDALI, inOffice: entered)
				}
				NotificationCenter.default.post(name: Notification.Name.Custom.TimsOfficeEnteredOrExited,
                                                object: nil,
                                                userInfo: ["entered": entered])
			}
		} else if region.name == "Event Vote Region", entered {
			if UIApplication.shared.applicationState == .background {
				registerBackgroundTask {
					AppDelegate.shared.votingEventEnteredOrExited {
						self.endBackgroundTask()
					}
				}
			} else {
				NotificationCenter.default.post(name: Notification.Name.Custom.EventVoteEnteredOrExited,
                                                object: nil,
                                                userInfo: ["entered": entered])
			}
		} else if region.name == "Check In Region", entered {
			if UIApplication.shared.applicationState == .background {
				registerBackgroundTask {
					rangeCheckin(region: region)
				}
			} else {
				rangeCheckin(region: region)
			}
		}
		
		NotificationCenter.default.post(name: NSNotification.Name.Custom.LocationUpdated, object: nil)
	}
	
	deinit {
		self.beaconManager.stopRangingIBeacons()
		self.beaconManager.stopAdvertising()
		self.beaconManager.stop()
	}
	
	private func staticSetup() throws {
		if BeaconController.current != nil {
            throw BeaconError.duplicateController
		}
		BeaconController.current = self
	}
	
	func proximityKit(_ manager: RPKManager, didEnter region: RPKRegion) {
		print("Entered Region \(region.name ?? "unknown name"), \(region.identifier ?? "unknown id")")
	}
	
	func persistantRange(callback: @escaping (BeaconController) -> Void) -> () -> Void {
		numToRange = -1
		
		self.beaconManager.start()
		self.beaconManager.startRangingBeacons()
		onRange = {
			callback(self)
		}
		
		return { () in
			self.numToRange = 0
			self.beaconManager.stopRangingIBeacons()
		}
	}
	
	private func rangeCheckin(region: RPKRegion) {
		numToRange = 15
		ranged.removeAll()
		targetRegion = region
		self.beaconManager.startRangingBeacons()
		rangeDone = { () in
			if let first = self.ranged.first {
				if UIApplication.shared.applicationState != .background {
					NotificationCenter.default.post(name: NSNotification.Name.Custom.CheckInEnteredOrExited,
                                                    object: nil,
                                                    userInfo: ["entered": true,
                                                               "major": first.major!,
                                                               "minor": first.minor!])
				}
                _ = DALIEvent.checkIn(major: first.major as! Int, minor: first.minor as! Int).onSuccess(block: { (_) in
                    if UIApplication.shared.applicationState == .background {
                        AppDelegate.shared.checkInHappened()
                        self.endBackgroundTask()
                    }
                })
			} else {
				// We are in fact not at a check in event
			}
		}
	}
	
	func proximityKit(_ manager: RPKManager, didExit region: RPKRegion) {
		print("Exited Region \(region.name ?? "unknown name"), \(region.identifier ?? "unknown id")")
	}
	
	func proximityKit(_ manager: RPKManager!, didRangeBeacons beacons: [Any]!, in region: RPKBeaconRegion!) {
		if numToRange <= 0 && numToRange != -1 {
			self.beaconManager.stopRangingIBeacons()
			return
		}
		
		numToRange -= 1
		if beacons.count == 0 && regions.contains(region) {
			// I am not going to deal with exits here. That will be the job of the exit region code
			return
		}
		
		if let targetRegion = targetRegion, targetRegion.identifier == region.identifier {
			for beacon in beacons as! [RPKBeacon] {
				ranged.insert(beacon)
			}
		}
		
		if let rangeDone = rangeDone, numToRange == 0 {
			rangeDone()
		}
		
		self.proximityKit(manager, didDetermineState: beacons.count > 0 ? .inside : .outside, for: region)
		if let onRange = onRange {
			onRange()
		}
	}
	
	enum BeaconError: Error {
		case duplicateController
	}
}

// Helper function inserted by Swift 4.2 migrator.
private func convertToUIBackgroundTaskIdentifier(_ input: Int) -> UIBackgroundTaskIdentifier {
	return UIBackgroundTaskIdentifier(rawValue: input)
}
