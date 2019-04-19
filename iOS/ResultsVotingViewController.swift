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
        _ = event.getResults().mainThreadFuture.onSuccess { (options) in
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
            
            self.tableView.reloadData()
        }
		
		self.title = event.name + ": Awards"
	}
	
	override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		if indexPath.row == 0 {
			return 50
		} else {
			return 40
		}
	}
	
	override func numberOfSections(in tableView: UITableView) -> Int {
		return self.awards.count
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return 2
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		if indexPath.row == 1 {
			let cell = tableView.dequeueReusableCell(withIdentifier: "optionCell")!
			
			cell.textLabel?.text = self.awards[indexPath.section].option.name
			cell.selectionStyle = .none
			
			return cell
		} else {
			let cell = tableView.dequeueReusableCell(withIdentifier: "awardCell")!
			
			cell.textLabel?.text = self.awards[indexPath.section].award
			cell.imageView?.image = #imageLiteral(resourceName: "ribbon")
			cell.selectionStyle = .none
			
			return cell
		}
	}
}
