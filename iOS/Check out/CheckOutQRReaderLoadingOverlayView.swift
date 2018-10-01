//
//  CheckOutQRReaderLoadingOverlayView.swift
//  iOS
//
//  Created by John Kotz on 9/24/18.
//  Copyright © 2018 BrunchLabs. All rights reserved.
//

import Foundation
import UIKit

class CheckOutQRReaderLoadingOverlayView: UIView, UIGestureRecognizerDelegate {
    let activityIndicator: UIActivityIndicatorView
    let gestureRecognizer: UITapGestureRecognizer
    
    private var _loading: Bool = false
    var loading: Bool {
        get {
            return _loading
        }
        set {
            if (_loading != newValue) {
                _loading = newValue
                if (newValue) {
                    self.activityIndicator.startAnimating()
                    self.backgroundColor = UIColor.black.withAlphaComponent(0.5)
                } else {
                    self.activityIndicator.stopAnimating()
                    self.backgroundColor = UIColor.clear
                }
                self.isHidden = !newValue
            }
        }
    }
    
    func isLoading() -> Bool {
        return _loading;
    }
    
    func set(loading: Bool, animated: Bool) {
        UIView.animate(withDuration: 0.5) {
            self.loading = loading
        }
    }
    
    override init(frame: CGRect) {
        gestureRecognizer = UITapGestureRecognizer(target: nil, action: nil)
        activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        activityIndicator.hidesWhenStopped = true
        
        super.init(frame: frame)
        self.addSubview(self.activityIndicator)
        self.addGestureRecognizer(self.gestureRecognizer)
        
        activityIndicator.stopAnimating()
        backgroundColor = UIColor.clear
        gestureRecognizer.delegate = self
    }
    
    // Consume all gestures while loading
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return _loading
    }
    
    override func updateConstraints() {
        super.updateConstraints()
        var constraints = [NSLayoutConstraint]()
        
        constraints.append(self.activityIndicator.centerXAnchor.constraint(equalTo: self.centerXAnchor))
        constraints.append(self.activityIndicator.centerYAnchor.constraint(equalTo: self.centerYAnchor))
        
        NSLayoutConstraint.activate(constraints)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
