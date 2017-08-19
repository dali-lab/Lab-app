//
//  ViewController.swift
//  DALISwift
//
//  Created by John Kotz on 6/23/17.
//  Copyright © 2017 Facebook. All rights reserved.
//

import UIKit
import GoogleSignIn

class LoginViewController: UIViewController, GIDSignInUIDelegate {
	@IBOutlet weak var image: UIImageView!
	@IBOutlet weak var imageHorizontalContraint: NSLayoutConstraint!
	@IBOutlet weak var subView: UIView!
	@IBOutlet weak var googleButton: GIDSignInButton!
	@IBOutlet weak var skipSignInButton: UIButton!
	
	var googleSignInView: UIViewController!
	var transformAnimationDone = false

	override func viewDidLoad() {
		super.viewDidLoad()
		
		UIApplication.shared.statusBarStyle = .lightContent
		self.setNeedsStatusBarAppearanceUpdate()
		
		GIDSignIn.sharedInstance().uiDelegate = self
		
		if let delegate = UIApplication.shared.delegate as? AppDelegate {
			delegate.loginViewController = self
		}
		
		googleButton.style = .wide
		subView.alpha = 0
		
		UIView.animate(withDuration: 1.3, delay: 1.0, options: [UIViewAnimationOptions.curveEaseInOut], animations: {
			self.image.transform = CGAffineTransform(translationX: 0, y: -90)
			self.subView.transform = CGAffineTransform(translationX: 0, y: -90)
		}) { (success) in
			UIView.animate(withDuration: 1.0, animations: { 
				self.subView.alpha = 1
			})
			self.transformAnimationDone = true
		}
	}
	
	@IBAction func skipSignInPressed(_ sender: Any) {
		if let delegate = UIApplication.shared.delegate as? AppDelegate {
			delegate.skipSignIn()
		}
	}
	
	func sign(_ signIn: GIDSignIn!, present viewController: UIViewController!) {
		viewController.modalPresentationStyle = .formSheet
		viewController.modalTransitionStyle = .coverVertical
		self.present(viewController, animated: true) {}
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}


}

