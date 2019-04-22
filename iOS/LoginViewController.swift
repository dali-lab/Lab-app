//
//  ViewController.swift
//  DALISwift
//
//  Created by John Kotz on 6/23/17.
//  Copyright © 2017 Facebook. All rights reserved.
//

import UIKit
import GoogleSignIn
import SCLAlertView

class LoginViewController: UIViewController, GIDSignInUIDelegate, ErrorAlertShower {
	@IBOutlet weak var image: UIImageView!
	@IBOutlet weak var imageHorizontalContraint: NSLayoutConstraint!
	@IBOutlet weak var subView: UIView!
	@IBOutlet weak var googleButton: GIDSignInButton!
	@IBOutlet weak var skipSignInButton: UIButton!
	@IBOutlet weak var loadingOverlay: UIVisualEffectView!
	@IBOutlet weak var activityIndicator: UIActivityIndicatorView!
	
	var transformAnimationDone = false

	override func viewDidLoad() {
		super.viewDidLoad()
		loadingOverlay.isHidden = true
		activityIndicator.isHidden = true
		activityIndicator.stopAnimating()
		
		GIDSignIn.sharedInstance().uiDelegate = self
		
		if let delegate = UIApplication.shared.delegate as? AppDelegate {
			delegate.loginViewController = self
		}
		
		googleButton.style = .wide
		subView.alpha = 0
		
		UIView.animate(withDuration: 1.3, delay: 1.0, options: [UIView.AnimationOptions.curveEaseInOut], animations: {
			self.image.transform = CGAffineTransform(translationX: 0, y: -90)
			self.subView.transform = CGAffineTransform(translationX: 0, y: -90)
		}) { _ in
			UIView.animate(withDuration: 1.0, animations: { 
				self.subView.alpha = 1
			})
			self.transformAnimationDone = true
		}
	}
	
	func showError(alert: SCLAlertView, title: String, subTitle: String) {
		DispatchQueue.main.async {
			_ = alert.showError(title, subTitle: subTitle)
		}
	}
	
	func beginLoading() {
		loadingOverlay.isHidden = false
		loadingOverlay.alpha = 0.0
		activityIndicator.isHidden = false
		activityIndicator.startAnimating()
		
		UIView.animate(withDuration: 0.3, delay: 0.5, options: [], animations: {
			self.loadingOverlay.alpha = 1.0
		}) { _ in
			
		}
	}
	
	func endLoading() {
		activityIndicator.isHidden = true
		activityIndicator.stopAnimating()
		
		UIView.animate(withDuration: 0.5) {
			self.loadingOverlay.alpha = 0.0
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
