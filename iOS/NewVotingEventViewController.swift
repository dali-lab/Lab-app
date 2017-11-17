//
//  CreateNewVotingEventViewController.swift
//  DALI Lab
//
//  Created by John Kotz on 8/24/17.
//  Copyright © 2017 BrunchLabs. All rights reserved.
//

import Foundation
import UIKit
import DALI

class NewVotingEventViewController: UITableViewController {
	
	var events: [DALIEvent] = []
	
	override func viewDidLoad() {
		self.updateData()
	}
	
	func updateData() {
		DALIEvent.getFuture { (events, error) in
			if let events = events {
				self.events.removeAll()
				for event in events {
					if event as? DALIEvent.VotingEvent == nil {
						self.events.append(event)
					}
				}
				self.tableView.reloadData()
			}
		}
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let event = events[indexPath.row]
		
		self.performSegue(withIdentifier: "configure", sender: event)
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if let dest = segue.destination as? NewVotingEventConfigViewController {
			dest.event = sender as! DALIEvent
		}
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "cell")!
		cell.textLabel?.text = events[indexPath.row].name
		
		let event = events[indexPath.row]
		let startFormatter = DateFormatter()
		startFormatter.dateStyle = .short
		startFormatter.timeStyle = .short
		
		let endFormatter = DateFormatter()
		endFormatter.dateStyle = .none
		endFormatter.timeStyle = .short
		
		cell.detailTextLabel?.text = "\(startFormatter.string(from: event.start)) - \(endFormatter.string(from: event.end))"
		
		return cell
	}
	
	override func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return events.count
	}
}
