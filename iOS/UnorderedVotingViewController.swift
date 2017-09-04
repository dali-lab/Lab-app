//
//  UnorderedVotingViewController.swift
//  DALI Lab
//
//  Created by John Kotz on 8/30/17.
//  Copyright © 2017 BrunchLabs. All rights reserved.
//

import Foundation
import UIKit
import DALI
import SCLAlertView

class UnorderedVotingViewController: UITableViewController {
	var event: DALIEvent!
	var options: [(DALIEvent.Voting.Option, Bool)] = []
	var numSelected = 0
	
	override func viewDidLoad() {
		self.event.getOptions { (options, error) in
			if let options = options {
				self.options.removeAll()
				
				for option in options.sorted(by: { (option1, option2) -> Bool in return option1.name < option2.name }) {
					self.options.append((option, false))
				}
				
				DispatchQueue.main.async {
					self.tableView.reloadData()
				}
			}
		}
		
		self.title = event.name
		self.navigationController?.isToolbarHidden = false
		self.navigationController?.toolbar.barTintColor = #colorLiteral(red: 0, green: 0.4870499372, blue: 0.5501662493, alpha: 1)
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		self.navigationController?.isToolbarHidden = true
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if let dest = segue.destination as? HasVotedViewController {
			dest.event = event
		}
	}
	
	@IBAction func submit(_ sender: Any) {
		var optionsToSubmit: [DALIEvent.Voting.Option] = []
		
		for option in options {
			if option.1 {
				optionsToSubmit.append(option.0)
			}
		}
		
		if optionsToSubmit.count < event.votingConfig!.numSelected {
			SCLAlertView().showError("Please select \(event.votingConfig!.numSelected)", subTitle: "")
			return
		}
		
		let wait = SCLAlertView(appearance: SCLAlertView.SCLAppearance(
			showCloseButton: false
		)).showWait("Submitting...", subTitle: "")
		
		event.submitVotes(options: optionsToSubmit) { (success, error) in
			DispatchQueue.main.async {
				wait.close()
				if success {
					self.performSegue(withIdentifier: "done", sender: nil)
				}else{
					SCLAlertView().showError("Encountered an error", subTitle: "")
				}
			}
		}
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return options.count
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = UITableViewCell(style: .default, reuseIdentifier: "cell")
		
		cell.textLabel?.text = options[indexPath.row].0.name
		cell.accessoryType = options[indexPath.row].1 ? .checkmark : .none
		
		cell.selectionStyle = numSelected >= event.votingConfig!.numSelected && !options[indexPath.row].1 ? .none : .gray
		
		return cell
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		if numSelected >= event.votingConfig!.numSelected && !options[indexPath.row].1 {
			tableView.deselectRow(at: indexPath, animated: false)
			return
		}
		
		tableView.deselectRow(at: indexPath, animated: true)
		options[indexPath.row].1 = !options[indexPath.row].1
		if options[indexPath.row].1 {
			numSelected += 1
		}else{
			numSelected -= 1
		}
		
		tableView.reloadData()
	}
}
