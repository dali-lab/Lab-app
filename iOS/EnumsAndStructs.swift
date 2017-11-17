//
//  EnumsAndStructs.swift
//  DALISwift
//
//  Created by John Kotz on 7/5/17.
//  Copyright © 2017 Facebook. All rights reserved.
//

import Foundation
import SCLAlertView
import DALI

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

let abvWeekDays = ["Sun", "Mon", "Tues", "Wed", "Thurs", "Fri", "Sat"]
var signedIn: Bool {
	return DALIapi.isSignedIn
}

func userIsTim(user: GIDGoogleUser) -> Bool {
	return (env["tim"] as! String) == user.profile.email
}

func userIsTim(user: DALIMember? = DALIMember.current) -> Bool {
	if user == nil {
		return false
	}
	return (env["tim"] as! String) == user!.email
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
