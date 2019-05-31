//
//  AppDelegate.swift
//  LampControllerV2
//
//  Created by Chris Sainsbury on 15/1/19.
//  Copyright © 2019 Chris Sainsbury. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        let defaults = UserDefaults.standard
        let connected = ["connection" : false]
        let serverIP = ["serverIP" : ""]
        let serverPort = ["serverPort" : Int32(56702)]
        let manualEnabled = ["manualEnabled" : 0]
        let manHue = ["manHue" : "180"]
        let manBri = ["manBri" : "050"]
        let manSat = ["manSat" : "050"]
        let savedTrans = ["savedTrans" : "Standard"]
        let savedWake = ["savedWake" : "00:00"]
        let savedSleep = ["savedSleep" : "00:00"]
        let mBri = ["mBri" : "100"]
        let nBri = ["nBri" : "100"]
        let dBri = ["dBri" : "100"]
        let mHue = ["mHue" : "100"]
        let nHue = ["nHue" : "100"]
        let dHue = ["dHue" : "100"]
        let mSat = ["mSat" : "100"]
        let nSat = ["nSat" : "100"]
        let dSat = ["dSat" : "100"]
        defaults.register(defaults : connected)
        defaults.register(defaults : manHue)
        defaults.register(defaults : manBri)
        defaults.register(defaults : manSat)
        defaults.register(defaults : manualEnabled)
        defaults.register(defaults : serverIP)
        defaults.register(defaults : serverPort)
        defaults.register(defaults : savedTrans)
        defaults.register(defaults : savedWake)
        defaults.register(defaults : savedSleep)
        defaults.register(defaults : mBri)
        defaults.register(defaults : nBri)
        defaults.register(defaults : dBri)
        defaults.register(defaults : mHue)
        defaults.register(defaults : nHue)
        defaults.register(defaults : dHue)
        defaults.register(defaults : mSat)
        defaults.register(defaults : nSat)
        defaults.register(defaults : dSat)
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
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

