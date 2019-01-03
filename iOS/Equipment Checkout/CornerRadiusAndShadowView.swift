//
//  CornerRadiusAndShadowView.swift
//  Auracle
//
//  Created by John Kotz on 11/5/18.
//  Copyright © 2018 DALI Lab. All rights reserved.
//

import Foundation
import UIKit

open class CornerRadiusAndShadowView: UIView {
    let shadowLayer = CAShapeLayer()
    let containerView: UIView
    
    @IBInspectable var cornerRadius: CGFloat = 0 {
        didSet {
            updateFrame()
        }
    }
    
    @IBInspectable var shadowColor: UIColor = UIColor.clear {
        didSet {
            shadowLayer.shadowColor = shadowColor.cgColor
        }
    }
    
    @IBInspectable var shadowOpacity: Float = 0.0 {
        didSet {
            shadowLayer.shadowOpacity = shadowOpacity
        }
    }
    
    @IBInspectable var shadowRadius: CGFloat = 0.0 {
        didSet {
            shadowLayer.shadowRadius = shadowRadius
        }
    }
    
    @IBInspectable var shadowOffset: CGSize = CGSize.zero {
        didSet {
            shadowLayer.shadowOffset = shadowOffset
        }
    }
    
    @IBInspectable var fillColor: UIColor = UIColor.white {
        didSet {
            shadowLayer.fillColor = fillColor.cgColor
        }
    }
    
    public override init(frame: CGRect) {
        containerView = UIView(frame: frame)
        super.init(frame: frame)
        self.backgroundColor = UIColor.clear
        
        super.addSubview(containerView)
        self.updateView()
    }
    
    open override func addSubview(_ view: UIView) {
        if view == containerView {
            super.addSubview(view)
        } else {
            if !containerView.isDescendant(of: self) {
                super.addSubview(containerView)
            }
            containerView.addSubview(view)
        }
    }
    
    open override func layoutSubviews() {
        self.containerView.frame = bounds
        super.layoutSubviews()
        self.updateView()
    }
    
    func updateView() {
        layer.insertSublayer(shadowLayer, at: 0)
        shadowLayer.shadowColor = shadowColor.cgColor
        shadowLayer.shadowOpacity = shadowOpacity
        shadowLayer.shadowRadius = shadowRadius
        shadowLayer.shadowOffset = shadowOffset
        shadowLayer.fillColor = fillColor.cgColor
        containerView.backgroundColor = UIColor.clear
        self.updateFrame()
    }
    
    func updateFrame() {
        containerView.frame = bounds
        containerView.layer.cornerRadius = cornerRadius
        containerView.clipsToBounds = true
        shadowLayer.path = UIBezierPath(roundedRect: bounds, cornerRadius: cornerRadius).cgPath
        shadowLayer.shadowPath = shadowLayer.path
    }
    
    public required init?(coder aDecoder: NSCoder) {
        self.cornerRadius = CGFloat(aDecoder.decodeFloat(forKey: "cornerRadius"))
        self.shadowColor = aDecoder.decodeColor(forKey: "shadowColor")
        self.shadowOpacity = aDecoder.decodeFloat(forKey: "shadowOpacity")
        self.shadowRadius = CGFloat(aDecoder.decodeFloat(forKey: "shadowRadius"))
        self.shadowOffset = aDecoder.decodeCGSize(forKey: "shadowOffset")
        self.fillColor = aDecoder.decodeColor(forKey: "fillColor")
        
        containerView = UIView(frame: CGRect.zero)
        super.init(coder: aDecoder)
        self.backgroundColor = UIColor.clear
        self.updateView()
    }
    
    open override func encode(with aCoder: NSCoder) {
        aCoder.encode(cornerRadius, forKey: "cornerRadius")
        aCoder.encode(shadowColor, forKey: "shadowColor")
        aCoder.encode(shadowOpacity, forKey: "shadowOpacity")
        aCoder.encode(shadowRadius, forKey: "shadowRadius")
        aCoder.encode(shadowOffset, forKey: "shadowOffset")
        aCoder.encode(fillColor, forKey: "fillColor")
    }
}

extension NSCoder {
    func encode(_ color: UIColor, forKey key: String) {
        var red : CGFloat = 0
        var green : CGFloat = 0
        var blue : CGFloat = 0
        var alpha: CGFloat = 0
        
        if color.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
            encode(red, forKey: "\(key)-red")
            encode(green, forKey: "\(key)-green")
            encode(blue, forKey: "\(key)-blue")
            encode(alpha, forKey: "\(key)-alpha")
        }
    }
    
    func decodeColor(forKey key: String) -> UIColor {
        let red: CGFloat = CGFloat(decodeFloat(forKey: "\(key)-red"))
        let green: CGFloat = CGFloat(decodeFloat(forKey: "\(key)-green"))
        let blue: CGFloat = CGFloat(decodeFloat(forKey: "\(key)-blue"))
        let alpha: CGFloat = CGFloat(decodeFloat(forKey: "\(key)-alpha"))
        
        return UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }
}
