//
//  AppDelegate.swift
//  SampleForageSDK
//
//  Created by Symphony on 16/10/22.
//

import UIKit
import ForageSDK

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        guard let infoDictionary: [String: Any] = Bundle.main.infoDictionary else { return false }
        guard let forageSdkEnv: String = infoDictionary["FORAGE_SDK_ENVIRONMENT"] as? String else { return false }
        ForageSDK.setup(
            ForageSDK.Config(environment: parseForageEnvString(forageSdkEnv))
        )
        return true
    }
    
    func parseForageEnvString(_ env: String) -> EnvironmentTarget {
        switch(env) {
            case ".dev": return EnvironmentTarget.dev
            case ".staging": return EnvironmentTarget.staging
            case ".sandbox": return EnvironmentTarget.sandbox
            case ".cert": return EnvironmentTarget.cert
            case ".prod": return EnvironmentTarget.prod
            default: return EnvironmentTarget.sandbox
        }
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

