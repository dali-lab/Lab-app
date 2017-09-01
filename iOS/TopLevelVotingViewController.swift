//
//  TopLevelVotingViewController.swift
//  DALI Lab
//
//  Created by John Kotz on 8/30/17.
//  Copyright © 2017 BrunchLabs. All rights reserved.
//

import Foundation
import UIKit
import DALI


class TopLevelVotingViewController: UITableViewController {
	var pastEvents: [DALIEvent] = []
	var currentEvent: DALIEvent?
	
	override func viewDidLoad() {
		self.updateData()
		
		self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "Events", style: .plain, target: nil, action: nil)
	}
	
	func updateData() {
		DALIEvent.Voting.getCurrent { (event, error) in
			self.currentEvent = event
			
			DispatchQueue.main.async {
				self.tableView.reloadData()
			}
		}
		
		DALIEvent.Voting.getReleasedEvents { (events, error) in
			if let events = events {
				self.pastEvents = events.sorted(by: { (event1, event2) -> Bool in
					return event1.start > event2.start
				})
				
				DispatchQueue.main.async {
					self.tableView.reloadData()
				}
			}
		}
	}
	
	@IBAction func cancel(_ sender: Any) {
		self.dismiss(animated: true) { 
			
		}
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		if indexPath.section == 0 && currentEvent != nil {
			let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
			
			let formatter = DateFormatter()
			formatter.dateStyle = .long
			
			cell.textLabel?.text = currentEvent?.name
			cell.detailTextLabel?.text = formatter.string(from: currentEvent!.start)
			cell.accessoryType = .disclosureIndicator
			
			return cell
		}
		
		let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
		
		let formatter = DateFormatter()
		formatter.dateStyle = .long
		
		cell.textLabel?.text = pastEvents[indexPath.row].name
		cell.detailTextLabel?.text = formatter.string(from: pastEvents[indexPath.row].start)
		cell.accessoryType = .disclosureIndicator
		
		return cell
	}
	
	override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		if section == 1 || currentEvent == nil {
			return "Past"
		}else{
			return "Now Voting"
		}
	}
	
	override func numberOfSections(in tableView: UITableView) -> Int {
		return currentEvent == nil ? 1 : 2
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if section == 0 && currentEvent != nil {
			return 1
		}else{
			return pastEvents.count
		}
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if let dest = segue.destination as? ResultsVotingViewController {
			dest.event = sender as! DALIEvent
		}else if let dest = segue.destination as? OrderedVotingViewController {
			dest.event = sender as! DALIEvent
		}else if let dest = segue.destination as? UnorderedVotingViewController {
			dest.event = sender as! DALIEvent
		}else if let dest = segue.destination as? HasVotedViewController {
			dest.event = sender as! DALIEvent
		}
	}
	
	override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return 70
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		if indexPath.section == 0 && currentEvent != nil {
			let hasVoted = UserDefaults.standard.bool(forKey: "hasVoted:\(currentEvent!.id)")
			let ordered = currentEvent!.votingConfig!.ordered
			
			if hasVoted {
				self.performSegue(withIdentifier: "showHasVoted", sender: currentEvent!)
			}else if ordered {
				self.performSegue(withIdentifier: "showOrderedVoting", sender: currentEvent!)
			}else{
				self.performSegue(withIdentifier: "showUnorderedVoting", sender: currentEvent!)
			}
		}else{
			self.performSegue(withIdentifier: "showPastEvent", sender: pastEvents[indexPath.row])
		}
	}
}
