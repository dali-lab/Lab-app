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
		label.font = UIFont.boldSystemFont(ofSize: 30)
		label.text = options[section].name
		label.sizeToFit()
		label.center = view.center
		view.addSubview(label)
		
		return view
	}
	
	override func numberOfSections(in tableView: UITableView) -> Int {
		return self.options.count
	}
	
	override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		return tableView.sectionHeaderHeight
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return self.options[section].awards?.count ?? 0
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "awardCell") as! VotingAwardCell
		
		cell.setAward(award: self.options[indexPath.section].awards![indexPath.row])
		
		return cell
	}
}

class VotingAwardCell: UITableViewCell {
	@IBOutlet weak var awardLabel: UILabel!
	
	func setAward(award: String) {
		self.awardLabel.text = award
	}
}
