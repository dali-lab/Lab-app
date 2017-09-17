//
//  ServerCommunicator.swift
//  DALISwift
//
//  Created by John Kotz on 7/5/17.
//  Copyright © 2017 DALI Lab. All rights reserved.
//

import Foundation
import DALI

class ServerCommunicator {
	static var current: ServerCommunicator?
	var backgroundTask: UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid
	var refreshTimer: Timer?
	var backgroundTaskNumFires = 0
	
	func registerBackgroundTask() {
		backgroundTaskNumFires = 0
		backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
			self?.endBackgroundTask()
		}
		assert(backgroundTask != UIBackgroundTaskInvalid)
	}
	
	func endBackgroundTask() {
		print("Background task ended.")
		UIApplication.shared.endBackgroundTask(backgroundTask)
		backgroundTask = UIBackgroundTaskInvalid
	}
	
	/**
		Initializes the communicator
	*/
	init() {
		if ServerCommunicator.current != nil {
			fatalError("Tried to make more than one server communicator!")
		}
		ServerCommunicator.current = self
		
		NotificationCenter.default.addObserver(self, selector: #selector(ServerCommunicator.enterExitDALI(notification:)), name: Notification.Name.Custom.EnteredOrExitedDALI, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(ServerCommunicator.enterExitCheckIn(notification:)), name: Notification.Name.Custom.CheckInEnteredOrExited, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(ServerCommunicator.timsOfficeEnterExit(notification:)), name: Notification.Name.Custom.TimsOfficeEnteredOrExited, object: nil)
	}
	
	/**
	Responds to the given notification about entering or exiting Tim's office. Posts to the server to let it know
	
	- Parameters:
		- notification: Notification - The notification that triggered the call
	*/
	@objc func timsOfficeEnterExit(notification: Notification) {
		guard let user = GIDSignIn.sharedInstance().currentUser else {
			return
		}
		
		let entered = (notification.userInfo?["entered"] as? Bool) ?? false
		if !userIsTim(user: user) {
			return
		}
		
		DALILocation.Tim.submit(inDALI: BeaconController.current!.inDALI, inOffice: entered) { (success, error) in
			if let error = error {
				print("Encountered error submitting for tim's office: \(error)")
			}
		}
	}
	
	/**
	Responds to the given notification about entering or exiting the check-in range. Posts to the server to let it know
	
	- Parameters:
		- notification: Notification - The notification that triggered the call
	*/
	@objc func enterExitCheckIn(notification: Notification) {
		guard GIDSignIn.sharedInstance().currentUser != nil else {
			return
		}
		
		let entered = (notification.userInfo?["entered"] as? Bool) ?? false
		let major = (notification.userInfo?["major"] as! Int)
		let minor = (notification.userInfo?["minor"] as! Int)
		if !entered {
			return
		}
		
		DALIEvent.checkIn(major: major, minor: minor) { (success, error) in
			if let error = error {
				print("Encountered error checking in: \(error)")
			}
		}
	}
	
	/**
		Responds to the given notification about entering or exiting the lab. Posts to the server to let it know
	
	- Parameters:
		- notification: Notification - The notification that triggered the call
	*/
	@objc func enterExitDALI(notification: Notification) {
		guard let user = GIDSignIn.sharedInstance().currentUser else {
			return
		}
		
		let entered = (notification.userInfo?["entered"] as? Bool) ?? false
		
		if userIsTim(user: user) {
			DALILocation.Tim.submit(inDALI: entered, inOffice: BeaconController.current!.inOffice) { (success, error) in
				if let error = error {
					print("Encountered error submitting inDALI for tim: \(error)")
					UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalMinimum)
				}
			}
		}else {
			DALILocation.Shared.submit(inDALI: entered, entering: entered, callback: { (success, error) in
				if let error = error {
					print("Encountered error submitting inDALI: \(error)")
					UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalMinimum)
				}
			})
		}
	}
	
	func enterExitDALIFunc(inDALI: Bool, callback: @escaping (_ successs: Bool) -> Void) {
		if userIsTim(user: GIDSignIn.sharedInstance().currentUser) {
			DALILocation.Tim.submit(inDALI: inDALI, inOffice: BeaconController.current!.inOffice) { (success, error) in
				if let error = error {
					print("Encountered error submitting inDALI for tim: \(error)")
					callback(success)
				}
			}
		}else {
			DALILocation.Shared.submit(inDALI: inDALI, entering: inDALI, callback: { (success, error) in
				if let error = error {
					print("Encountered error submitting inDALI: \(error)")
					callback(success)
				}
			})
		}
	}
}
