//
//  SceneDelegate.swift
//  BudgetTracker
//
//  Created by ali on 10/10/2026.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        let window = UIWindow(windowScene: windowScene)
        window.overrideUserInterfaceStyle = ThemeManager.shared.currentTheme.userInterfaceStyle
        
        let rootTabBar = MainTabBarController()
        window.rootViewController = rootTabBar
        
        self.window = window
        window.makeKeyAndVisible()
    }

    func sceneDidDisconnect(_ scene: UIScene) {
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        BiometricAuthManager.shared.appDidBecomeActive(window: window)
        if let mainTabBar = window?.rootViewController as? MainTabBarController {
            mainTabBar.checkInitialLock()
        }
        TransactionManager.shared.processPendingRecurringTransactions()
    }

    func sceneWillResignActive(_ scene: UIScene) {
        BiometricAuthManager.shared.appWillResignActive(window: window)
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        BiometricAuthManager.shared.appWillEnterForeground()
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        BiometricAuthManager.shared.appDidEnterBackground()
        WidgetDataProvider.shared.updateWidgetData()
    }
}
