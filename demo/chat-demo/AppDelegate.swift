//
//  AppDelegate.swift
//  chat-demo
//
// Note on FCM:
// See sections marked "FCM" for Firebase Messaging support related code.
// The file "GoogleService-Info.plist" (download from Firebase console) is required for FCM to work.

import UIKit
import Firebase
import GMSLibrary

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    static var shared: AppDelegate { return UIApplication.shared.delegate as! AppDelegate }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // MARK: FCM start
        configureFCM(application)
        // MARK: FCM end
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    

    // MARK: GMSLibrary start
    var cometClient: ChatV2CometClient?
    var chatVC: ChatViewController?
    var chatDelegate: ChatDelegate?

    var serverSettings: GmsServerSettings?
    var serviceSettings: GmsServiceSettings?

    func connect(nickname: String?, email: String?, subject: String?, connectViewController: ConnectViewController) {
        // CONFIGURATIONS START HERE change hard-coded dummy values
       
        // Server settings
        let hostname = "gms.example.com" // required
        let port = 8080 // optional; default to 80 for HTTP, 443 for HTTPS
        let secureProtocol = true // true = use HTTPS (default); false = use HTTP

        let app = "genesys" // GMS app name; default to "genesys"
        let gmsUser = "sample-user" // optional
        let apiKey = "sample-API-key" // optional

        // Authorization header settings
        let authSettings = GmsAuthSettings.none // default
        // To use Basic Auth:
        // let authSettigns = GmsAuthSettings.basic("username", "password")
       
        // Push notification settings
        // let pushSettings = GmsPushNotificationSettings.none // default
        // Use FCM (see additional things setup in sections marked FCM in this file):
        let pushSettings = GmsPushNotificationSettings.fcm(fcmToken!, debug: true, language: "en-US", provider: "push-provider")

        // GMS service settings
        let serviceName = "customer-support"
        
        // CONFIGURATIONS END HERE
        
        do {
            
            serverSettings = try GmsServerSettings(hostname: hostname, port: port, app: app, secureProtocol: secureProtocol, gmsUser: gmsUser, apiKey: apiKey, authSettings: authSettings, pushSettings: pushSettings)
           serviceSettings = try GmsServiceSettings(serviceName)
        } catch {
           debugPrint("Setting initialization failed")
           return
        }
       
        var userSettings = GmsUserSettings()
       
        userSettings.nickname = nickname
        userSettings.email = email

        chatDelegate = ChatDelegate()
        cometClient = ChatV2CometClient(serviceSettings: serviceSettings!, serverSettings: serverSettings!, userSettings: userSettings, delegate: chatDelegate!)

        if let client = cometClient {
            client.requestChat(on: .global(qos: .userInitiated), subject: subject)
        }
    }
    // MARK: GMSLibrary end
    
    
    // MARK: FCM start
    let gcmMessageIDKey = "gcm.message_id"
    var fcmToken: String?

    func configureFCM(_ application: UIApplication) {
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
        application.registerForRemoteNotifications()
        // [END register_for_notifications]
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
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("Firebase registration token: \(fcmToken)")
        
        let dataDict:[String?: String?] = ["token": fcmToken]
        NotificationCenter.default.post(name: Notification.Name("FCMToken"), object: nil, userInfo: dataDict)
        // TODO: If necessary send token to application server.
        // Note: This callback is fired at each app startup and whenever a new token is generated.

        if let serverSettings = serverSettings {
            switch serverSettings.pushSettings {
            case .fcm:
                do {
                    self.serverSettings = try serverSettings.updateFcmToken(fcmToken ?? "")
                } catch {
                    print("[AppDelegate] cannot update FCM token in server settings: \(error)")
                }
            default:
                break
            }
        }

    }
    // [END refresh_token]
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
                content.sound = UNNotificationSound.default
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
