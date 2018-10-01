//
//  DatePickerAlert.swift
//  iOS
//
//  Created by John Kotz on 9/26/18.
//  Copyright © 2018 BrunchLabs. All rights reserved.
//

import Foundation

func datePickerAlert(title: String, datePickerMode: UIDatePickerMode) -> (alert: UIAlertController, datePicker: UIDatePicker) {
    let datePicker = UIDatePicker()
    datePicker.datePickerMode = datePickerMode
    
    let alert = UIAlertController(title: "\(title)\n\n\n\n\n\n\n\n\n\n\n", message: nil, preferredStyle: .actionSheet)
    alert.view.addSubview(datePicker)
    
    NSLayoutConstraint.activate([
        datePicker.centerXAnchor.constraint(equalTo: alert.view.centerXAnchor),
        datePicker.bottomAnchor.constraint(equalTo: alert.view.bottomAnchor)
    ])
    
    return (alert, datePicker)
}
