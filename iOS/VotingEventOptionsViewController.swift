//
//  VotingEventOptionsViewController.swift
//  DALI Lab
//
//  Created by John Kotz on 8/24/17.
//  Copyright © 2017 BrunchLabs. All rights reserved.
//

import Foundation
import UIKit
import DALI
import SCLAlertView
import OneSignal

class VotingEventOptionsViewController: UITableViewController {
	@IBOutlet weak var releaseButton: UIBarButtonItem!
	
	var event: DALIEvent.VotingEvent!
	var options: [DALIEvent.VotingEvent.Option] = []
	weak var delegate: VotingEventManagerViewController?
	
	override func viewDidLoad() {
		self.title = event.name
		
		releaseButton.isEnabled = !event.resultsReleased
		releaseButton.title = event.resultsReleased ? "Released" : "Release"
		
		self.options = options.sorted(by: { (option1, option2) -> Bool in
			return (option1.points ?? 0) > (option2.points ?? 0)
		})
		
		self.navigationController?.isToolbarHidden = false
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		self.navigationController?.isToolbarHidden = true
		if let index = delegate?.events.firstIndex(where: { (event) -> Bool in
			return event.id == self.event.id
		}) {
			delegate?.options[index] = options
		}
	}
	
	override func viewWillAppear(_ animated: Bool) {
        event.getUnreleasedResults().mainThreadFuture.onSuccess { (options) in
            self.options = options.sorted(by: { (option1, option2) -> Bool in
                return (option1.points ?? 0) > (option2.points ?? 0)
            })
            self.tableView.reloadData()
        }.onFail { _ in
            // TODO: Handle error
        }
	}
	
