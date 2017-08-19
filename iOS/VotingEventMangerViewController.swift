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

class VotingEventManagerViewController: UITableViewController {
	
	var createEventCell: UITableViewCell!
	var events = [DALIEvent]()
	
	override func viewDidLoad() {
		
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
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
	}
}

class VotingEventCell: UITableViewCell {
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var subTitleLabel: UILabel!
	
	private var eventObj: DALIEvent?
	var event: DALIEvent? {
		get {
			return eventObj
		}
		set {
			self.eventObj = newValue
			
			self.titleLabel.text = newValue?.name
			self.subTitleLabel.text = newValue?.description
		}
	}
}
