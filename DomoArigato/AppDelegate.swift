//
//  AppDelegate.swift
//  DomoArigato
//
//  Created by FLK on 20/10/2015.
//  Copyright © 2015 FLKone. All rights reserved.
//

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        Crittercism.enableWithAppID(kCrittercismAPI)
        
        UIApplication.sharedApplication().setStatusBarHidden(false, withAnimation: UIStatusBarAnimation.Slide)
        //UINavigationBar.appearance().barTintColor = UIColor(red: 0, green: 143.0/255.0, blue: 211.0/255.0, alpha: 1.0)
        UINavigationBar.appearance().barTintColor = UIColor(red: 0, green: 93.0/255.0, blue: 177.0/255.0, alpha: 1.0)
        UINavigationBar.appearance().tintColor = UIColor.whiteColor()
        
        let barShadow: NSShadow = NSShadow()
        barShadow.shadowColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.8)
        barShadow.shadowOffset = CGSize(width: 0, height: 1)
        
        let textTitleOptions = [NSForegroundColorAttributeName: UIColor.whiteColor()]
        UINavigationBar.appearance().titleTextAttributes = textTitleOptions

        

        UINavigationBar.appearance().translucent = true
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
        // Check if widget changed data..
        let sharedDefaults = NSUserDefaults(suiteName: kAppGroup)!
        NSLog("applicationDidBecomeActive")
        if sharedDefaults.boolForKey(kWidgetModelChanged) {
            NSLog("kWidgetModelChanged")

            sharedDefaults.removeObjectForKey(kWidgetModelChanged)
            sharedDefaults.synchronize()
            NSNotificationCenter.defaultCenter().postNotificationName(kContextChangedNotification, object: nil)
        }
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
    }
}

