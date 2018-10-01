//
//  CheckOutConfirmViewCells.swift
//  iOS
//
//  Created by John Kotz on 9/26/18.
//  Copyright © 2018 BrunchLabs. All rights reserved.
//

import Foundation
import DALI

class CheckOutConfirmViewTitleCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
}

class CheckOutConfirmViewCheckOutCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var dateRangeLabel: UILabel!
    
    private var _checkOutRecord: DALIEquipment.CheckOutRecord!
    var checkOutRecord: DALIEquipment.CheckOutRecord {
        get {
            return self._checkOutRecord
        }
        set {
            _checkOutRecord = newValue
            self.titleLabel.text = newValue.member.name
            
            let start = newValue.startDate
            let end = newValue.endDate ?? newValue.projectedEndDate!
            
            let sameYear = Calendar.current.component(.year, from: start) == Calendar.current.component(.year, from: end)
            let sameMonth = Calendar.current.component(.month, from: start) == Calendar.current.component(.month, from: end)
            
            // Formatters for the begining...
            let startFormatter = DateFormatter()
            startFormatter.dateFormat = "LLLL d"
            if (!sameYear) {
                startFormatter.dateFormat += ", yyyy"
            }
            
            // and end of the range
            let endFormatter = DateFormatter()
            endFormatter.dateFormat = "d, yyyy"
            if (!sameMonth) {
                endFormatter.dateFormat = "LLLL \(endFormatter.dateFormat!)"
            }
            
            // Put it all together
            var dateRangeString = ""
            dateRangeString += startFormatter.string(from: start)
            dateRangeString += " - "
            dateRangeString += endFormatter.string(from: end)
            
            self.dateRangeLabel.text = dateRangeString
        }
    }
}
