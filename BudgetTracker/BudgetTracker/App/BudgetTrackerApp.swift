//
//  BudgetTrackerApp.swift
//  BudgetTracker
//
//  Created by ali on 10/10/2026.
//

import SwiftUI
import UserNotifications

@main
struct BudgetTrackerApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var theme = ThemeManager.shared
    @StateObject private var auth = BiometricAuthManager.shared
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    
    init() {
        // 1. Initialize Core Data stack
        _ = CoreDataManager.shared
        
        // 2. Ensure initial default accounts exist
        AccountManager.shared.ensureDefaultAccountsExist()
        
        // 3. Process any pending recurring transactions
        TransactionManager.shared.processPendingRecurringTransactions()
        
        // 4. Request user notification authorization
        NotificationManager.shared.requestAuthorization()
        
        // 5. Update Home Screen widgets snapshot
        WidgetDataProvider.shared.updateWidgetData()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(theme.currentTheme.colorScheme)
            .environment(\.managedObjectContext, CoreDataManager.shared.viewContext)
            .onChange(of: scenePhase) { newPhase in
                switch newPhase {
                case .background:
                    auth.appDidEnterBackground()
                    WidgetDataProvider.shared.updateWidgetData()
                case .active:
                    auth.appWillEnterForeground()
                case .inactive:
                    break
                @unknown default:
                    break
                }
            }
        }
    }
}
