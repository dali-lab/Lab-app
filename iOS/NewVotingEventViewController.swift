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
		
		self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add,
                                                                 target: self,
                                                                 action: #selector(NewVotingEventViewController.new))
	}
	
	@objc func new() {
		let newEventController = NewEventViewController(destination: self) { (success) in
			if success {
				self.updateData()
			}
		}
		let navController = UINavigationController(rootViewController: newEventController)
		navController.navigationBar.barTintColor = self.navigationController?.navigationBar.barTintColor
		navController.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
		navController.navigationBar.tintColor = self.navigationController?.navigationBar.tintColor
		navController.modalPresentationStyle = .formSheet
		navController.modalTransitionStyle = .coverVertical
		self.present(navController, animated: true, completion: nil)
	}
	
	func updateData() {
        DALIEvent.getFuture(includeHidden: true).mainThreadFuture.onSuccess { (events) in
            self.events.removeAll()
            self.events = events.filter({ (event) -> Bool in
                return event is DALIEvent.VotingEvent
            })
            self.tableView.reloadData()
        }.onFail { _ in
            // FIXME: handle error
        }
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let event = events[indexPath.row]
		
		self.performSegue(withIdentifier: "configure", sender: event)
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if let dest = segue.destination as? NewVotingEventConfigViewController {
			dest.event = sender as? DALIEvent
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
