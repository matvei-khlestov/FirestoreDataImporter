//
//  SceneDelegate.swift
//  FirestoreDataImporter
//
//  Created by Matvei Khlestov on 06.01.2026.
//

import UIKit
import FactoryKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        let window = UIWindow(windowScene: windowScene)
        let viewModel = Container.shared.debugImportViewModel()
        let rootVC = FirestoreImportViewController(viewModel: viewModel)
        window.rootViewController = UINavigationController(rootViewController: rootVC)
        window.makeKeyAndVisible()
        self.window = window
    }
}

