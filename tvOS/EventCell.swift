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
				descriptionLabel.text = newValue.desc == newValue.name && newValue.location != nil ? newValue.location : newValue.desc
				
				let calendar = Calendar.current
				
				let weekDayIndex = calendar.component(.weekday, from: newValue.start)
				let weekDay = EventCell.days[weekDayIndex - 1]
				let day = calendar.component(.day, from: newValue.start)
				let dayPostFix = EventCell.getDayPostfix(day: day)
				
				dateLabel.text = "\n\(weekDay) \(newValue.start.timeString())-\(newValue.end.timeString()), \(String(day) + dayPostFix)"
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
		let hours = Calendar.current.component(.hour, from: self)
		return "\(hours > 12 ? hours - 12 : hours)\(minutes != 0 ? ":\(minutes < 10 ? "0" : "")\(minutes)" : "") \(hours >= 12 && hours < 24 ? "PM" : "AM")"
	}
}
