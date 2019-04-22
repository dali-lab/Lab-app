//
//  AppDelegate.swift
//  DALI Lab tvOS
//
//  Created by John Kotz on 6/6/17.
//  Copyright © 2017 Facebook. All rights reserved.
//

import UIKit
import DALI

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
	static var shared: AppDelegate!
	
	var window: UIWindow?
	var timer: Timer?
	var currentView: ViewProtocol!
	
	func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
		// Override point for customization after application launch.
		AppDelegate.shared = self
		let file = NSDictionary(dictionary: [
			"server_url": "https://dalilab-api.herokuapp.com",
			"api_key": "69222f5c9ea91af57b223e087bca601e7c151ef9c9848dcfbae4d08bb884"
			])
		let config = DALIConfig(dict: file)
		DALIapi.configure(config: config)
		self.createTimer()
		return true
	}
	
	func slideshowExitTriggered(view: ViewProtocol) {
		createTimer()
		view.endSlideshow()
	}
	
	func applicationDidEnterBackground(_ application: UIApplication) {
		timer?.invalidate()
	}
	
	func applicationWillEnterForeground(_ application: UIApplication) {
		self.createTimer()
	}
	
	func createTimer() {
		self.timer?.invalidate()
		self.timer = Timer(timeInterval: 20*60, repeats: false, block: { (_) in
			self.currentView.startSlideshow()
		})
		RunLoop.current.add(self.timer!, forMode: .commonModes)
	}
}
