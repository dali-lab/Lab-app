//
//  HasVotedViewController.swift
//  DALI Lab
//
//  Created by John Kotz on 8/30/17.
//  Copyright © 2017 BrunchLabs. All rights reserved.
//

import Foundation
import UIKit
import DALI
import OneSignal

class HasVotedViewController: UIViewController {
	@IBOutlet weak var notificationSwitch: UISwitch!
	
	var event: DALIEvent!
	
	override func viewDidLoad() {
		self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(self.pop))
		
		UserDefaults.standard.set(true, forKey: "hasVoted:\(event.id)")
		notificationSwitch.isOn = UserDefaults.standard.value(forKey: "notifyFor:\(event.id)") as? Bool ?? true
		
		self.title = event.name
		
		OneSignal.sendTag("resultsReleased:\(event.id)", value: "\(notificationSwitch.isOn)")
	}
	
	@IBAction func switchChanged(_ sender: UISwitch) {
		UserDefaults.standard.set(sender.isOn, forKey: "notifyFor:\(event.id)")
		
		OneSignal.sendTag("resultsReleased:\(event.id)", value: "\(sender.isOn)")
	}
	
	func pop() {
		self.navigationController?.popToRootViewController(animated: true)
	}
}
