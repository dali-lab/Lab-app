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
				self.events = events.filter({ (event) -> Bool in
					return !event.votingEnabled
				})
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
		
		
		let startComponents = Calendar.current.dateComponents([.weekday, .hour, .minute], from: events[indexPath.row].start)
		let endComponents = Calendar.current.dateComponents([.weekday, .hour, .minute], from: events[indexPath.row].end)
		
		let weekdayStart = abvWeekDays[startComponents.weekday! - 1]
		let weekdayEnd = startComponents.weekday! != endComponents.weekday! ? abvWeekDays[endComponents.weekday! - 1] : nil
		
		let startHour = startComponents.hour! > 12 ? startComponents.hour! - 12 : startComponents.hour!
		let endHour = endComponents.hour! > 12 ? endComponents.hour! - 12 : endComponents.hour!
		
		let startMinute = startComponents.minute!
		let endMinute = endComponents.minute!
		
		let startDaytime = startHour >= 12
		let endDaytime = endHour >= 12
		
		let daytimeDifferent = startDaytime != endDaytime
		
		let startString = "\(startHour):\(startMinute  < 10 ? "0" : "")\(startMinute)\(daytimeDifferent ? " \(startDaytime ? "AM" : "PM")" : "")"
		let endString = "\(endHour):\(endMinute < 10 ? "0" : "")\(endMinute) \(endDaytime ? "AM" : "PM")"
		
		cell.detailTextLabel?.text = "\(weekdayStart) \(startString) - \(weekdayEnd == nil ? "" : weekdayEnd! + " ")\(endString)"
		
		return cell
	}
	
	override func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return events.count
	}
}
