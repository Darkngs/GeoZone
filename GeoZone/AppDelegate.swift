//
//  AppDelegate.swift
//  GeoZone
//
//  Created by Mykola Golyash on 1/17/19.
//  Copyright © 2019 Mykola Golyash. All rights reserved.
//

import UIKit
import CoreLocation
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
   
   var window: UIWindow?
   
   let locationManager = CLLocationManager()
   
   func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
      locationManager.delegate = self
      locationManager.requestAlwaysAuthorization()
      
      let options: UNAuthorizationOptions = [.badge, .sound, .alert]
      UNUserNotificationCenter.current().requestAuthorization(options: options) { success, error in
         if let error = error {
            print("Error: \(error)")
         }
      }
      
      return true
   }
   
   func applicationWillResignActive(_ application: UIApplication) {
      // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
      // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
   }
   
   func applicationDidEnterBackground(_ application: UIApplication) {
      // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
      // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
   }
   
   func applicationWillEnterForeground(_ application: UIApplication) {
      // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
   }
   
   func applicationDidBecomeActive(_ application: UIApplication) {
      application.applicationIconBadgeNumber = 0
      UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
      UNUserNotificationCenter.current().removeAllDeliveredNotifications()
   }
   
   func applicationWillTerminate(_ application: UIApplication) {
      // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
   }
   
   //MARK: -
   
   func handleEvent(for region: CLRegion!) {
      if UIApplication.shared.applicationState == .active {
         guard let message = note(from: region.identifier) else {
            return
         }
         
         window?.rootViewController?.showAlert(withTitle: nil, message: message)
      } else {
         guard let body = note(from: region.identifier) else {
            return
         }
         
         let notificationContent = UNMutableNotificationContent()
         notificationContent.body = body
         notificationContent.sound = UNNotificationSound.default
         notificationContent.badge = UIApplication.shared.applicationIconBadgeNumber + 1 as NSNumber
         let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
         let request = UNNotificationRequest(identifier: "location_change", content: notificationContent, trigger: trigger)
         UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
               print("Error: \(error)")
            }
         }
      }
   }
   
   func geoItem(from identifier: String) -> GeoItem? {
      return GeoItem.allGeoItems().filter({
         $0.identifier == identifier
      }).first
   }
   
   func note(from identifier: String) -> String? {
      return geoItem(from: identifier)?.note
   }
}

extension AppDelegate: CLLocationManagerDelegate {
   
   func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
      if region is CLCircularRegion {
         handleEvent(for: region)
      }
   }
   
   func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
      let identifier = "Test SSID name"
      let currentSSID = currentSSIDs().filter({
         $0 == identifier
      }).first
      if let currentSSID = currentSSID {
         window?.rootViewController?.showAlert(withTitle: nil, message: "You are stil connected to \(currentSSID)!")
      } else if region is CLCircularRegion {
         handleEvent(for: region)
      }
   }
}
