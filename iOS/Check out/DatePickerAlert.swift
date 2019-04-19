//
//  DatePickerAlert.swift
//  iOS
//
//  Created by John Kotz on 9/26/18.
//  Copyright © 2018 BrunchLabs. All rights reserved.
//

import Foundation
import UIKit

extension UIAlertController {
    func set(vc: UIViewController?, width: CGFloat? = nil, height: CGFloat? = nil) {
        guard let vc = vc else { return }
        setValue(vc, forKey: "contentViewController")
        if let height = height {
            vc.preferredContentSize.height = height
            preferredContentSize.height = height
        }
    }
}

extension UIAlertController {
    func addDatePicker(mode: UIDatePicker.Mode,
                       date: Date?,
                       minimumDate: Date? = nil,
                       maximumDate: Date? = nil,
                       action: DatePickerViewController.Action?) {
        let datePicker = DatePickerViewController(mode: mode,
                                                  date: date,
                                                  minimumDate: minimumDate,
                                                  maximumDate: maximumDate,
                                                  action: action)
        set(vc: datePicker, height: 217)
    }
}

final class DatePickerViewController: UIViewController {
    
    public typealias Action = (Date) -> Void
    
    fileprivate var action: Action?
    
    fileprivate lazy var datePicker: UIDatePicker = { [unowned self] in
        $0.addTarget(self, action: #selector(DatePickerViewController.actionForDatePicker), for: .valueChanged)
        return $0
        }(UIDatePicker())
    
    required init(mode: UIDatePicker.Mode,
                  date: Date? = nil,
                  minimumDate: Date? = nil,
                  maximumDate: Date? = nil,
                  action: Action?) {
        super.init(nibName: nil, bundle: nil)
        datePicker.datePickerMode = mode
        datePicker.date = date ?? Date()
        datePicker.minimumDate = minimumDate
        datePicker.maximumDate = maximumDate
        self.action = action
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        view = datePicker
    }
    
    @objc func actionForDatePicker() {
        action?(datePicker.date)
    }
    
    public func setDate(_ date: Date) {
        datePicker.setDate(date, animated: true)
    }
}
