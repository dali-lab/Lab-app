//
//  EnumsAndStructs.swift
//  DALISwift
//
//  Created by John Kotz on 7/5/17.
//  Copyright © 2017 Facebook. All rights reserved.
//

import Foundation
import SCLAlertView

let env = NSDictionary(contentsOfFile: Bundle.main.path(forResource: "PrivateInformation", ofType: "plist")!)! as! [String: Any]

extension Notification.Name {
	enum Custom {
		static let LocationUpdated = Notification.Name(rawValue: "LocationUpdated")
		static let CheckInComeplte  =  Notification.Name(rawValue: "CheckInComeplte")
		static let EnteredOrExitedDALI = Notification.Name(rawValue: "EnteredOrExitedDALI")
		static let CheckInEnteredOrExited = Notification.Name(rawValue: "CheckInEnteredOrExited")
		static let EventVoteEnteredOrExited = Notification.Name(rawValue: "EventVoteEnteredOrExited")
		static let TimsOfficeEnteredOrExited = Notification.Name(rawValue: "TimsOfficeEnteredOrExited")
	}
}

struct SharedUser {
	let email: String
	let name: String
}

struct Recurrence {
	enum Frequency: String {
		case weekly
		case daily
	}
	let frequency: Frequency
	let interval: Int?
	let periodData: [Int]?
	let rrule: String
	let until: Date?
}

struct VotingOption {
	
}

let abvWeekDays = ["Sun", "Mon", "Tues", "Wed", "Thurs", "Fri", "Sat"]

func userIsTim(user: GIDGoogleUser) -> Bool {
	return (env["tim"] as! String) == user.profile.email
}

func userIsAdmin(user: GIDGoogleUser) -> Bool {
	return (env["admins"] as! [String]).contains(user.profile.email)
}

var checkInRangeID: String {
	return env["checkInRangeID"] as! String
}

protocol AlertShower {
	func showAlert(alert: SCLAlertView, title: String, subTitle: String, color: UIColor, image: UIImage)
}

protocol ErrorAlertShower {
	func showError(alert: SCLAlertView, title: String, subTitle: String)
}
