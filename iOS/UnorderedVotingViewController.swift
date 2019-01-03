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
	var event: DALIEvent.VotingEvent!
	var options: [(DALIEvent.VotingEvent.Option, Bool)] = []
	var numSelected = 0
	
	override func viewDidLoad() {
        _ = event.getOptions().onSuccess { (options) in
            self.options.removeAll()
            
            let optionsOrdered = options.sorted(by: { (option1, option2) -> Bool in return option1.name < option2.name })
            self.options = optionsOrdered.map({ (option) -> (DALIEvent.VotingEvent.Option, Bool) in
                return (option, false)
            })
            self.tableView.reloadData()
        }
		
		title = event.name
		navigationController?.isToolbarHidden = false
		navigationController?.toolbar.barTintColor = #colorLiteral(red: 0, green: 0.4870499372, blue: 0.5501662493, alpha: 1)
	}
    
    override func viewWillAppear(_ animated: Bool) {
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
		var optionsToSubmit: [DALIEvent.VotingEvent.Option] = []
		
		for option in options {
			if option.1 {
				optionsToSubmit.append(option.0)
			}
		}
		
		if optionsToSubmit.count < event.config.numSelected {
			SCLAlertView().showError("Please select \(event.config.numSelected)", subTitle: "")
			return
		}
		
		let wait = SCLAlertView(appearance: SCLAlertView.SCLAppearance(
			showCloseButton: false
		)).showWait("Submitting...", subTitle: "")
		
        event.submitVote(options: optionsToSubmit).mainThreadFuture.onSuccess { (_) in
            wait.close()
            self.performSegue(withIdentifier: "done", sender: nil)
        }.onFail { (error) in
            SCLAlertView().showError("Encountered an error", subTitle: "\(error.localizedDescription)")
        }
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return options.count
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = UITableViewCell(style: .default, reuseIdentifier: "cell")
		
		cell.textLabel?.text = options[indexPath.row].0.name
		cell.accessoryType = options[indexPath.row].1 ? .checkmark : .none
		
		cell.selectionStyle = numSelected >= event.config.numSelected && !options[indexPath.row].1 ? .none : .gray
		
		return cell
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		if numSelected >= event.config.numSelected && !options[indexPath.row].1 {
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
