//
//  ResultsVotingViewController.swift
//  DALI Lab
//
//  Created by John Kotz on 8/30/17.
//  Copyright © 2017 BrunchLabs. All rights reserved.
//

import Foundation
import UIKit
import DALI

class ResultsVotingViewController: UITableViewController {
	var event: DALIEvent.VotingEvent!
	var options: [DALIEvent.VotingEvent.Option] = []
	var awards: [(String, DALIEvent.VotingEvent.Option)] = []
	
	override func viewDidLoad() {
		event.getResults { (options, error) in
			if let options = options {
				self.options = options
				
				self.options.sort(by: { (option1, option2) -> Bool in
					return option1.name > option2.name
				})
				
				self.options.forEach({ (option) in
					option.awards?.forEach({ (award) in
						self.awards.append((award, option))
					})
				})
				
				DispatchQueue.main.async {
					self.tableView.reloadData()
				}
			}
		}
		
		self.title = event.name
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return awards.count
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = UITableViewCell(style: .value1, reuseIdentifier: "cell")
		
		cell.textLabel?.text = awards[indexPath.row].1.name
		cell.detailTextLabel?.text = awards[indexPath.row].0
		cell.selectionStyle = .none
		
		return cell
	}
}
