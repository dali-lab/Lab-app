//
//  NewEventViewController.swift
//  iOS
//
//  Created by John Kotz on 12/14/17.
//  Copyright © 2017 BrunchLabs. All rights reserved.
//

import Foundation
import UIKit
import Eureka
import SCLAlertView
import DALI

class NewEventViewController: FormViewController {
	let completionHandler: (destination: UIViewController, callback: ((_ success: Bool)->Void)?)?
	var complete = false
	
	init(destination: UIViewController, callback: ((_ success: Bool)->Void)?) {
		completionHandler = (destination, callback)
		super.init(style: .grouped)
	}
	
	init() {
		completionHandler = nil
		super.init(style: .grouped)
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		title = "Create Event"
		
		let dateFormatter = DateFormatter()
		dateFormatter.dateStyle = .short
		dateFormatter.timeStyle = .short
		form +++ Section("General")
			<<< TextRow() { row in
				row.tag = "name"
				row.add(rule: RuleRequired())
				row.validationOptions = [.validatesOnChange]
				row.title = "Name"
				row.placeholder = "eg. Open Lab Hours"
			}.cellUpdate { cell, row in
				if !row.isValid {
					cell.titleLabel?.textColor = .red
				}
			}
			<<< TextRow() { row in
				row.tag = "location"
				row.add(rule: RuleRequired())
				row.validationOptions = [.validatesOnChange]
				row.title = "Location"
				row.placeholder = "eg. KAF"
			}.cellUpdate { cell, row in
				if !row.isValid {
					cell.titleLabel?.textColor = .red
				}
			}
		+++ Section("Description")
			<<< TextAreaRow() { row in
				row.tag = "description"
				row.title = "Description"
				row.placeholder = "eg. Members and non-members alike can come to this event..."
			}
		+++ Section("Timing")
			<<< DateTimeRow() { row in
				row.tag = "start"
				row.title = "Start time"
				row.add(rule: RuleRequired())
				row.validationOptions = [.validatesOnChange]
				row.dateFormatter = dateFormatter
				row.minimumDate = Date()
			}.cellUpdate { cell, row in
				if !row.isValid {
					cell.textLabel?.textColor = .red
				}
				(self.form.rowBy(tag: "end") as! DateTimeRow).minimumDate = row.value
			}
			<<< DateTimeRow() { row in
				row.tag = "end"
				row.title = "End time"
				row.add(rule: RuleRequired())
				let ruleRequiredViaClosure = RuleClosure<Date> { rowValue in
					if rowValue != nil && ((self.form.rowBy(tag: "start") as! DateTimeRow).value == nil || rowValue! > (self.form.rowBy(tag: "start") as! DateTimeRow).value!) {
						return nil
					}
					return ValidationError(msg: "End time must be later than start")
				}
				row.add(rule: ruleRequiredViaClosure)
				row.validationOptions = [.validatesOnChange]
				row.dateFormatter = dateFormatter
				row.minimumDate = Date()
			}.cellUpdate { cell, row in
				if !row.isValid {
					cell.textLabel?.textColor = .red
				}
			}
		+++ MultivaluedSection(multivaluedOptions: [.Insert, .Delete], header: "Tags", footer: "Tags allow users to subscribe to events with certain tags, so tag this with project names, topics, or description words") { section in
			section.addButtonProvider = { section in
				return ButtonRow() { button in
					button.title = "New tag"
				}
			}
			section.multivaluedRowToInsertAt = { index in
				return NameRow() { row in
					row.placeholder = "Tag name"
				}
			}
			section <<< NameRow() { row in
				row.placeholder = "Tag Name"
			}
		}
		
		self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(NewEventViewController.done))
		self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(NewEventViewController.dismissView))
	}
	
	@objc func dismissView() {
		self.dismiss(animated: true) {
			self.completionHandler?.callback?(self.complete)
		}
	}
	
	@objc func done() {
		let errors = form.validate(includeHidden: true)
		if errors.count > 0 {
			SCLAlertView().showError("Some errors", subTitle: "Please address the form errors")
			for row in form.allRows {
				if !row.isValid {
					row.baseCell.textLabel?.textColor = .red
				}
			}
			return
		}
		
		let start = (form.rowBy(tag: "start") as! DateTimeRow).value!
		let end = (form.rowBy(tag: "end") as! DateTimeRow).value!
		
		let event = DALIEvent(name: (form.rowBy(tag: "name") as! TextRow).value!,
							  description: (form.rowBy(tag: "description") as! TextAreaRow).value,
							  location: (form.rowBy(tag: "location") as! TextRow).value!,
							  start: start,
							  end: end)
        
        event.create().mainThreadFuture.onSuccess { (_) in
            self.dismissView()
        }.onFail { (error) in
            SCLAlertView().showError("Encountered error", subTitle: error.localizedDescription)
        }
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}
