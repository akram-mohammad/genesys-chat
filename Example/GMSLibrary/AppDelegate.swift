//
// AppDelegate.swift
// GMSLibrary_Example
//
// Created by Cindy Wong on 2019-07-10
// Copyright © 2019 Genesys.  All rights reserved.
//

import UIKit
import Firebase
import GMSLibrary

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    static var shared: AppDelegate { return UIApplication.shared.delegate as! AppDelegate }

    let gcmMessageIDKey = "gcm.message_id"
    var fcmToken: String?
    
    var callbackClient: CallbackApiClient?
    
    var fcmConfigured = false
    
    var window: UIWindow?
    var application: UIApplication?

    private var _serverSettings: GmsServerSettings?
    private var _callbackServiceSettings: CallbackServiceSettings?
    private var _chatServiceSettings: ChatServiceSettings?
    private var _userSettings: GmsUserSettings?
    
    var serverSettings: GmsServerSettings? {
        get {
            return _serverSettings
        }
        set {
            _serverSettings = newValue
            sendSettingsUpdated()
        }
    }

    var callbackServiceSettings: CallbackServiceSettings? {
        get {
            return _callbackServiceSettings
        }
        set {
            _callbackServiceSettings = newValue
            sendSettingsUpdated()
        }
    }
    
    var chatServiceSettings: ChatServiceSettings? {
        get {
            return _chatServiceSettings
        }
        set {
            _chatServiceSettings = newValue
            sendSettingsUpdated()
        }
    }
    
    var userSettings: GmsUserSettings? {
        get {
            return _userSettings
        }
        set {
            _userSettings = newValue
            sendSettingsUpdated()
        }
    }
    
    var settingsUpdateDelegate: SettingsUpdateDelegate?
    
    var userSettingsViewController: UserSettingsTableViewController?
    var appSettingsViewController: AppSettingsTableViewController?
    
    var lastVC: UIViewController?
    
    var fcmEnabled: Bool {
        if let serverSettings = serverSettings {
            switch serverSettings.pushSettings {
            case .fcm:
                return true
            default:
                return false
            }
        } else {
            return false
        }
    }

    func sendSettingsUpdated() {
        // update callback client
        if let service = callbackServiceSettings, let server = serverSettings {
            callbackClient = CallbackApiClient(service, server)
        }
        if let delegate = settingsUpdateDelegate {
            delegate.settingsUpdated()
        }
    }

    func addSettingsUpdateDelegate(delegate: SettingsUpdateDelegate) {
        settingsUpdateDelegate = delegate
    }
    
    func loadPreferences() {
        print("Loading preferences")
        do {
            // set up some hardcoded preferences
            serverSettings = try GmsServerSettings(hostname: "gms.example.com", secureProtocol: true)
            callbackServiceSettings = try CallbackServiceSettings("callback", callbackType: .VOICE_NOW_USERTERM, target: "Customer_Service > 0")
            chatServiceSettings = try ChatServiceSettings("customer-support", useCometClient: true)
            userSettings = GmsUserSettings()
            userSettings!.firstName = "Jane"
            userSettings!.lastName = "Doe"
            userSettings!.nickname = "JaneD"
            userSettings!.email = "jane.doe@example.com"
        } catch {
            // do nothing
        }

        if  let path = Bundle.main.path(forResource: "Preferences", ofType: "plist"),
            let xml = FileManager.default.contents(atPath: path),
            let preferences = try? PropertyListDecoder().decode(Preferences.self, from: xml) {
            do {
                print("Preferences read from: \(path)")
                serverSettings = try preferences.getServerSettings()
                callbackServiceSettings = preferences.serviceSettings.callbackService
                chatServiceSettings = preferences.serviceSettings.chatService
            } catch {
                // do nothing
            }
            userSettings = preferences.getUserSettings()
        }
        
        callbackClient = CallbackApiClient(callbackServiceSettings!, serverSettings!)
    }
    
    
    func savePreferences() {
        print("Saving preferences")
        let preferences = Preferences(serverSettings: serverSettings!,
                                      callbackService: callbackServiceSettings!,
                                      chatService: chatServiceSettings!,
                                      userSettings: userSettings!)
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .xml
        
        let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("Preferences.plist")
        print("Saving Preferences to: \(path)")
        do {
            let data = try encoder.encode(preferences)
            try data.write(to: path)
        } catch {
            print(error)
        }
        reloadPushSettings()
    }

    func reloadPushSettings() {
        if !fcmConfigured && fcmEnabled {
            // configure FCM
            FirebaseApp.configure()
            
            // [START set_messaging_delegate]
            Messaging.messaging().delegate = self
            // [END set_messaging_delegate]
            // Register for remote notifications. This shows a permission dialog on first run, to
            // show the dialog at a more appropriate time move this registration accordingly.
            // [START register_for_notifications]
            
            // For iOS 10 display notification (sent via APNS)
            UNUserNotificationCenter.current().delegate = self
            
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(
                options: authOptions,
                completionHandler: {_, _ in })
            
            fcmToken = Messaging.messaging().fcmToken
            application!.registerForRemoteNotifications()
            // [END register_for_notifications]

            // bypass APN when app is in foreground
            Messaging.messaging().shouldEstablishDirectChannel = true
            
            fcmConfigured = true
        }
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        self.application = application

        loadPreferences()
        savePreferences()
        
        return true
    }

    // [START receive_message]
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        // If you are receiving a notification message while your app is in the background,
        // this callback will not be fired till the user taps on the notification launching the application.
        // TODO: Handle data of notification
        // With swizzling disabled you must let Messaging know about the message, for Analytics
        // Messaging.messaging().appDidReceiveMessage(userInfo)
        // Print message ID.
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        
        // Print full message.
        print(userInfo)
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // If you are receiving a notification message while your app is in the background,
        // this callback will not be fired till the user taps on the notification launching the application.
        // TODO: Handle data of notification
        // With swizzling disabled you must let Messaging know about the message, for Analytics
        // Messaging.messaging().appDidReceiveMessage(userInfo)
        // Print message ID.
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        
        // Print full message.
        print(userInfo)
        
        completionHandler(UIBackgroundFetchResult.newData)
    }
    // [END receive_message]
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Unable to register for remote notifications: \(error.localizedDescription)")
    }
    
    // This function is added here only for debugging purposes, and can be removed if swizzling is enabled.
    // If swizzling is disabled then this function must be implemented so that the APNs token can be paired to
    // the FCM registration token.
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("APNs token retrieved: \(deviceToken)")
        
        // With swizzling disabled you must set the APNs token here.
        // Messaging.messaging().apnsToken = deviceToken
    }
}

