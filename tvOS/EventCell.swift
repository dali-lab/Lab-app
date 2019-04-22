//
//  EventCell.swift
//  DALI Lab tvOS
//
//  Created by John Kotz on 6/6/17.
//  Copyright © 2017 Facebook. All rights reserved.
//

import Foundation
import UIKit
import DALI

class EventCell: UITableViewCell {
	@IBOutlet weak var nameLabel: UILabel!
	@IBOutlet weak var descriptionLabel: UILabel!
	@IBOutlet weak var dateLabel: UILabel!
	
	static let days = ["Sun", "Mon", "Tues", "Wed", "Thurs", "Fri", "Sat"]
	
	var event: DALIEvent? {
		set {
			if let newValue = newValue {
				nameLabel.text = newValue.name
                 if newValue.description == newValue.name && newValue.location != nil {
                    descriptionLabel.text = newValue.location
                } else {
                    descriptionLabel.text = newValue.description
                }
				
				let calendar = Calendar.current
				
				let weekDayIndex = calendar.component(.weekday, from: newValue.start)
				let weekDay = EventCell.days[weekDayIndex - 1]
				let day = calendar.component(.day, from: newValue.start)
				let dayPostFix = EventCell.getDayPostfix(day: day)
                let dayString = String(day) + dayPostFix
                let startString = newValue.start.timeString()
                let endString = newValue.end.timeString()
				
				dateLabel.text = "\n\(weekDay) \(startString)-\(endString), \(dayString)"
			}
		}
		get {
			return nil
		}
	}
	
	fileprivate static func getDayPostfix(day: Int) -> String {
		switch day {
		case 1:
			return "st"
		case 2:
			return "nd"
		case 3:
			return "rd"
		default:
			return "th"
		}
	}
}

extension Date {
	func timeString() -> String {
		let minutes = Calendar.current.component(.minute, from: self)
		var hours = Calendar.current.component(.hour, from: self)
		hours = hours != 0 ? hours : 12
        
        let hours12 = hours > 12 ? hours - 12 : hours
        let minutesString = minutes != 0 ? ":\(minutes < 10 ? "0" : "")\(minutes)" : ""
        let amPMString = hours >= 12 && hours < 24 ? "PM" : "AM"
		
		return "\(hours12)\(minutesString) \(amPMString)"
	}
}
