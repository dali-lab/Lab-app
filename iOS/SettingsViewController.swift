//
//  SettingsViewController.swift
//  DALISwift
//
//  Created by John Kotz on 7/6/17.
//  Copyright © 2017 Facebook. All rights reserved.
//

import Foundation
import UIKit
import SCLAlertView
import DALI

class SettingsViewController: UITableViewController, AlertShower {
	@IBOutlet weak var signOutCell: UITableViewCell!
	@IBOutlet weak var enterSwitch: UISwitch!
	@IBOutlet weak var checkInSwitch: UISwitch!
	@IBOutlet weak var votingSwitch: UISwitch!
	@IBOutlet weak var shareSwitch: UISwitch!
	
	override func viewDidLoad() {
		let user = GIDSignIn.sharedInstance().currentUser
		signOutCell.textLabel?.text = user == nil ? "Sign In" : "Sign out"
		
		enterSwitch.isOn = SettingsController.getEnterExitNotif()
		checkInSwitch.isOn = SettingsController.getCheckInNotif()
		votingSwitch.isOn = SettingsController.getVotingNotif()
		shareSwitch.isOn = DALILocation.sharing
	}
	
	@IBAction func switchChanged(_ sender: UISwitch) {
		if sender != shareSwitch {
			// Then they switched a notification
			if sender.isOn {
				UserDefaults.standard.set(false, forKey: "noNotificationsSelected")
			}
			AppDelegate.shared.setUpNotificationListeners()
			
			SettingsController.set(sender.isOn, forKey: sender.accessibilityLabel!)
		} else {
			DALILocation.sharing = sender.isOn
		}
	}
	
	func showAlert(alert: SCLAlertView, title: String, subTitle: String, color: UIColor, image: UIImage) {
		let _ = alert.showCustom(title, subTitle: subTitle, color: color, icon: image)
	}
	
	override func numberOfSections(in tableView: UITableView) -> Int {
		let user = GIDSignIn.sharedInstance().currentUser
		if let user = user {
			return userIsAdmin(user: user) ? 4 : 3
		}else{
			return 1
		}
	}
	
	@IBAction func done(_ sender: Any) {
		self.navigationController?.dismiss(animated: true, completion: {
			
		})
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		if indexPath.section == 0 {
			// Sign out
			AppDelegate.shared?.signOut()
		}
	}
}

class SettingsController {
	private static let defaults = UserDefaults(suiteName: "Settings")!
	
	static func set(_ bool: Bool, forKey key: String) {
		defaults.set(bool, forKey: key)
	}
	
	static func getEnterExitNotif() -> Bool {
		return defaults.value(forKey: "enterExitNotification") != nil ? defaults.bool(forKey: "enterExitNotification") : false
	}
	
	static func getCheckInNotif() -> Bool {
		return defaults.value(forKey: "checkInNotification") != nil ? defaults.bool(forKey: "checkInNotification") : true
	}
	
	static func getVotingNotif() -> Bool {
		return defaults.value(forKey: "votingNotification") != nil ? defaults.bool(forKey: "votingNotification") : true
	}
	
	static func getSharePref() -> Bool {
		return defaults.value(forKey: "sharePreference") != nil ? defaults.bool(forKey: "sharePreference") : true
	}
}
