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
	
	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
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
	
	func applicationWillResignActive(_ application: UIApplication) {
		// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
		// Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
	}
	
	func applicationDidEnterBackground(_ application: UIApplication) {
		// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
		// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
		timer?.invalidate()
	}
	
	func applicationWillEnterForeground(_ application: UIApplication) {
		// Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
		self.createTimer()
	}
	
	func createTimer() {
		self.timer?.invalidate()
		self.timer = Timer(timeInterval: 20*60, repeats: false, block: { (timer) in
			self.currentView.startSlideshow()
		})
		RunLoop.current.add(self.timer!, forMode: .commonModes)
	}
	
	func applicationDidBecomeActive(_ application: UIApplication) {
		// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
	}
	
	func applicationWillTerminate(_ application: UIApplication) {
		// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
	}
	
	
}