	override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
		return true
	}
	
	override func tableView(_ tableView: UITableView,
                            commit editingStyle: UITableViewCell.EditingStyle,
                            forRowAt indexPath: IndexPath) {
		if editingStyle == UITableViewCell.EditingStyle.delete {
			// handle delete (by removing the data from your array and updating the tableview)
            event.removeOption(option: self.options[indexPath.row]).mainThreadFuture.onSuccess { (_) in
                self.options.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .automatic)
            }.onFail { (error) in
                SCLAlertView().showError("Encountered error", subTitle: error.localizedDescription)
            }
		}
	}
	@IBAction func release(_ sender: UIBarButtonItem) {
		var awards = 0
		for option in options { awards += option.awards?.count ?? 0 }
		
		if awards == 0 {
			SCLAlertView().showError("Need One ☝️", subTitle: "Need at least one award to release the awards")
			return
		}
		
        event.release().onSuccess { (_) in
            sender.isEnabled = false
            sender.title = "Released"
        }.onFail { (_) in
            // TODO: Handle error
        }
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		if indexPath.row >= options.count {
			return tableView.dequeueReusableCell(withIdentifier: "addCell")!
		}
		
		let option = options[indexPath.row]
		
		let cell = tableView.dequeueReusableCell(withIdentifier: "optionCell") as! VotingOptionCell
		cell.titleLabel.text = option.name
		
		var string = ""
		var first = true
		
		for award in option.awards ?? [] {
			if !first {
				string += ", "
			}
			string += award
			first = false
		}
		
		cell.awardsLabel.text = string
		cell.scoreLabel.text = "\(option.points ?? 0)"
		
		return cell
	}
	
	func addAward(option optIndex: Int, textField: UITextField) {
		var option = self.options[optIndex]
		
		if option.awards == nil {
			option.awards = []
		}
		
		option.awards!.append(textField.text!)
		self.options[optIndex] = option
		
		let waitAlert = SCLAlertView(appearance: SCLAlertView.SCLAppearance(
			showCloseButton: false
		))
		let wait = waitAlert.showWait("Adding...", subTitle: "")
        
        self.event.saveResults(options: self.options).mainThreadFuture.onSuccess { (_) in
            self.tableView.reloadData()
        }.onFail { (error) in
            SCLAlertView().showError("Encountered error", subTitle: error.localizedDescription)
        }.onComplete { (_) in
            wait.close()
        }
		
		self.options[optIndex] = option
	}
	
	func removeAward(option optIndex: Int, award: String) {
		var option = self.options[optIndex]
		
		if let index = option.awards!.firstIndex(of: award) {
			option.awards!.remove(at: index)
			self.options[optIndex] = option
			
			let waitAlert = SCLAlertView(appearance: SCLAlertView.SCLAppearance(
				showCloseButton: false
			))
			let wait = waitAlert.showWait("Removing...", subTitle: "")
            
            self.event.saveResults(options: self.options).onSuccess { (_) in
                self.tableView.reloadData()
            }.onFail { (error) in
                SCLAlertView().showError("Encountered error", subTitle: error.localizedDescription)
            }.onComplete { (_) in
                wait.close()
            }
		}
	}
	
	func newOption(textField: UITextField) {
		let option = textField.text
		
        self.event.addOption(option: option!).onSuccess { (_) in
            return self.event.getOptions().mainThreadFuture
        }.onSuccess { (options) in
            self.options = options
            self.tableView.reloadData()
        }.onFail { (error) in
            SCLAlertView().showError("Encountered error", subTitle: "\(error.localizedDescription)")
        }
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
		
		if indexPath.row >= options.count {
			let appearance = SCLAlertView.SCLAppearance(
				showCloseButton: false
			)
			
			let alert = SCLAlertView(appearance: appearance)
			let textFeild = alert.addTextField()
			
			alert.addButton("Add", action: { 
				self.newOption(textField: textFeild)
			})
			
			alert.addButton("Cancel", action: {
			})
			
			alert.showEdit("New Option", subTitle: "")
		} else {
			func addAwardAlert() {
				let alert = SCLAlertView()
				let textField = alert.addTextField()
				
				alert.addButton("Add award", action: {
					if textField.text?.isEmpty ?? false {
						let error = SCLAlertView(appearance: SCLAlertView.SCLAppearance.init(showCloseButton: false))
						error.addButton("Okay", action: {
							addAwardAlert()
						})
						error.showError("Need at least one character", subTitle: "")
						return
					}
					textField.resignFirstResponder()
					
					self.addAward(option: indexPath.row, textField: textField)
				})
				
				alert.showEdit("Add award", subTitle: "Add an award to '\(self.options[indexPath.row].name)'")
			}
			
			if let awards = options[indexPath.row].awards {
				let whatToDoAlert = SCLAlertView()
				whatToDoAlert.addButton("Add award", action: addAwardAlert)
				
				whatToDoAlert.addButton("Remove award", action: {
					let alert = SCLAlertView(appearance: SCLAlertView.SCLAppearance(showCloseButton: false))
					
					for award in awards {
						alert.addButton("\(award)", action: { 
							self.removeAward(option: indexPath.row, award: award)
						})
					}
					
					alert.addButton("Cancel", action: { 
						
					})
					
					alert.showEdit("Remove which award?", subTitle: "Which award do you want to remove")
				})
				
				whatToDoAlert.showInfo("What to do?", subTitle: "What do you want to do?")
			} else {
				addAwardAlert()
			}
		}
	}
	
	override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		if indexPath.row >= options.count {
			return 57
		}
		
		let label = UILabel(frame: CGRect(x: 0, y: 0, width: self.view.frame.width - 42, height: 1000))
		var string = ""
		var first = true
		
		for award in self.options[indexPath.row].awards ?? [] {
			if !first {
				string += ", "
			}
			string += award
			first = false
		}
		
		label.text = string
		label.font = UIFont.systemFont(ofSize: 14)
		label.sizeToFit()
		
		return label.frame.height + 40
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return options.count + 1
	}
	
	override func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}
}

class VotingOptionCell: UITableViewCell {
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var scoreLabel: UILabel!
	@IBOutlet weak var awardsLabel: UILabel!
}
