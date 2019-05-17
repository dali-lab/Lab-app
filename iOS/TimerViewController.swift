//
//  TimerViewController.swift
//  iOS
//
//  Created by John Kotz on 3/29/19.
//  Copyright © 2019 BrunchLabs. All rights reserved.
//

import Foundation
import UIKit

class TimerViewController: UIViewController {
    @IBOutlet weak var startButton: UIButton!
    
    override func viewDidLoad() {
        startButton.setBackgroundImage(startButton.currentBackgroundImage?.withRenderingMode(.alwaysTemplate),
                                       for: .normal)
    }
    
    @IBAction func signIn(_ sender: UIButton) {
        
    }
    
    @IBAction func doneButtonPressed(_ sender: Any) {
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
}