// [START ios_10_message_handling]
@available(iOS 10, *)
extension AppDelegate : UNUserNotificationCenterDelegate {
    
    // Receive displayed notifications for iOS 10 devices.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        
        // With swizzling disabled you must let Messaging know about the message, for Analytics
        // Messaging.messaging().appDidReceiveMessage(userInfo)
        // Print message ID.
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        
        // Print full message.
        print(userInfo)
        
        // Change this to your preferred presentation option
        completionHandler([.alert])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        // Print message ID.
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        
        // Print full message.
        print(userInfo)
        
        completionHandler()
    }
}
// [END ios_10_message_handling]

extension AppDelegate : MessagingDelegate {
    // [START refresh_token]
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        print("Firebase registration token: \(fcmToken)")
        
        let dataDict:[String: String] = ["token": fcmToken]
        NotificationCenter.default.post(name: Notification.Name("FCMToken"), object: nil, userInfo: dataDict)
        // TODO: If necessary send token to application server.
        // Note: This callback is fired at each app startup and whenever a new token is generated.

        if let serverSettings = serverSettings {
            switch serverSettings.pushSettings {
            case .fcm:
                do {
                    self.serverSettings = try serverSettings.updateFcmToken(fcmToken)
                } catch {
                    print("[AppDelegate] cannot update FCM token in server settings: \(error)")
                }
            default:
                break
            }
        }

    }
    // [END refresh_token]

    // [START ios_10_data_message]
    // Receive data messages on iOS 10+ directly from FCM (bypassing APNs) when the app is in the foreground.
    // To enable direct data messages, you can set Messaging.messaging().shouldEstablishDirectChannel to true.
    func messaging(_ messaging: Messaging, didReceive remoteMessage: MessagingRemoteMessage) {
        print("Received data message: \(remoteMessage.appData)")
    }
    // [END ios_10_data_message]
    
}

// MARK: - Local notifications
extension AppDelegate {
    func sendLocalNotificationDelegate(_ identifier:String, alertEnabled:Bool, soundEnabled:Bool, badgeEnabled:Bool, title:String = "", subtitle: String = "", body:String = "", badgeCount:Int = 0) {
        // only call this if notification is enabled
            let content = UNMutableNotificationContent()
            if alertEnabled {
                if !title.isEmpty {
                    content.title = title
                }
                if !subtitle.isEmpty {
                    content.subtitle = subtitle
                }
                if !body.isEmpty {
                    content.body = body
                }
            }
            
            if soundEnabled {
                content.sound = UNNotificationSound.default()
            }
            
            if badgeEnabled {
                content.badge = NSNumber(value: badgeCount)
            }
            
            content.categoryIdentifier = "chat"
            let trigger = UNTimeIntervalNotificationTrigger(
                timeInterval: 1,
                repeats: false)
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
        if badgeEnabled {
            DispatchQueue.main.async {
                UIApplication.shared.applicationIconBadgeNumber = badgeCount
            }
        }
    }
    
    func setAppBadgeNumber(_ count: Int = 0) {
            UNUserNotificationCenter.current().getNotificationSettings() {
                (settings) in
                let badgeEnabled = (settings.badgeSetting == .enabled)
                self.sendLocalNotificationDelegate("chat badge", alertEnabled: false, soundEnabled: false, badgeEnabled: badgeEnabled, badgeCount: count)
            }
    }
    
    func sendLocalNotification(_ identifier:String, title:String = "", subtitle: String = "", body:String = "", badgeCount: Int?) {
            UNUserNotificationCenter.current().getNotificationSettings() {
                (settings) in
                let soundEnabled = (settings.soundSetting == .enabled)
                let alertEnabled = (settings.alertSetting == .enabled)
                let badgeEnabled = badgeCount == nil ? false : (settings.badgeSetting == .enabled)
                self.sendLocalNotificationDelegate(identifier, alertEnabled: alertEnabled, soundEnabled: soundEnabled, badgeEnabled: badgeEnabled, title: title, subtitle: subtitle, body: body, badgeCount: badgeCount ?? 0)
            }
    }
    
    func clearAllNotifications() {
        setAppBadgeNumber(0)
            let center = UNUserNotificationCenter.current()
            center.removeAllPendingNotificationRequests() // remove all pending notifications which are not delivered yet but scheduled.
            center.removeAllDeliveredNotifications() // To remove all delivered notifications
    }
}
