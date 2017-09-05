//
//  VotingEventMangerViewController.swift
//  DALISwift
//
//  Created by John Kotz on 7/8/17.
//  Copyright © 2017 Facebook. All rights reserved.
//

import Foundation
import UIKit
import DALI
import SwiftyJSON

class VotingEventManagerViewController: UITableViewController {
	
	var createEventCell: UITableViewCell!
	var events: [DALIEvent.VotingEvent] = []
	var options: [[DALIEvent.VotingEvent.Option]] = []
	
	override func viewDidLoad() {
		self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "Back", style: .plain, target: nil, action: nil)
	}
	
	override func viewDidAppear(_ animated: Bool) {
		self.updateData()
	}
	
	func updateData() {
		DALIEvent.VotingEvent.get { (events, error) in
			if let events = events {
				self.events = events
				
				for event in events {
					event.getUnreleasedResults(callback: { (options, error) in
						if let options = options {
							self.options.append(options)
						}
					})
				}
				
				DispatchQueue.main.async {
					self.tableView.reloadData()
				}
			}
		}
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		switch indexPath.section {
		case 0:
			let cell = tableView.dequeueReusableCell(withIdentifier: "createNewCell", for: indexPath)
			return cell
		case 1:
			let cell = tableView.dequeueReusableCell(withIdentifier: "eventCell", for: indexPath) as! VotingEventCell
			cell.event = events[indexPath.row]
			return cell
		default:
			print("Unknown number of sections")
			return UITableViewCell()
		}
	}
	
	override func numberOfSections(in tableView: UITableView) -> Int {
		return 2
	}
	
	override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		switch section {
		case 0:
			return "General"
		case 1:
			return "Events"
		default:
			return "Unknown number of sections"
		}
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		switch section {
		case 0:
			return 1
		case 1:
			return events.count
		default:
			print("Unknown number of sections")
			return 0
		}
	}
	
	override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		if indexPath.section == 1 {
			return 80
		}
		return 50
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if let dest = segue.destination as? VotingEventOptionsViewController {
			dest.event = events[sender as! Int]
			dest.options = options[sender as! Int]
		}
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
		
		if indexPath.section != 0 {
			self.performSegue(withIdentifier: "optionsEditor", sender: indexPath.row)
		}
	}
}

class VotingEventCell: UITableViewCell {
	
	private var eventObj: DALIEvent?
	var event: DALIEvent? {
		get {
			return eventObj
		}
		set {
			self.eventObj = newValue
			
			self.textLabel?.text = newValue?.name
			
			if let newValue = newValue {
				let startComponents = Calendar.current.dateComponents([.weekday, .hour, .minute], from: newValue.start)
				let endComponents = Calendar.current.dateComponents([.weekday, .hour, .minute], from: newValue.end)
				
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
				
				self.detailTextLabel?.text = "\(weekdayStart) \(startString) - \(weekdayEnd == nil ? "" : weekdayEnd! + " ")\(endString)"
			}
		}
	}
}
