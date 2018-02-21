//
//  AppDelegate.swift
//  DALISwift
//
//  Created by John Kotz on 6/23/17.
//  Copyright © 2017 Facebook. All rights reserved.
//

import UIKit
import Fabric
import Crashlytics
import UserNotifications
import SCLAlertView
import DALI
import OneSignal

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, GIDSignInDelegate, OSSubscriptionObserver {
	static var shared: AppDelegate!
	
	var window: UIWindow?
	var user: GIDGoogleUser?
	var loginViewController: LoginViewController?
	var mainViewController: MainViewController?
	var inBackground = false
	var playerID: String?
	var notificationsAuthorized = false
	
	var beaconController: BeaconController?
	
	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
		// Override point for customization after application launch.
		let settings = [kOSSettingsKeyAutoPrompt: false]
		OneSignal.initWithLaunchOptions(launchOptions, appId: "6799d21a-debe-4ec8-b6f0-99c72cac170d", handleNotificationAction: nil, settings: settings)
		OneSignal.inFocusDisplayType = OSNotificationDisplayType.notification
		OneSignal.add(self as OSSubscriptionObserver)
		
		#if !DEBUG
			Fabric.with([Crashlytics.self])
		#endif
		
		AppDelegate.shared = self
		
		var error: NSError? = nil
		GGLContext.sharedInstance().configureWithError(&error)
		
		assert(error == nil)
		
		let config = DALIConfig(serverURL: "https://dalilab-api.herokuapp.com")
		DALIapi.configure(config: config)
		
		GIDSignIn.sharedInstance().delegate = self
		
		if DALIapi.isSignedIn {
			self.didSignIn(member: DALIMember.current!)
			DALIapi.silentMemberUpdate(callback: { (_) in
				
			})
		}else{
			DALIapi.silentMemberUpdate(callback: { (member) in
				if let member = member {
					self.didSignIn(member: member)
				}
			})
		}
		GIDSignIn.sharedInstance().signInSilently()
		UIApplication.shared.setMinimumBackgroundFetchInterval(1.0)
		
		UNUserNotificationCenter.current().getNotificationSettings { (settings) in
			self.notificationsAuthorized = settings.authorizationStatus == .authorized
		}
		
		return true
	}
	
	func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
		print("Background fetching...")
		if let beaconController = BeaconController.current {
			if userIsTim() {
				DALILocation.Tim.submit(inDALI: beaconController.inDALI, inOffice: beaconController.inOffice, callback: { (_, error) in
					if error != nil {
						completionHandler(.failed)
					}else{
						completionHandler(.newData)
					}
				})
			}else{
				DALILocation.Shared.submit(inDALI: beaconController.inDALI, entering: false, callback: { (_, error) in
					if error != nil {
						completionHandler(.failed)
					}else{
						completionHandler(.newData)
					}
				})
			}
		}
	}
	
	func onOSSubscriptionChanged(_ stateChanges: OSSubscriptionStateChanges!) {
		//The player id is inside stateChanges. But be careful, this value can be nil if the user has not granted you permission to send notifications.
		if let playerId = stateChanges.to.userId {
			UserDefaults.standard.set(playerId, forKey: "playerID")
		}
	}
	
	func askForNotifications(callback: @escaping (_ success: Bool) -> Void) {
		let center = UNUserNotificationCenter.current()
		
		if UserDefaults.standard.bool(forKey: "noNotificationsSelected") {
			callback(false)
			return
		}
		
		center.getNotificationSettings(completionHandler: { (settings) in
			switch (settings.authorizationStatus) {
			case .notDetermined:
				DispatchQueue.main.async {
					let alertAppearance = SCLAlertView.SCLAppearance(
						showCloseButton: false
					)
					
					let alert = SCLAlertView(appearance: alertAppearance)
					alert.addButton("No, not now", action: {
						UserDefaults.standard.set(true, forKey: "noNotificationsSelected")
						callback(false)
					})
					alert.addButton("Sure", action: {
						center.requestAuthorization(options: [.alert, .badge, .sound]) { (success, error) in
							self.notificationsAuthorized = true
							callback(success)
						}
					})
					
					(self.getVisibleViewController(self.window?.rootViewController) as? AlertShower)?.showAlert(alert: alert, title: "Notifications", subTitle: "Would you like this app to send you notifications to welcoming you to events you go to?", color: #colorLiteral(red: 0.6085096002, green: 0.80526066, blue: 0.9126116071, alpha: 1), image: #imageLiteral(resourceName: "notificationBell"))
				}
				break
			case .authorized:
				self.notificationsAuthorized = true
				callback(true)
				break
			default:
				callback(false)
				break
			}
		})
	}
	
	
	// Credits to @ProgrammierTier https://stackoverflow.com/a/34179192
	func getVisibleViewController(_ rootViewController: UIViewController?) -> UIViewController? {
		
		var rootVC = rootViewController
		if rootVC == nil {
			rootVC = UIApplication.shared.keyWindow?.rootViewController
		}
		
		if rootVC?.presentedViewController == nil {
			return rootVC
		}
		
		if let presented = rootVC?.presentedViewController {
			if presented.isKind(of: UINavigationController.self) {
				let navigationController = presented as! UINavigationController
				return navigationController.viewControllers.last!
			}
			
			if presented.isKind(of: UITabBarController.self) {
				let tabBarController = presented as! UITabBarController
				return tabBarController.selectedViewController!
			}
			
			return getVisibleViewController(presented)
		}
		return nil
	}
	
	func setUpNotificationListeners() {
		self.askForNotifications { (success) in
			if success {
				if let user = GIDSignIn.sharedInstance().currentUser {
					OneSignal.syncHashedEmail(user.profile.email)
				}
				OneSignal.sendTag("signedIn", value: "\(GIDSignIn.sharedInstance().currentUser != nil)")
				
				OneSignal.promptForPushNotifications(userResponse: { accepted in
					
				})
			}
		}
	}
	
	func enterExitHappened(entered: Bool) {
		if UIApplication.shared.applicationState != .background {
			return
		}
		
		if SettingsController.getEnterExitNotif() {
			let content = UNMutableNotificationContent()
			content.title = entered ? "Welcome Back" : "See you next time"
			let emojies = ["💡", "😄", "🚀", "💻", "🌈", "✨", "🌯", "⚙️"]
			let randomIndex = Int(arc4random_uniform(UInt32(emojies.count)))
			content.body = entered ? emojies[randomIndex] : "👋"
			content.subtitle = ""
			content.sound = UNNotificationSound(named: "coins.m4a")
			
			let notification = UNNotificationRequest(identifier: "enterExitNotification", content: content, trigger: nil)
			UNUserNotificationCenter.current().add(notification) { (error) in
				
			}
		}
	}
	
	func checkInHappened() {
		if UIApplication.shared.applicationState != .background {
			return
		}
		
		if SettingsController.getCheckInNotif() {
			let content = UNMutableNotificationContent()
			content.title = "Checked In!"
			content.body = "Just checked you into this event 👍🤖!"
			content.subtitle = ""
			content.sound = UNNotificationSound(named: "coins.m4a")
			
			let notification = UNNotificationRequest(identifier: "checkInNotification", content: content, trigger: nil)
			UNUserNotificationCenter.current().add(notification) { (error) in
				
			}
		}
	}
	
	func votingEventEnteredOrExited(_ callback: @escaping () -> Void) {
		if UIApplication.shared.applicationState != .background {
			return
		}
		
		if SettingsController.getVotingNotif() {
			DALIEvent.VotingEvent.getCurrent { (events, error) in
				guard events.count > 0 else {
					return
				}
				
				let content = UNMutableNotificationContent()
				content.title = "Welcome to " + events.first!.name
				content.body = "Voting is available for this event! 🗳💡"
				content.subtitle = ""
				content.sound = UNNotificationSound(named: "coins.m4a")
				
				let notification = UNNotificationRequest(identifier: "votingNotification", content: content, trigger: nil)
				UNUserNotificationCenter.current().add(notification) { (error) in
					callback()
				}
			}
		}
	}
	
	func breakDownNotificationListeners() {
		NotificationCenter.default.removeObserver(self)
	}
	
	func didSignIn(member: DALIMember, noUIChange: Bool = false) {
		if self.notificationsAuthorized {
			OneSignal.syncHashedEmail(member.email)
			OneSignal.sendTag("signedIn", value: "\(true)")
		}
		
		if self.beaconController == nil && BeaconController.current == nil {
			self.beaconController = BeaconController()
		}else{
			self.beaconController = BeaconController.current
		}
		DALIapi.enableSockets()
		
		if !noUIChange {
			let mainViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "MainViewController") as! MainViewController
			if let loginViewController = self.loginViewController {
				mainViewController.modalTransitionStyle = .crossDissolve
				mainViewController.modalPresentationStyle = .fullScreen
				mainViewController.loginTransformAnimationDone = loginViewController.transformAnimationDone
				
				loginViewController.present(mainViewController, animated: true, completion: {
					self.setUpNotificationListeners()
				})
			}else{
				self.window?.rootViewController = mainViewController
			}
			
			self.loginViewController?.endLoading()
		}
	}
	
	func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
		UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalMinimum)
		
		if let error = error {
			print(error)
		}else{
			let alreadySignedIn = DALIapi.isSignedIn
			self.user = user
			if !alreadySignedIn {
				self.loginViewController?.beginLoading()
				DALIapi.signin(accessToken: user.authentication.accessToken, refreshToken: user.authentication.refreshToken, forced: true, done: { (sucess, error) in
					if let member = DALIMember.current, sucess {
						DispatchQueue.main.async {
							self.didSignIn(member: member, noUIChange: alreadySignedIn)
						}
					}else{
						print(error!)
						
						if !alreadySignedIn {
							DispatchQueue.main.async {
								self.loginViewController?.showError(alert: SCLAlertView(), title: "Error Logging In", subTitle: "Encountered an error when logging in!")
								self.loginViewController?.endLoading()
							}
						}
					}
				})
			}
		}
	}
	
	func skipSignIn() {
		
		UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalNever)
		let mainViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "MainViewController") as! MainViewController
		
		mainViewController.modalTransitionStyle = .crossDissolve
		mainViewController.modalPresentationStyle = .fullScreen
		mainViewController.loginTransformAnimationDone = loginViewController?.transformAnimationDone ?? false
		OneSignal.sendTag("signedIn", value: "\(false)")
		
		DALIapi.enableSockets()
		
		loginViewController?.present(mainViewController, animated: true, completion: {
			
		})
	}
	
	func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
		print("Disconnected!")
		self.breakDownNotificationListeners()
	}
	
	func signOut() {
		UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalNever)
		self.breakDownNotificationListeners()
		BeaconController.current?.breakdown()
		self.beaconController = nil
		
		GIDSignIn.sharedInstance().signOut()
		DALIapi.signOut()
		OneSignal.sendTag("signedIn", value: "\(false)")
		
		DALIapi.disableSockets()
		
		let loginViewController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController() as! LoginViewController
		
		self.window?.rootViewController? = loginViewController
		self.loginViewController = loginViewController
	}
	
	func returnToSignIn() {
		self.signOut()
	}
	
	func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
		return GIDSignIn.sharedInstance().handle(url, sourceApplication: options[.sourceApplication] as? String, annotation: options)
	}
	
	func applicationWillResignActive(_ application: UIApplication) {
		// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
		// Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
	}
	
	func applicationDidEnterBackground(_ application: UIApplication) {
		// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
		// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
		inBackground = true
		print("Entering Background")
		
		// Notify the rest of the app
		NotificationCenter.default.post(name: NSNotification.Name(rawValue: "enterBackground"), object: nil)
	}
	
	func applicationWillEnterForeground(_ application: UIApplication) {
		// Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
	}
	
	func applicationDidBecomeActive(_ application: UIApplication) {
		// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
		if inBackground {
			print("Returning from Background")
			inBackground = false
			
			// Notify the rest of the app
			NotificationCenter.default.post(name: NSNotification.Name(rawValue: "returnFromBackground"), object: nil)
		}
	}
	
	func applicationWillTerminate(_ application: UIApplication) {
		// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
	}
	
	
}

