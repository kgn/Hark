//
//  AppDelegate.swift
//  Hark
//
//  Created by David Keegan on 9/24/14.
//  Copyright (c) 2014 David Keegan. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    lazy var window: UIWindow = {
        let window = UIWindow(frame: UIScreen.mainScreen().bounds)
        window.rootViewController = UIViewController()
        window.backgroundColor = UIColor.whiteColor()
        window.tintColor = UIColor(hex: 0xff3b30)
        return window
    }()

    lazy var textViewController: TextViewController = {
        let textViewController = TextViewController()
        return textViewController
    }()

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        self.window.rootViewController = UINavigationController(rootViewController: self.textViewController)
        self.window.makeKeyAndVisible()
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        self.textViewController.stopAutoSaveTimer()
        self.saveLastText()
    }

    func applicationDidBecomeActive(application: UIApplication) {
        self.textViewController.promptToReplaceTextFromPasteboard()
        self.textViewController.startAutoSaveTimer()
    }

    func applicationWillTerminate(application: UIApplication) {
        self.saveLastText()
    }

    func saveLastText() {
        NSUserDefaults.standardUserDefaults().setObject(self.textViewController.textView.text, forKey: "app.lastText")
    }

}

