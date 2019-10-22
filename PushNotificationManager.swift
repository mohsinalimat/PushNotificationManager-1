import Firebase
import FirebaseMessaging
import UIKit
import UserNotifications

class PushNotificationManager: NSObject, MessagingDelegate, UNUserNotificationCenterDelegate {
    
    static let shared = PushNotificationManager()
    
    private override init(){}
    
    /// APN Token
    var deviceToken: String?
    
    /// Firebase generated token
    var fcmToken: String = {
        let _token = Messaging.messaging().fcmToken
        return _token ?? ""
    }()
    
    
    
    /// return if  remote notification register or yet
    var isRegisteredForRemoteNotifications: Bool = {
        return UIApplication.shared.isRegisteredForRemoteNotifications
    }()
    
    /// Trigger bind when user allow the push notification for ios 10 and below 10
    var didAllowPunshNotification: ()->() = {}
    
    /// Trigger bind when tab on notification and return data to call back
    var didTabOnNotification: (_ data: PushNotificationData) -> () = {_ in}
    
    /// Trigger bind when swipe on notification and return data to call back
    var didSwipeOnNotification: (_ data: PushNotificationData) -> () = {_ in}
    
    /// Trigger bind when tab show more button on notification and return data to call back
    var didTabOnShowMoreButtonNotification: (_ data: PushNotificationData) -> () = {_ in}
    
    
    
    /// Sent APN Device Token to firebase
    /// call this function in didRegisterForRemoteNotificationsWithDeviceToken app delegate
    /// - Parameter deviceToken: Data
    func setUpDeviceToken(deviceToken: Data){
        Messaging.messaging().apnsToken = deviceToken
        self.deviceToken = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
    }
    
