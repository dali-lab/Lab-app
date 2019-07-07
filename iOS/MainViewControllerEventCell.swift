//
//  EventCell.swift
//  iOS
//
//  Created by John Kotz on 7/7/19.
//  Copyright © 2019 BrunchLabs. All rights reserved.
//

import Foundation
import UIKit
import DALI

class MainViewControllerEventCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    
    var event: DALIEvent? {
        didSet {
            if let event = event {
                self.titleLabel.text = event.name
                self.locationLabel.text = event.location
                
                let startComponents = Calendar.current.dateComponents([.weekday, .hour, .minute], from: event.start)
                let endComponents = Calendar.current.dateComponents([.weekday, .hour, .minute], from: event.end)
                
                let weekdayStart = abvWeekDays[startComponents.weekday! - 1]
                let weekdayEnd = startComponents.weekday! != endComponents.weekday! ? abvWeekDays[endComponents.weekday! - 1] : nil
                
                var startHour = startComponents.hour! > 12 ? startComponents.hour! - 12 : startComponents.hour!
                startHour = startHour != 0 ? startHour : 12
                var endHour = endComponents.hour! > 12 ? endComponents.hour! - 12 : endComponents.hour!
                endHour = endHour != 0 ? endHour : 12
                
                let startMinute = startComponents.minute!
                let endMinute = endComponents.minute!
                
                let startDaytime = startHour >= 12
                let endDaytime = endHour >= 12
                
                let daytimeDifferent = startDaytime != endDaytime
                
                let startString = "\(startHour):\(startMinute  < 10 ? "0" : "")" +
                "\(startMinute)\(daytimeDifferent ? " \(startDaytime ? "AM" : "PM")" : "")"
                let endString = "\(endHour):\(endMinute < 10 ? "0" : "")\(endMinute) \(endDaytime ? "AM" : "PM")"
                
                self.timeLabel.text = "\(weekdayStart) \(startString) - \(weekdayEnd == nil ? "" : weekdayEnd! + " ")\(endString)"
            } else {
                self.titleLabel.text = ""
            }
        }
    }
}
