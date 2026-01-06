//
//  AppDelegate.swift
//  FirestoreDataImporter
//
//  Created by Matvei Khlestov on 06.01.2026.
//

import UIKit
import FactoryKit
import FirebaseCore

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        FirebaseApp.configure()
        
        let window = UIWindow(frame: UIScreen.main.bounds)
        let viewModel = Container.shared.debugImportViewModel()
        let rootVC = FirestoreImportViewController(viewModel: viewModel)
        window.rootViewController = UINavigationController(rootViewController: rootVC)
        window.makeKeyAndVisible()
        return true
    }
    
    // MARK: UISceneSession Lifecycle
    
    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
}

