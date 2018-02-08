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
	var pastEvents: [DALIEvent.VotingEvent] = []
	var currentEvent: DALIEvent.VotingEvent?
	var beaconControl: BeaconController {
		return BeaconController.current ?? BeaconController()
	}
	var persistantRangeEnd: (() -> Void)?
	
	override func viewDidLoad() {
		self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "Events", style: .plain, target: nil, action: nil)
		self.updateData()
	}
	
	override func viewWillAppear(_ animated: Bool) {
		persistantRangeEnd = beaconControl.persistantRange(callback: { (controller) in
			if controller.inVotingEvent {
				self.persistantRangeEnd!()
				self.persistantRangeEnd = nil
				self.updateData()
			}
		})
	}
	
	override func viewDidDisappear(_ animated: Bool) {
		if let persistantRangeEnd = persistantRangeEnd {
			persistantRangeEnd()
		}
	}
	
	func updateData() {
		if beaconControl.inVotingEvent {
			DALIEvent.VotingEvent.getCurrent { (event, error) in
				self.currentEvent = event
				if let event = event {
					event.haveVoted(callback: { (haveVoted, error) in
						UserDefaults.standard.set(haveVoted || UserDefaults.standard.bool(forKey:  "hasVoted:\(event.id)"), forKey: "hasVoted:\(event.id)")
					})
				}
				
				self.tableView.reloadData()
			}
		}
		
		NotificationCenter.default.addObserver(forName: Notification.Name.Custom.EventVoteEnteredOrExited, object: nil, queue: nil) { (notification) in
			if notification.userInfo?["entering"] as? Bool ?? false {
				DALIEvent.VotingEvent.getCurrent { (event, error) in
					self.currentEvent = event
					if let event = event {
						event.haveVoted(callback: { (haveVoted, error) in
							UserDefaults.standard.set(haveVoted || UserDefaults.standard.bool(forKey:  "hasVoted:\(event.id)"), forKey: "hasVoted:\(event.id)")
						})
					}
					self.tableView.reloadData()
				}
			}else{
				self.currentEvent = nil
				self.tableView.reloadData()
			}
		}
		
		DALIEvent.VotingEvent.getReleasedEvents { (events, error) in
			if let events = events {
				self.pastEvents = events.sorted(by: { (event1, event2) -> Bool in
					return event1.start > event2.start
				})
				self.tableView.reloadData()
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
			dest.event = sender as! DALIEvent.VotingEvent
		}else if let dest = segue.destination as? OrderedVotingViewController {
			dest.event = sender as! DALIEvent.VotingEvent
		}else if let dest = segue.destination as? UnorderedVotingViewController {
			dest.event = sender as! DALIEvent.VotingEvent
		}else if let dest = segue.destination as? HasVotedViewController {
			dest.event = sender as! DALIEvent.VotingEvent
		}
	}
	
	override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return 70
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
		if indexPath.section == 0 && currentEvent != nil {
			let hasVoted = UserDefaults.standard.bool(forKey: "hasVoted:\(currentEvent!.id)")
			let ordered = currentEvent!.config.ordered
			
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
