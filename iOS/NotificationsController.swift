//
//  NotificationsController.swift
//  iOS
//
//  Created by John Kotz on 5/22/19.
//  Copyright © 2019 BrunchLabs. All rights reserved.
//

import Foundation
import UserNotifications
import SCLAlertView
import OneSignal
import DALI
import FutureKit
import EmitterKit

class NotificationsController: NSObject, OSSubscriptionObserver, UNUserNotificationCenterDelegate {
    private static var _shared: NotificationsController?
    public static var shared: NotificationsController {
        if _shared == nil {
            _shared = NotificationsController()
        }
        return _shared!
    }
    
    private static let coinsSound = UNNotificationSound(named: UNNotificationSoundName(rawValue: "coins.m4a"))
    
    /// Notifications are authorized
    public var notificationsAuthorized = false
    private var notificationsDismissed: Bool {
        get {
            return UserDefaults.standard.bool(forKey: "noNotificationsSelected")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "noNotificationsSelected")
        }
    }
    private var memberSignedInListener: Listener?
    private var regionListeners = [Listener]()
    
    private override init() {
        super.init()
        
        regionListeners = DALIRegion.all.map { (region) -> Listener in
            return region.stateEvent.on { (tuple) in
                self.region(region, changedBy: tuple.change, to: tuple.now)
            }
        }
        
        memberSignedInListener = AppDelegate.shared.memberSignedInEvent.on { (member) in
            self.signedIn(with: member)
        }
    }
    
    deinit {
        memberSignedInListener?.isListening = false
        regionListeners.forEach { $0.isListening = false }
    }
    
    private func region(_ region: DALIRegion, changedBy change: DALIRegion.State.Change, to state: DALIRegion.State) {
        switch region {
        case .DALI:
            self.enterNotif(entered: change == .entering)
        // TODO: Handle more stuff
        default: break
        }
    }
    
    public func setup(launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        // Override point for customization after application launch.
        let settings = [kOSSettingsKeyAutoPrompt: false]
        OneSignal.initWithLaunchOptions(launchOptions,
                                        appId: "6799d21a-debe-4ec8-b6f0-99c72cac170d",
                                        handleNotificationAction: nil,
                                        settings: settings)
        OneSignal.inFocusDisplayType = OSNotificationDisplayType.notification
        OneSignal.add(self as OSSubscriptionObserver)
        signedIn(with: DALIMember.current)
        
        UNUserNotificationCenter.current().getNotificationSettings { (settings) in
            self.notificationsAuthorized = (settings.authorizationStatus == .authorized)
        }
        
        // TODO: Equipment return date notification
        let updateReturnDate = UNNotificationAction(identifier: "UPDATE_RETURN_ACTION",
                                                    title: "Update Return Date",
                                                    options: .foreground)
        let returnReminderCategory = UNNotificationCategory(identifier: "RETURN_REMINDER",
                                                            actions: [updateReturnDate],
                                                            intentIdentifiers: [],
                                                            options: .customDismissAction)
        UNUserNotificationCenter.current().setNotificationCategories([returnReminderCategory])
    }
    
    func checkedInNotification() {
        guard SettingsController.checkInNotificationsEnabled &&
              UIApplication.shared.applicationState != .background else {
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "Checked In!"
        content.body = "Just checked you into this event 👍🤖!"
        content.subtitle = ""
        content.sound = NotificationsController.coinsSound
        
        let notification = UNNotificationRequest(identifier: "checkInNotification", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(notification)
    }
    
    func enterNotif(entered: Bool) {
        guard SettingsController.enterExitNotificationsEnabled &&
              UIApplication.shared.applicationState != .background else {
            return
        }
        
        let lastSentDateDefaultsKey = "entrance\(entered)NotificationLastSent"
        let lastSentDate = UserDefaults.standard.object(forKey: lastSentDateDefaultsKey) as? Date
        
        guard lastSentDate == nil || entered && abs(lastSentDate!.timeIntervalSince(Date())) < 2*60*60 else {
            return
        }
        UserDefaults.standard.set(Date(), forKey: lastSentDateDefaultsKey)
        
        let content = UNMutableNotificationContent()
        content.title = entered ? "Welcome Back" : "See you next time"
        let emojies = ["💡", "😄", "🚀", "💻", "🌈", "✨", "🌯", "⚙️"]
        let randomIndex = Int(arc4random_uniform(UInt32(emojies.count)))
        content.body = entered ? emojies[randomIndex] : "👋"
        content.subtitle = ""
        content.sound = NotificationsController.coinsSound
        
        let notification = UNNotificationRequest(identifier: "enterExitNotification", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(notification) { (_) in
            
        }
    }
    
    func votingNotif(events: [DALIEvent]) -> Future<Void> {
        let promise = Promise<Void>()
        let content = UNMutableNotificationContent()
        content.title = "Welcome to " + events.first!.name
        content.body = "Voting is available for this event! 🗳💡"
        content.subtitle = ""
        content.sound = NotificationsController.coinsSound
        
        let notification = UNNotificationRequest(identifier: "votingNotification",
                                                 content: content,
                                                 trigger: nil)
        UNUserNotificationCenter.current().add(notification) { (_) in
            promise.completeWithSuccess(())
        }
        return promise.future
    }
    
    func returnNotif(equipment: DALIEquipment, returnDate: Date) {
        let content = UNMutableNotificationContent()
        content.title = "\(equipment.name) Return Date Reached"
        content.body = "The expected return rate for \(equipment.name) has arrived"
        content.categoryIdentifier = "RETURN_REMINDER"
        content.threadIdentifier = "returnReminder:\(equipment.id)"
        content.userInfo = ["equipment": ["id": equipment.id, "name": equipment.name]]
        
        var dateComponents = Calendar.current.dateComponents([.calendar, .day, .month, .year, .era], from: returnDate)
        dateComponents.hour = 14 // 14:00 hours
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(identifier: "returnReminder:\(equipment.id)",
            content: content,
            trigger: trigger)
        UNUserNotificationCenter.current().add(request) { (error) in
            if let error = error {
                print(error.localizedDescription)
            }
        }
    }
    
    private func signedIn(with member: DALIMember?) {
        if let member = member {
            OneSignal.setEmail(member.email)
            OneSignal.sendTag("admin", value: "\(member.isAdmin)")
        }
        OneSignal.sendTag("signedIn", value: "\(member != nil)")
    }
    
    /**
     Ask for notifications if necessary
     
     - returns: Future describing the result. True for notifications enabled, false for disabled
     */
    public func askForNotifications() -> Future<Bool> {
        let promise = Promise<Bool>()
        let center = UNUserNotificationCenter.current()
        
        guard !notificationsDismissed else {
            return Future(fail: DALIUIError.Notifications.notificationsDismissed)
        }
        
        // Prepare for computing UI elements in case we need them
        let alertInfo = { () -> (alert: SCLAlertView, vc: AlertShower?) in
            // Generate an alert and find a view controller to show it on
            let alertAppearance = SCLAlertView.SCLAppearance(showCloseButton: false)
            let alert = SCLAlertView(appearance: alertAppearance)
            let alertShower = self.visibleVC(startingAt: nil) as? AlertShower
            
            // Add some buttons
            alert.addButton("No, not now", action: {
                self.notificationsDismissed = true
                promise.completeWithFail(DALIUIError.Notifications.notificationsDismissed)
            })
            alert.addButton("Sure", action: {
                // Request authorization using the system default way
                UNUserNotificationCenter.current()
                    .requestAuthorization(options: [.alert, .badge, .sound]) { (success, _) in
                        self.notificationsAuthorized = true
                        promise.completeWithSuccess(success)
                }
            })
            return (alert, alertShower)
        }
        
        // Confirm that notifications are not determined before asking
        center.getNotificationSettings(completionHandler: { (settings) in
            switch settings.authorizationStatus {
            case .notDetermined:
                let info = alertInfo()
                info.vc?.showAlert(alert: info.alert,
                                   title: "Notifications",
                                   subTitle: "Would you like this app to send you notifications to" +
                                             " welcoming you to events you go to?",
                                   color: #colorLiteral(red: 0.6085096002, green: 0.80526066, blue: 0.9126116071, alpha: 1),
                                   image: #imageLiteral(resourceName: "notificationBell"))
                
            default:
                self.notificationsAuthorized = (settings.authorizationStatus == .authorized)
                promise.completeWithSuccess(settings.authorizationStatus == .authorized)
            }
        })
        
        return promise.future
    }
    
    /**
     
     */
    public func setUpNotificationListeners() {
//        _ = self.askForNotifications().onSuccess { (success) in
//            guard success else { return }
//            OneSignal.promptForPushNotifications(userResponse: { _ in })
//        }
        
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
//        let userInfo = response.notification.request.content.userInfo

        // TODO: Deal with equipment update return date actions
//        if response.actionIdentifier == "UPDATE_RETURN_ACTION" {
//            guard let equipmentDict = userInfo["equipment"] as? [String: String],
//                let id = equipmentDict["id"] else {
//                    return
//            }
//
//            _ = DALIEquipment.equipment(for: id).onSuccess { _ in
//
//            }
//        }
    }
    
    // MARK: - OSSubscriptionObserver
    
    func onOSSubscriptionChanged(_ stateChanges: OSSubscriptionStateChanges!) {
        // The player id is inside stateChanges.
        // But be careful, this value can be nil if the user has not granted you permission to send notifications.
        if let playerId = stateChanges.to.userId {
            UserDefaults.standard.set(playerId, forKey: "playerID")
        }
    }
    
    // MARK: - Helpers
    
    /**
     Get the current visibile view controller
     
     Credits to @ProgrammierTier https://stackoverflow.com/a/34179192
     
     - parameter rootViewController: The view controller to start from
     - returns: The view controller that could be found that is visible
     */
    func visibleVC(startingAt rootViewController: UIViewController?) -> UIViewController? {
        let rootVC = rootViewController ??
            AppDelegate.shared.window?.rootViewController ??
            UIApplication.shared.keyWindow?.rootViewController
        
        guard let presented = rootVC?.presentedViewController else {
            return rootVC
        }
        
        if presented.isKind(of: UINavigationController.self) {
            return (presented as! UINavigationController).viewControllers.last!
        } else if presented.isKind(of: UITabBarController.self) {
            return (presented as! UITabBarController).selectedViewController!
        }
        
        return visibleVC(startingAt: presented)
    }
}
