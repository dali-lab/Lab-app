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
import FutureKit
import EmitterKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, GIDSignInDelegate {
    /// The shared instance of the AppDelegate
	static private(set) var shared: AppDelegate!
    
    private let trackingModule = TrackingModule()
	
    var window: UIWindow?
    /// User provided by Google Sign In
	var googleUser: GIDGoogleUser?
    /// The saved LoginViewController instance
	var loginViewController: LoginViewController?
    /// The saved MainViewController instance
	var mainViewController: MainViewController?
    /// Keep track of when the app is backgrounded so we know when it is reactivated
	private(set) var inBackground = false
    /// Event triggered when the user signs in or out
    let memberSignedInEvent = Event<DALIMember?>()
	
	func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
		#if !DEBUG
			Fabric.with([Crashlytics.self])
		#endif
		
		AppDelegate.shared = self
		
		var error: NSError?
		GGLContext.sharedInstance().configureWithError(&error)
		assert(error == nil)
		
		let config = DALIConfig(serverURL: "https://dalilab-api.herokuapp.com")
		DALIapi.configure(config: config)
		
		GIDSignIn.sharedInstance().delegate = self
		
		if DALIapi.isSignedIn {
			self.didSignIn(member: DALIMember.current!)
			_ = DALIapi.silentMemberUpdate()
		} else {
            _ = DALIapi.silentMemberUpdate().onSuccess { (member) in
                if let member = member {
                    self.didSignIn(member: member)
                }
            }
		}
		GIDSignIn.sharedInstance().signInSilently()
        NotificationsController.shared.setup(launchOptions: launchOptions)
        CheckInController.shared.setup()
        trackingModule.startTracking()
		
		return true
	}
	
	func application(_ application: UIApplication,
                     performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
		print("Background fetching...")
        var inDALI = BeaconController.shared.inside(.DALI)
        var inOffice = BeaconController.shared.inside(.timsOffice)
        
        if userIsTim() {
            if inDALI && inOffice {
                inDALI = DALIRegion.DALI.locationTextPriority > DALIRegion.timsOffice.locationTextPriority
                inOffice = DALIRegion.timsOffice.locationTextPriority > DALIRegion.DALI.locationTextPriority
            }
            
            DALILocation.Tim.submit(inDALI: inDALI, inOffice: inOffice).onSuccess { (_) in
                completionHandler(.newData)
            }.onFail { _ in
                completionHandler(.failed)
            }
        } else {
            DALILocation.Shared.submit(inDALI: inDALI, entering: false).onSuccess { (_) in
                completionHandler(.noData)
            }.onFail { _ in
                completionHandler(.failed)
            }
        }
	}
    
    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        return GIDSignIn.sharedInstance().handle(url,
                                                 sourceApplication: options[.sourceApplication] as? String,
                                                 annotation: options)
    }
    
    func application(_ application: UIApplication,
                     handleEventsForBackgroundURLSession identifier: String,
                     completionHandler: @escaping () -> Void) {
        BackgroundSession.shared.savedCompletionHandler = completionHandler
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        inBackground = true
        print("Entering Background")
        
        // Notify the rest of the app
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "enterBackground"), object: nil)
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        if inBackground {
            print("Returning from Background")
            inBackground = false
            
            // Notify the rest of the app
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "returnFromBackground"), object: nil)
        }
    }
    
    // MARK: - GIDSignInDelegate
    
    /**
     Completed signing in using Google
     
     - parameter signIn: The Google sign in controller
     - parameter user: The Goole user object
     - parameter error: Error encountered, if any
     */
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        
        if let error = error {
            print(error)
            UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalNever)
        } else {
            UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalMinimum)
            let alreadySignedIn = DALIapi.isSignedIn
            self.googleUser = user
            
            if !alreadySignedIn {
                self.loginViewController?.beginLoading()
                let accessToken = user.authentication.accessToken!
                let refreshToken = user.authentication.refreshToken!
                
                DALIapi.signin(accessToken: accessToken, refreshToken: refreshToken, forced: true)
                    .mainThreadFuture.onSuccess { (member) in
                        self.didSignIn(member: member, changeUI: !alreadySignedIn)
                    }.onFail { _ in
                        if !alreadySignedIn {
                            self.loginViewController?.showError(alert: SCLAlertView(),
                                                                title: "Error Logging In",
                                                                subTitle: "Encountered an error when logging in!")
                            self.loginViewController?.endLoading()
                        }
                }
            }
        }
    }
    
    // MARK: - User management
    
    func didSignIn(member: DALIMember, changeUI: Bool = true) {
        trackingModule.askForPermission()
        memberSignedInEvent.emit(member)
        DALIapi.enableSockets()
        BeaconController.shared.assemble()
        BeaconController.shared.updateLocation()
        
        if changeUI {
            let mainViewController = UIStoryboard(name: "Main", bundle: nil)
                .instantiateViewController(withIdentifier: "MainViewController") as! MainViewController
            if let loginViewController = self.loginViewController {
                mainViewController.modalTransitionStyle = .crossDissolve
                mainViewController.modalPresentationStyle = .fullScreen
                mainViewController.loginTransformAnimationDone = loginViewController.transformAnimationDone
                
                loginViewController.present(mainViewController, animated: true, completion: {
                    NotificationsController.shared.setUpNotificationListeners()
                })
            } else {
                self.window?.rootViewController = mainViewController
            }
            
            self.loginViewController?.endLoading()
        }
    }
    
    func skipSignIn() {
        UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalNever)
        let mainViewController = UIStoryboard(name: "Main", bundle: nil)
            .instantiateViewController(withIdentifier: "MainViewController") as! MainViewController
        
        mainViewController.modalTransitionStyle = .crossDissolve
        mainViewController.modalPresentationStyle = .fullScreen
        mainViewController.loginTransformAnimationDone = loginViewController?.transformAnimationDone ?? false
        
        memberSignedInEvent.emit(nil)
        DALIapi.enableSockets()
        
        loginViewController?.present(mainViewController, animated: true, completion: {
            
        })
    }
    
    func signOut() {
        UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalNever)
        BeaconController.shared.dismantle()
        
        GIDSignIn.sharedInstance().signOut()
        DALIapi.signOut()
        memberSignedInEvent.emit(nil)
        
        DALIapi.disableSockets()
        
        let loginViewController = UIStoryboard(name: "Main", bundle: nil)
            .instantiateInitialViewController() as! LoginViewController
        
        self.window?.rootViewController? = loginViewController
        self.loginViewController = loginViewController
    }
    
    // MARK: - Notifications
	
	func votingEventEnteredOrExited(_ callback: @escaping () -> Void) {
		if UIApplication.shared.applicationState != .background {
			return
		}
		
		if SettingsController.votingNotificationsEnabled {
            DALIEvent.VotingEvent.getCurrent().onSuccess { (events) in
                return NotificationsController.shared.votingNotif(events: events)
            }.onSuccess { (_) in
                callback()
            }.onFail { _ in
                // TODO: Handle error
            }
		}
	}
    
    func checkedOut(equipment: DALIEquipment) {
        guard let checkOut = equipment.lastCheckedOut, let returnDate = checkOut.expectedReturnDate else {
            return
        }
        
        NotificationsController.shared.returnNotif(equipment: equipment, returnDate: returnDate)
    }
}