    /* Must have in didFinishLaunchingWithOptions Due to:
     Use the delegate object to respond to user-selected actions and to process incoming notifications when your app is in the foreground. For example, you might use your delegate to silence notifications when your app is in the foreground.
    To guarantee that your app responds to all actionable notifications, you must set the value of this property before your app finishes launching. For an iOS app, this means updating this property in the application(_:willFinishLaunchingWithOptions:) or application(_:didFinishLaunchingWithOptions:) method of the app delegate. Notifications that cause your app to be launched or delivered shortly after these methods finish executing.
     */
    func initiatePushnotificationDelegate(){
        // For iOS 10 display notification (sent via APNS)
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().delegate = self
        } else {
            // Fallback on earlier versions
        }
        // For iOS 10 data message (sent via FCM)
        Messaging.messaging().delegate = self
    }
    
    /// Register PushNotification
    /// call when when you want to register push for user to allow
    func registerForPushNotifications() {
        Messaging.messaging().isAutoInitEnabled = true
        if !isRegisteredForRemoteNotifications{
            if #available(iOS 10.0, *) {
                let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
                UNUserNotificationCenter.current().requestAuthorization(
                    options: authOptions,
                    completionHandler: {granted, _ in
                        if granted{
                            self.didAllowPunshNotification()
                        }else{
                            // not yet allow
                        }
                        
                })
            } else {
                let settings: UIUserNotificationSettings =
                    UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
                UIApplication.shared.registerUserNotificationSettings(settings)
            }
            UIApplication.shared.registerForRemoteNotifications()
            updatePushTokenIfNeeded()
        }
    }
    
    /// updatePushTokenIfNeeded
    func updatePushTokenIfNeeded() {
        if let _token = Messaging.messaging().fcmToken {
            fcmToken = _token
            print("FCM token 🥳🥳🥳🥳🥳🥳🥳🥳🥳🥳🥳🥳🥳🥳🥳🥳: \(_token)")
        }
    }
    
    /// Get FCM Token then call back
    /// - Parameter complete: (String) -> ()
    func getFCMToken(complete: @escaping (String)->()) {
        if let _token = Messaging.messaging().fcmToken {
            complete(_token)
        }
    }
        
    /// Delegate when receive remote message
    /// - Parameter messaging: Messaging
    /// - Parameter remoteMessage: MessagingRemoteMessage
    func messaging(_ messaging: Messaging, didReceive remoteMessage: MessagingRemoteMessage) {
        print(remoteMessage.appData) // or do whatever
    }
    
    /// Detegate from firebase when already reeceive RegistrationToken
    /// - Parameter messaging: Messaging
    /// - Parameter fcmToken: String
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        self.fcmToken = fcmToken
    }
    
    /// extractUserInfo
    /// - Parameter userInfo:  [AnyHashable : Any]
    func extractUserInfo(userInfo: [AnyHashable : Any]) -> (title: String, body: String) {
        var info = (title: "", body: "")
        guard let aps = userInfo["aps"] as? [String: Any] else { return info }
        guard let alert = aps["alert"] as? [String: Any] else { return info }
        let title = alert["title"] as? String ?? ""
        let body = alert["body"] as? String ?? ""
        info = (title: title, body: body)
        return info
    }
    
    /// handle when push notification base on application:
    /// if Application active trigger local push base on schedule else it will extracted data and trigger didTabOnNotification
    /// - Parameter application: UIApplication
    /// - Parameter userInfo: [AnyHashable : Any]
    func handlePushNotification(_ application: UIApplication, userInfo: [AnyHashable : Any]) {
        // Check applicationState
        if (application.applicationState == .active) {
            // Application is running in foreground
            self.fireLocalPush(wtih: userInfo)
        }
        else {
        // Application is brought from background or launched after terminated
            if let data = extractDataFromUserInfo(userInfo: userInfo){
                self.didTabOnNotification(data)
            }
        }
    }
    
    /// send LocalPush
    /// - Parameter userInfo: [AnyHashable : Any]
    func fireLocalPush(wtih userInfo: [AnyHashable : Any]){
        if #available(iOS 10.0, *) {
            let content = UNMutableNotificationContent()
            let alert = self.extractUserInfo(userInfo: userInfo)
            let identifier = userInfo["google.c.a.c_l"] as? String ?? "No Category Identifier founded"
            content.categoryIdentifier = identifier
            content.title = alert.title
            content.body = alert.body
            content.userInfo = userInfo
            content.sound = UNNotificationSound.default
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request) { (error) in
                // if the error is nil, that mean the local push is successfully push
                print(error?.localizedDescription)
            }
        } else {
            // Fallback on earlier versions
            let notification = UILocalNotification()
            let alert = self.extractUserInfo(userInfo: userInfo)
            notification.alertTitle = alert.title
            notification.alertBody = alert.body
            notification.userInfo = userInfo
            notification.repeatInterval = NSCalendar.Unit.nanosecond
            UIApplication.shared.cancelAllLocalNotifications()
            UIApplication.shared.scheduledLocalNotifications = [notification]
        }
    }
    
    func resetBadge(){
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
    
    func disableNotification() {
        UIApplication.shared.unregisterForRemoteNotifications()
    }
    
    
    
    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        resetBadge()
        let userInfo = response.notification.request.content.userInfo
        if let data = extractDataFromUserInfo(userInfo: userInfo){
            switch response.actionIdentifier {
            case UNNotificationDefaultActionIdentifier:
                // the user swiped to unlock
                print("Default identifier")
                didSwipeOnNotification(data)

            case "show":
                // the user tapped our "show more info…" button
                print("Show more information…")
                didTabOnShowMoreButtonNotification(data)
                break

            default:
                break
            }
            completionHandler()
        }
    }
    
    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void){
        completionHandler([.alert, .badge, .sound])
    }
    
    //Refresh Token
    func messaging(_ messaging: Messaging, didRefreshRegistrationToken fcmToken: String) {
        print("refreshToken")
        self.fcmToken = fcmToken
    }
}


extension PushNotificationManager{
    func subscribeNotification(){
//        APIWrapper.subscribeNotication(deviceToken: deviceToken ?? Utils.getDeviceId(), fcmToken: fcmToken) {
//            print("🥳🥳🥳🥳 SubscribeNotication Success 🥳🥳🥳🥳")
//        }
    }
    
    func unSubscribeNotification(){
//        APIWrapper.unSubscribeNotication {
//            print("💥💥💥💥 unSubscribeNotication Success 💥💥💥💥")
//        }
    }
}

extension PushNotificationManager{
    
    func extractDataFromUserInfo(userInfo: [AnyHashable : Any]) -> PushNotificationData? {
        let dict = userInfo as? [String: Any]
        let jsonString = dict?["data"] as? String
        let data = jsonString?.data(using: .utf8)
        if let dataDict = try? JSONSerialization.jsonObject(with: data!, options : .allowFragments) as? [String: Any] {
            // json is now a [String : Any] type
           let pushData = PushNotificationData(dictionary: dataDict)
           return pushData
        }
        return nil
    }
}
