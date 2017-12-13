//
//  OrderedVotingViewController.swift
//  DALI Lab
//
//  Created by John Kotz on 8/30/17.
//  Copyright © 2017 BrunchLabs. All rights reserved.
//

import Foundation
import UIKit
import DALI
import SCLAlertView

class OrderedVotingViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
	@IBOutlet weak var leftTableView: UITableView!
	@IBOutlet weak var orderedTableView: UITableView!
	
	var event: DALIEvent.VotingEvent!
	var options: [DALIEvent.VotingEvent.Option] = []
	static let ordinals = ["1st", "2nd", "3rd"]
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		orderedTableView.isEditing = true
		orderedTableView.delegate = self
		orderedTableView.dataSource = self
		leftTableView.delegate = self
		leftTableView.dataSource = self
		
		self.title = event.name
		
		self.update()
	}
	
	func update() {
		self.event.getOptions { (options, error) in
			if let options = options {
				self.options = options.sorted(by: { (option1, option2) -> Bool in
					return option1.name < option2.name
				})
				
				DispatchQueue.main.async {
					self.orderedTableView.reloadData()
				}
			}
		}
	}
	
	@IBAction func submit(_ sender: Any) {
		let wait = SCLAlertView(appearance: SCLAlertView.SCLAppearance(
			showCloseButton: false
		)).showWait("Submitting...", subTitle: "")
		
		event.submitVote(options: Array(options.prefix(upTo: event.config.numSelected))) { (success, error) in
			DispatchQueue.main.async {
				wait.close()
				if success {
					self.performSegue(withIdentifier: "done", sender: nil)
				}else{
					SCLAlertView().showError("You already voted", subTitle: "")
				}
			}
		}
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if let dest = segue.destination as? HasVotedViewController {
			dest.event = event
			self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(self.pop))
		}
	}
	
	@objc func pop() {
		self.navigationController?.popToRootViewController(animated: true)
	}
	
	func scrollViewDidScroll(_ scrollView: UIScrollView) {
		if scrollView == orderedTableView {
			leftTableView.setContentOffset(scrollView.contentOffset, animated: false)
		}
	}
	
	func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
		return .none
	}
	
	func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
		return false
	}
	
	func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
		let movedObject = self.options[sourceIndexPath.row]
		options.remove(at: sourceIndexPath.row)
		options.insert(movedObject, at: destinationIndexPath.row)
		self.orderedTableView.reloadData()
	}
	
	func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
		return tableView == orderedTableView
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		if tableView == orderedTableView {
			let cell = UITableViewCell(style: .default, reuseIdentifier: "optionCell")
			
			cell.textLabel?.text = options[indexPath.row].name
			
			if indexPath.row < event.config.numSelected {
				cell.backgroundColor = UIColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1.0)
			}
			
			return cell
		}else{
			let cell = tableView.dequeueReusableCell(withIdentifier: "orderCell") as! VotingOrderCell
			
			if indexPath.row < OrderedVotingViewController.ordinals.count {
				cell.orderLabel?.text = OrderedVotingViewController.ordinals[indexPath.row]
			}else{
				cell.orderLabel?.text = "\(indexPath.row)th"
			}
			
			return cell
		}
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if tableView == leftTableView {
			return event.config.numSelected
		}else{
			return options.count
		}
	}
}

class VotingOrderCell: UITableViewCell {
	@IBOutlet weak var orderLabel: UILabel!
	
}
