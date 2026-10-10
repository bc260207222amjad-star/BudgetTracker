//
//  AppDelegate.swift
//  BudgetTracker
//
//  Created by ali on 10/10/2026.
//

import UIKit
import UserNotifications

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // 1. Initialize persistent storage
        _ = CoreDataManager.shared
        
        // 2. Ensure initial default accounts exist
        AccountManager.shared.ensureDefaultAccountsExist()
        
        // 3. Process recurring transactions on startup
        TransactionManager.shared.processPendingRecurringTransactions()
        
        // 4. Request notification authorization
        NotificationManager.shared.requestAuthorization()
        
        // 5. Update Home Screen widgets snapshot
        WidgetDataProvider.shared.updateWidgetData()
        
        return true
    }

    // MARK: - UISceneSession Lifecycle

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
        configuration.delegateClass = SceneDelegate.self
        return configuration
    }

    func application(
        _ application: UIApplication,
        didDiscardSceneSessions sceneSessions: Set<UISceneSession>
    ) {
    }
}
