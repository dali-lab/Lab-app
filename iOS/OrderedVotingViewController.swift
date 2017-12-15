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
	static let ordinals = ["1st", "2nd", "3rd"]
	var selected: [DALIEvent.VotingEvent.Option?] = []
	var unselected: [DALIEvent.VotingEvent.Option] = []
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		orderedTableView.isEditing = true
		orderedTableView.delegate = self
		orderedTableView.dataSource = self
		leftTableView.delegate = self
		leftTableView.dataSource = self
		
		self.title = event.name
		
		selected = Array.init(repeating: nil, count: event.config.numSelected)
		
		self.update()
	}
	
	func update() {
		self.event.getOptions { (options, error) in
			if let options = options {
				self.unselected = options.sorted(by: { (option1, option2) -> Bool in
					return option1.name < option2.name
				})
				
				DispatchQueue.main.async {
					self.orderedTableView.reloadData()
				}
			}
		}
	}
	
	@IBAction func submit(_ sender: Any) {
		var numSelected = 0
		for x in self.selected {
			if x != nil {
				numSelected += 1
			}
		}
		
		if numSelected < event.config.numSelected {
			SCLAlertView().showError("Choose more", subTitle: "Please select options for each ordered space")
			return
		}
		
		let wait = SCLAlertView(appearance: SCLAlertView.SCLAppearance(
			showCloseButton: false
		)).showWait("Submitting...", subTitle: "")
		
		event.submitVote(options: Array(self.selected) as! [DALIEvent.VotingEvent.Option]) { (success, error) in
			DispatchQueue.main.async {
				wait.close()
				if success {
					self.performSegue(withIdentifier: "done", sender: nil)
				}else{
					SCLAlertView().showError("You already voted", subTitle: error?.localizedDescription ?? "")
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
		var destPath = destinationIndexPath
		if lastProposedDestination != nil {
			destPath = lastProposedDestination!
		}
		
		if sourceIndexPath.section == 0 && destPath.section == 0 && sourceIndexPath.row <= destPath.row {
			destPath = IndexPath(row: min(destPath.row + 1, self.selected.count - 1), section: 0)
		}
		
		if sourceIndexPath.section == 0 {
			if destPath.section == 0 {
				let movedObject = self.selected[sourceIndexPath.row]
				self.selected[sourceIndexPath.row] = self.selected[destPath.row]
				self.selected[destPath.row] = movedObject
			}else{
				let movedObject = self.selected[sourceIndexPath.row]!
				self.selected[sourceIndexPath.row] = nil
				self.unselected.insert(movedObject, at: destPath.row)
			}
		}else{
			if destPath.section == 1 {
				let movedObject = self.unselected[sourceIndexPath.row]
				self.unselected.remove(at: sourceIndexPath.row)
				self.unselected.insert(movedObject, at: destPath.row)
			}else{
				let movedObject = self.unselected[sourceIndexPath.row]
				self.unselected.remove(at: sourceIndexPath.row)
				if destPath.row > self.selected.count - 1 {
					var firstIndex: Int? = nil
					for i in 0...self.selected.count-1 {
						if self.selected[self.selected.count - 1 - i] == nil && firstIndex == nil {
							firstIndex = self.selected.count - 1 - i; break
						}
					}
					if firstIndex != nil {
						self.selected.remove(at: firstIndex!)
						self.selected.append(movedObject)
					}else{
						self.unselected.insert(movedObject, at: sourceIndexPath.row)
					}
				} else if self.selected[destPath.row] == nil {
					self.selected[destPath.row] = movedObject
				}else{
					self.unselected.insert(self.selected[destPath.row]!, at: sourceIndexPath.row)
					self.selected[destPath.row] = movedObject
				}
			}
		}
		
		lastProposedDestination = nil
		self.orderedTableView.reloadData()
	}
	
	var lastProposedDestination: IndexPath?
	func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
		lastProposedDestination = proposedDestinationIndexPath
		if sourceIndexPath.section == 0 {
			return sourceIndexPath
		}
		return IndexPath(row: proposedDestinationIndexPath.section == 1 ? proposedDestinationIndexPath.row : self.unselected.count - 1, section: 1)
	}
	
	func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
		return tableView == orderedTableView && [self.selected, self.unselected][indexPath.section][indexPath.row] != nil
	}
	
	func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		return section == 1 ? "   Options" : nil
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		if tableView == orderedTableView {
			if let option = (indexPath.section == 0 ? selected : unselected)[indexPath.row] {
				let cell = tableView.dequeueReusableCell(withIdentifier: "optionCell")!
				
				cell.textLabel?.text = option.name
				
				return cell
			}else{
				let cell = tableView.dequeueReusableCell(withIdentifier: "emptyCell")!
				return cell
			}
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
		if section == 0 {
			return event.config.numSelected
		}else{
			return unselected.count
		}
	}
	
	func numberOfSections(in tableView: UITableView) -> Int {
		return tableView == leftTableView ? 1 : 2
	}
}

class VotingOrderCell: UITableViewCell {
	@IBOutlet weak var orderLabel: UILabel!
	
}
