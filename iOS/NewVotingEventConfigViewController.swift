//
//  NewVotingEventConfigViewController.swift
//  DALI Lab
//
//  Created by John Kotz on 8/24/17.
//  Copyright © 2017 BrunchLabs. All rights reserved.
//

import Foundation
import UIKit
import DALI
import SCLAlertView

class NewVotingEventConfigViewController: UITableViewController {
	@IBOutlet weak var orderedSwitch: UISwitch!
	@IBOutlet weak var stepper: UIStepper!
	@IBOutlet weak var numSelectedLabel: UILabel!
	
	var event: DALIEvent!
	
	override func viewDidLoad() {
		self.title = event.name
		
		self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel,
                                                                target: self,
                                                                action: #selector(cancel))
		
		self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done,
                                                                 target: self,
                                                                 action: #selector(done))
	}
	
	@objc func cancel() {
		self.navigationController?.popViewController(animated: true)
	}
	
	@objc func done() {
        event.enableVoting(numSelected: Int(stepper.value), ordered: orderedSwitch.isOn)
            .mainThreadFuture.onSuccess(block: { (event) in
            self.event = event
            let viewControllers: [UIViewController] = self.navigationController!.viewControllers as [UIViewController]
            self.navigationController!.popToViewController(viewControllers[viewControllers.count - 3], animated: true)
        }).onFail(block: { (error) in
            SCLAlertView().showError("Encountered Error", subTitle: "\(error.localizedDescription)")
        })
	}
	
	@IBAction func stepperChanged(_ sender: UIStepper) {
		numSelectedLabel.text = "# Selected: \(Int(sender.value))"
	}
}
