//
//  AppDelegate.swift
//  OpenWeather
//
//  Created by Nik Rodionov on 27.01.2020.
//  Copyright © 2020 nrodionov. All rights reserved.
//

import UIKit
import Firebase

/**
 main() {
    while(True) { // RunLoop
        autoreleasepool {
            UIApplication.touches()
            UIApplication.selector()
        }
    }
 }
 */
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    let queue = DispatchQueue(label: "my_queue", qos: .background)
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        FirebaseApp.configure()
        
        PurchaseManager.shared.prepare()
        
        
        
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


}

