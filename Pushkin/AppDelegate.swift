//
//  AppDelegate.swift
//  Pushkin
//
//  Created by Alexey Salangin on 9/27/19.
//  Copyright © 2019 Alexey Salangin. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        self.window = UIWindow()
        self.window?.rootViewController = ChatViewController()
        self.window?.makeKeyAndVisible()
        UIWindow.appearance().tintColor = .appTintColor

        return true
    }

}

