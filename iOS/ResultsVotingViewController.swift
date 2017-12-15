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
	var awards: [(award: String, option: DALIEvent.VotingEvent.Option)] = []
	
	override func viewDidLoad() {
		event.getResults { (options, error) in
			if let options = options {
				let options2 = options.sorted(by: { (option1, option2) -> Bool in
					return option1.name < option2.name
				})
				
				self.options = options2.filter({ (option) -> Bool in
					return option.awards != nil && option.awards!.filter({ (string) -> Bool in
						return !string.isEmpty
					}).count > 0
				})
				
				for option in self.options {
					if let awards = option.awards {
						for award in awards {
							self.awards.append((award: award, option: option))
						}
					}
				}
				
				DispatchQueue.main.async {
					self.tableView.reloadData()
				}
			}
		}
		
		self.title = event.name + ": Awards"
		self.tableView.rowHeight = 40
		self.tableView.sectionHeaderHeight = 50
	}
	
	override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		let view = UITableViewHeaderFooterView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: tableView.sectionHeaderHeight))
		view.backgroundColor = UIColor.clear
		let label = UILabel()
		label.font = UIFont.boldSystemFont(ofSize: 34)
		label.text = awards[section].award
		label.sizeToFit()
		label.center = view.center
		label.frame.origin = CGPoint(x: 8, y: label.frame.origin.y + (section == 0 ? 10 : 0))
		view.addSubview(label)
		
		return view
	}
	
	override func numberOfSections(in tableView: UITableView) -> Int {
		return self.awards.count
	}
	
	override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		return tableView.sectionHeaderHeight + (section == 0 ? 10 : 0)
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return 1
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "awardCell")!
		
		cell.textLabel?.text = self.awards[indexPath.section].option.name
		
		return cell
	}
}
