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
            update()
        }
    }
    
    internal func update() {
        updateDateString()
        
        self.titleLabel.text = checkOutRecord.member.name
    }
    
    private func updateDateString() {
        let start = checkOutRecord.startDate
        let end = checkOutRecord.endDate
        
        let startYear = Calendar.current.component(.year, from: start)
        let thisYear = Calendar.current.component(.year, from: Date())
        let startSameAsThisYear = startYear == thisYear
        
        var sameYear = true
        var sameMonth = true
        if let end = end {
            sameYear = Calendar.current.component(.year, from: start) == Calendar.current.component(.year, from: end)
            sameMonth = Calendar.current.component(.month, from: start) == Calendar.current.component(.month, from: end)
        }
        
        // Formatters for the begining...
        let startFormatter = DateFormatter()
        startFormatter.dateFormat = "LLLL d"
        if !sameYear && !startSameAsThisYear {
            startFormatter.dateFormat += ", yyyy"
        }
        
        // Put it all together
        var dateRangeString = ""
        dateRangeString += startFormatter.string(from: start)
        if let end = end {
            let endYear = Calendar.current.component(.year, from: end)
            let endSameAsThisYear = endYear == thisYear
            
            // and end of the range
            let endFormatter = DateFormatter()
            endFormatter.dateFormat = "d"
            if !endSameAsThisYear {
                endFormatter.dateFormat += ", yyyy"
            }
            if !sameMonth {
                endFormatter.dateFormat = "LLLL \(endFormatter.dateFormat!)"
            }
            
            dateRangeString += " - "
            dateRangeString += endFormatter.string(from: end)
        }
        
        self.dateRangeLabel.text = dateRangeString
    }
}

class CheckOutConfirmViewCheckedOutCell: CheckOutConfirmViewCheckOutCell {
    @IBOutlet weak var expectedReturnLabel: UILabel!
    
    override func update() {
        super.update()
        
        if let expectEnd = checkOutRecord.expectedReturnDate {
            let formatter = DateFormatter()
            formatter.dateFormat = "LLLL d"
            if Calendar.current.component(.year, from: expectEnd) != Calendar.current.component(.year, from: Date()) {
                formatter.dateFormat += ", yyyy"
            }
            
            expectedReturnLabel.text = "Expected return date: \(formatter.string(from: expectEnd))"
        }
    }
}
