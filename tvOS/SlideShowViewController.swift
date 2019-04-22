//
//  SlideShowViewController.swift
//  tvOS
//
//  Created by John Kotz on 9/19/17.
//  Copyright © 2017 BrunchLabs. All rights reserved.
//

import Foundation
import UIKit
import DALI

class SlideShowViewController: UIViewController, ViewProtocol {
	func startSlideshow() {
		
	}
	
	func endSlideshow() {
		self.performSegue(withIdentifier: "endSlideshow", sender: nil)
	}
	
	@IBOutlet weak var imageContainer: UIView!
	@IBOutlet weak var overlayContainer: UIView!
	@IBOutlet var imageViews: [UIImageView]!
	
	var photos: [String] = []
	var timer: Timer!
	var observation: Observation?
	var nextImageIndex = 0
	
	override func viewDidLoad() {
		DALIPhoto.get { (photos, _) in
			self.photos = photos
			self.showRandomAll()
			
			self.timer = Timer(timeInterval: 20,
                               target: self,
                               selector: #selector(self.showRandom),
                               userInfo: nil,
                               repeats: true)
			RunLoop.main.add(self.timer, forMode: RunLoopMode.commonModes)
		}
		
		observation = DALILocation.observeMemberEnter { (member) in
			self.showOverlay(member: member.name)
		}
		
		let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(SlideShowViewController.tapped))
		tapRecognizer.allowedPressTypes = [NSNumber(value: UIPressType.select.rawValue),
                                           NSNumber.init(value: UIPressType.menu.rawValue)]
		self.view.addGestureRecognizer(tapRecognizer)
	}
	
	@objc func tapped() {
		AppDelegate.shared.slideshowExitTriggered(view: self)
	}
	
	override func viewDidAppear(_ animated: Bool) {
		AppDelegate.shared.currentView = self
	}
	
	func showOverlay(member: String) {
		let effectView = UIVisualEffectView()
		effectView.frame = self.overlayContainer.frame
		self.overlayContainer.addSubview(effectView)
		let label = UILabel()
		label.text = "Welcome \(member)! 👋"
		label.font = UIFont(name: "Avenir Next", size: 50.0)
		label.textColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
		label.alpha = 0.0
		label.sizeToFit()
		label.frame = CGRect(x: self.overlayContainer.frame.origin.x - label.frame.width,
                             y: self.overlayContainer.frame.height / 2,
                             width: label.frame.width,
                             height: label.frame.height)
		self.overlayContainer.addSubview(label)
		
		UIView.animate(withDuration: 0.5, animations: {
			effectView.effect = UIBlurEffect(style: .dark)
			label.alpha = 1.0
			label.frame = CGRect(x: self.overlayContainer.frame.width/2 - label.frame.width/2,
                                 y: self.overlayContainer.frame.height / 2 - label.frame.height / 2,
                                 width: label.frame.width,
                                 height: label.frame.height)
		}, completion: { (_) in
			UIView.animate(withDuration: 0.5, delay: 10, options: [], animations: {
				label.frame = CGRect(x: self.overlayContainer.frame.width,
                                     y: self.overlayContainer.frame.height / 2 - label.frame.height / 2,
                                     width: label.frame.width,
                                     height: label.frame.height)
				label.alpha = 0.0
				effectView.alpha = 0
			}, completion: { (_) in
				effectView.removeFromSuperview()
				label.removeFromSuperview()
			})
		})
	}
	
	func showRandomAll() {
		for imageView in self.imageViews {
			self.showRandomPhoto(on: imageView)
		}
	}
	
	func showRandomPhoto(on imageView: UIImageView) {
		let url = self.getRandomPhotoURL()
		
		self.loadPhotoURL(url: url, callback: { (image) in
			DispatchQueue.main.async {
				let newImageView = UIImageView(frame: imageView.frame)
				newImageView.image = image
				newImageView.contentMode = imageView.contentMode
				newImageView.alpha = 0.0
				newImageView.clipsToBounds = imageView.clipsToBounds
				self.imageContainer.addSubview(newImageView)
				
				UIView.animate(withDuration: 0.5, animations: {
					newImageView.alpha = 1.0
					imageView.alpha = 0.0
				}, completion: { (_) in
					imageView.alpha = 1.0
					newImageView.removeFromSuperview()
					imageView.image = image
				})
			}
		})
	}
	
	@objc func showRandom() {
		let imageView = self.imageViews[nextImageIndex]
		self.nextImageIndex = (nextImageIndex + 1) % self.imageViews.count
		self.showRandomPhoto(on: imageView)
	}
	
	func loadPhotoURL(url: String, callback: @escaping (UIImage) -> Void) {
		guard let url = URL(string: url) else {
			return
		}
		
		URLSession.shared.dataTask(with: url) { (data, _, _) in
			if let data = data, let image = UIImage.init(data: data) {
				callback(image)
			} else {
				print("Failed to get image from: \(url)")
			}
		}.resume()
	}
	
	func getRandomPhotoURL() -> String {
		let randomIndex = Int(arc4random_uniform(UInt32(self.photos.count)))
		return photos[randomIndex]
	}
}
