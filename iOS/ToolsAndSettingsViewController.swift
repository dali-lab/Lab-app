//
//  ToolsAndSettingsViewController.swift
//  DALISwift
//
//  Created by John Kotz on 7/6/17.
//  Copyright © 2017 Facebook. All rights reserved.
//

import Foundation
import UIKit
import SCLAlertView
import DALI
import QRCodeReaderViewController

class ToolsAndSettingsViewController: UITableViewController, AlertShower, QRCodeReaderDelegate {
	@IBOutlet weak var signOutCell: UITableViewCell!
	@IBOutlet weak var enterSwitch: UISwitch!
	@IBOutlet weak var checkInSwitch: UISwitch!
	@IBOutlet weak var votingSwitch: UISwitch!
	@IBOutlet weak var shareSwitch: UISwitch!
	@IBOutlet weak var foodLabel: UILabel!
	
	override func viewDidLoad() {
		let user = GIDSignIn.sharedInstance().currentUser
		signOutCell.textLabel?.text = user == nil ? "Sign In" : "Sign out"
		
		enterSwitch.isOn = SettingsController.enterExitNotificationsEnabled
		checkInSwitch.isOn = SettingsController.checkInNotificationsEnabled
		votingSwitch.isOn = SettingsController.votingNotificationsEnabled
		shareSwitch.isOn = DALILocation.sharing
		
        _ = DALIFood.getFood().mainThreadFuture.onSuccess { (food) in
            self.foodLabel.text = food ?? "No Food Tonight"
        }
	}
	
	@IBAction func switchChanged(_ sender: UISwitch) {
		if sender != shareSwitch {
			// Then they switched a notification
			if sender.isOn {
				UserDefaults.standard.set(false, forKey: "noNotificationsSelected")
			}
			NotificationsController.shared.setUpNotificationListeners()
			
            switch sender {
            case checkInSwitch:
                SettingsController.checkInNotificationsEnabled = sender.isOn
            case votingSwitch:
                SettingsController.votingNotificationsEnabled = sender.isOn
            case enterSwitch:
                SettingsController.enterExitNotificationsEnabled = sender.isOn
            default:
                break
            }
		} else {
			DALILocation.sharing = sender.isOn
		}
	}
	
	func showAlert(alert: SCLAlertView, title: String, subTitle: String, color: UIColor, image: UIImage) {
        DispatchQueue.main.async {
            _ = alert.showCustom(title, subTitle: subTitle, color: color, icon: image)
        }
	}
	
	override func numberOfSections(in tableView: UITableView) -> Int {
		let user = GIDSignIn.sharedInstance().currentUser
		if user != nil {
			return DALIMember.current!.isAdmin ? 5 : 3
		} else {
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
        } else if indexPath.section == 3 {
			let alert = SCLAlertView()
			
			let textFeild = alert.addTextField()
			textFeild.text = foodLabel.text
			
			alert.addButton("Save", action: {
                DALIFood.setFood(food: textFeild.text!).mainThreadFuture.onSuccess(block: { (_) in
                    self.foodLabel.text = textFeild.text!
                }).onFail(block: { (error) in
                    SCLAlertView().showError("Encountered Error", subTitle: "\(error.localizedDescription)")
                })
			})
			
			alert.addButton("Cancel Food", action: { 
                DALIFood.cancelFood().mainThreadFuture.onSuccess(block: { (_) in
                    self.foodLabel.text = "No Food Tonight"
                }).onFail(block: { (error) in
                    SCLAlertView().showError("Encountered Error", subTitle: "\(error.localizedDescription)")
                })
			})
			
			alert.showEdit("Set food tonight", subTitle: "")
			
			tableView.deselectRow(at: indexPath, animated: true)
		}
	}
}
