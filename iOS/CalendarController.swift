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

class CalendarController: NSObject, EKCalendarChooserDelegate {
	static var current: CalendarController!
	let eventStore = EKEventStore()
	
	override init() {
		super.init()
		
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
	
	func calendarChooserDidCancel(_ calendarChooser: EKCalendarChooser) {
		
	}
	
	func calendarChooserSelectionDidChange(_ calendarChooser: EKCalendarChooser) {
		
	}
	
	func calendarChooserDidFinish(_ calendarChooser: EKCalendarChooser) {
		
	}
	
	func showCalendarChooser(on vc: UIViewController) {
		self.checkPermissions { (success) in
			if success {
				let eventView = EKCalendarChooser(selectionStyle: EKCalendarChooserSelectionStyle.single, displayStyle: EKCalendarChooserDisplayStyle.writableCalendarsOnly, entityType: EKEntityType.event, eventStore: self.eventStore)
				
				eventView.modalPresentationStyle = .popover
				
				DispatchQueue.main.async {
					vc.present(eventView, animated: true, completion: {
						
					})
				}
			}else{
				SCLAlertView().showError("Cant access calendar!", subTitle: "")
			}
		}
	}
}
