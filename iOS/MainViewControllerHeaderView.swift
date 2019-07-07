//
//  MainViewControllerHeaderView.swift
//  iOS
//
//  Created by John Kotz on 7/7/19.
//  Copyright © 2019 BrunchLabs. All rights reserved.
//

import Foundation
import UIKit

class MainViewControllerEventsListHeaderView: UIView {
    let label = UILabel()
    let backgroundView = UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffect.Style.regular))
    
    init(title: String, active: Bool) {
        super.init(frame: CGRect.zero)
        
        backgroundView.backgroundColor = #colorLiteral(red: 0.1450980392, green: 0.5843137255, blue: 0.6588235294, alpha: 0.6546819982)
        backgroundView.layer.cornerRadius = 4
        backgroundView.clipsToBounds = true
        
        label.font = UIFont(name: "AvenirNext-Italic", size: 15)!
        label.text = title
        label.textColor = active ? UIColor.white : UIColor(red: 1, green: 1, blue: 1, alpha: 0.5)
        label.sizeToFit()
        
        addSubview(backgroundView)
        addSubview(label)
        
        self.updateConstraints()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func updateConstraints() {
        super.updateConstraints()
        label.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            label.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            label.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            
            backgroundView.leftAnchor.constraint(equalTo: self.leftAnchor),
            backgroundView.rightAnchor.constraint(equalTo: self.rightAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            backgroundView.topAnchor.constraint(equalTo: self.topAnchor)
        ])
    }
}
