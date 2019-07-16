//
//  UIColor+hex.swift
//  iOS
//
//  Created by John Kotz on 7/8/19.
//  Copyright © 2019 BrunchLabs. All rights reserved.
//

import Foundation

extension UIColor {
    convenience init(hex: String, alpha: CGFloat) {
        let scanner = Scanner(string: hex)
        scanner.scanLocation = 0
        
        var rgbValue: UInt64 = 0
        
        scanner.scanHexInt64(&rgbValue)
        
        let red = (rgbValue & 0xff0000) >> 16
        let green = (rgbValue & 0xff00) >> 8
        let blue = rgbValue & 0xff
        
        self.init(
            red: CGFloat(red) / 0xff,
            green: CGFloat(green) / 0xff,
            blue: CGFloat(blue) / 0xff, alpha: alpha
        )
    }
    
    func toHex() -> String {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        let rgb: Int = (Int)(red * 255)<<16 | (Int)(green * 255)<<8 | (Int)(blue * 255)<<0
        
        return NSString(format: "#%06x", rgb) as String
    }
}
