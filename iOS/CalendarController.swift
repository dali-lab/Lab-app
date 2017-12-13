//
//  CalendarController.swift
//  DALISwift
//
//  Created by John Kotz on 7/12/17.
//  Copyright © 2017 Facebook. All rights reserved.
//

import Foundation
import EventKit
import EventKitUI
import SCLAlertView
import DALI

class CalendarController: NSObject, EKCalendarChooserDelegate {
	static var current: CalendarController!
	let eventStore = EKEventStore()
	var event : DALIEvent!
	
	let eventView: EKCalendarChooser
	let navControl: UINavigationController
	
	override init() {
		eventView = EKCalendarChooser(selectionStyle: EKCalendarChooserSelectionStyle.single, displayStyle: EKCalendarChooserDisplayStyle.writableCalendarsOnly, entityType: EKEntityType.event, eventStore: self.eventStore)
		navControl = UINavigationController(rootViewController: self.eventView)
		
		
		super.init()
		
		
		eventView.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(self.calendarChooserDidFinish))
		eventView.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(self.calendarChooserDidCancel))
		
		CalendarController.current = self
	}
	
	func checkPermissions(callback: ((Bool) -> Void)?) {
		let status = EKEventStore.authorizationStatus(for: EKEntityType.event)
		
		switch (status) {
		case EKAuthorizationStatus.notDetermined:
			// This happens on first-run
			self.requestPermissions(callback)
		case EKAuthorizationStatus.authorized:
			// Things are in line with being able to show the calendars in the table view
			if let callback = callback {
				callback(true)
			}
		case EKAuthorizationStatus.restricted, EKAuthorizationStatus.denied:
			// We need to help them give us permission
			if let callback = callback {
				callback(false)
			}
		}
	}
	
	func requestPermissions(_ callback: ((Bool) -> Void)?) {
		DispatchQueue.main.async {
			self.eventStore.requestAccess(to: EKEntityType.event, completion: {
				(accessGranted: Bool, error: Error?) in
				if let callback = callback {
					callback(accessGranted)
				}
			})
		}
	}
	
	@objc func calendarChooserDidCancel() {
		self.navControl.dismiss(animated: true) {}
	}
	
	@objc func calendarChooserDidFinish() {
		if (eventView.selectedCalendars.count == 0) {
			SCLAlertView().showError("Please select one", subTitle: "")
			return;
		}
		
		let event = EKEvent(eventStore: self.eventStore)
		
		event.title = self.event.name
		event.startDate = self.event.start
		event.endDate = self.event.end
		event.location = self.event.location
		event.notes = "\(self.event.description == nil ? "Description: \(self.event.description!)\n\n" : "")ID: \(self.event.id)"
		
		event.calendar = eventView.selectedCalendars.first!
		
		do {
			try eventStore.save(event, span: .thisEvent)
			
			self.navControl.dismiss(animated: true) {}
		} catch let error as NSError {
			print("failed to save event with error : \(error)")
			SCLAlertView().showError("Encountered error!", subTitle: error.localizedDescription)
		}
	}
	
	func showCalendarChooser(on vc: UIViewController) {
		self.checkPermissions { (success) in
			if success {
				
				self.navControl.modalPresentationStyle = .popover
				
				DispatchQueue.main.async {
					vc.present(self.navControl, animated: true, completion: {})
				}
			}else{
				SCLAlertView().showError("Cant access calendar!", subTitle: "You may have not allowed access to your calendar. Change this in your phone settings to put events on your calendar")
			}
		}
	}
}
