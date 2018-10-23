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
		
        self.title = event.name
        
        guard let id = event.id else {
            return
        }
		UserDefaults.standard.set(true, forKey: "hasVoted:\(id)")
		notificationSwitch.isOn = UserDefaults.standard.value(forKey: "notifyFor:\(id)") as? Bool ?? true
		
		OneSignal.sendTag("resultsReleased:\(id)", value: "\(notificationSwitch.isOn)")
	}
	
	@IBAction func switchChanged(_ sender: UISwitch) {
        guard let id = event.id else {
            return
        }
		UserDefaults.standard.set(sender.isOn, forKey: "notifyFor:\(id)")
		
		OneSignal.sendTag("resultsReleased:\(id)", value: "\(sender.isOn)")
	}
	
	@objc func pop() {
		self.navigationController?.popToRootViewController(animated: true)
	}
}
