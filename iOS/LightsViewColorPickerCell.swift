//
//  Cell.swift
//  iOS
//
//  Created by John Kotz on 7/8/19.
//  Copyright © 2019 BrunchLabs. All rights reserved.
//

import Foundation
import UIKit
import ChromaColorPicker

class LightsViewColorPickerCell: UITableViewCell {
    var delegate: LightsViewColorPickerCellDelegate?
    var colorPicker: ChromaColorPicker!
    
    func setUp(color: UIColor?, delegate: LightsViewColorPickerCellDelegate) {
        if colorPicker == nil {
            colorPicker = ChromaColorPicker(frame: CGRect(x: 0, y: 0, width: 300, height: 300))
            self.addSubview(colorPicker)
        }
        if let color = color {
            colorPicker.adjustToColor(color)
        }
        colorPicker.center = self.center
        colorPicker.hexLabel.isHidden = true
        colorPicker.shadeSlider.isHidden = true
        colorPicker.addButton.isHidden = true
        colorPicker.handleLine.isHidden = true
        colorPicker.handleView.frame.size = CGSize(width: 60, height: 60)
        colorPicker.stroke = 30
        colorPicker.addTarget(self, action: #selector(LightsViewColorPickerCell.colorChanged(_:)), for: .editingDidEnd)
        colorPicker.frame.origin = CGPoint(x: colorPicker.frame.origin.x, y: 0)
        
        colorPicker.delegate = delegate
        colorPicker.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        self.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
    }
    
    @objc func colorChanged(_ sender: AnyObject?) {
        if let sender = sender as? ChromaColorPicker {
            delegate?.colorDidChange(to: sender.currentColor)
        }
    }
    
    func setColor(color: UIColor) {
        colorPicker.adjustToColor(color)
    }
}

protocol LightsViewColorPickerCellDelegate: ChromaColorPickerDelegate {
    func colorDidChange(to color: UIColor)
}
