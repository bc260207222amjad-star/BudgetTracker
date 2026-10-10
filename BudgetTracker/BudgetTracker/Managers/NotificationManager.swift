//
//  NotificationManager.swift
//  BudgetTracker
//
//  Created by ali on 10/10/2026.
//

import Foundation
import UserNotifications

public class NotificationManager {
    public static let shared = NotificationManager()
    
    private let budgetAlertsKey = "BudgetTracker_Notifications_BudgetAlerts"
    private let billRemindersKey = "BudgetTracker_Notifications_BillReminders"
    private let savingsRemindersKey = "BudgetTracker_Notifications_SavingsReminders"
    private let monthlyReportsKey = "BudgetTracker_Notifications_MonthlyReports"
    private let dailyReminderKey = "BudgetTracker_Notifications_DailyReminder"
    private let reminderTimeKey = "BudgetTracker_Notifications_ReminderTime"
    
    private init() {}
    
    public func isDailyReminderEnabled() -> Bool {
        return UserDefaults.standard.bool(forKey: dailyReminderKey)
    }
    
    public func getReminderTime() -> Date {
        if let time = UserDefaults.standard.object(forKey: reminderTimeKey) as? Date {
            return time
        }
        var comps = DateComponents()
        comps.hour = 20
        comps.minute = 0
        return Calendar.current.date(from: comps) ?? Date()
    }
    
    public func isBudgetAlertsEnabled() -> Bool {
        return budgetAlertsEnabled
    }
    
    public func setDailyReminder(enabled: Bool, at time: Date) {
        UserDefaults.standard.set(enabled, forKey: dailyReminderKey)
        UserDefaults.standard.set(time, forKey: reminderTimeKey)
        
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["DailyLoggingReminder"])
        
        guard enabled else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Daily Budget Reminder"
        content.body = "Don't forget to log today's expenses and track your financial progress!"
        content.sound = .default
        
        let calendar = Calendar.current
        let comps = calendar.dateComponents([.hour, .minute], from: time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        let request = UNNotificationRequest(identifier: "DailyLoggingReminder", content: content, trigger: trigger)
        center.add(request)
    }
    
    public func setBudgetAlerts(enabled: Bool) {
        budgetAlertsEnabled = enabled
    }
    
    // MARK: - Permission
    
    public func requestAuthorization(completion: ((Bool) -> Void)? = nil) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                completion?(granted)
            }
        }
    }
    
    public func checkAuthorization(completion: @escaping (UNAuthorizationStatus) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(settings.authorizationStatus)
            }
        }
    }
    
    // MARK: - Notification Preferences
    
    public var budgetAlertsEnabled: Bool {
        get { UserDefaults.standard.object(forKey: budgetAlertsKey) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: budgetAlertsKey) }
    }
    
    public var billRemindersEnabled: Bool {
        get { UserDefaults.standard.object(forKey: billRemindersKey) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: billRemindersKey) }
    }
    
    public var savingsRemindersEnabled: Bool {
        get { UserDefaults.standard.object(forKey: savingsRemindersKey) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: savingsRemindersKey) }
    }
    
    public var monthlyReportsEnabled: Bool {
        get { UserDefaults.standard.object(forKey: monthlyReportsKey) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: monthlyReportsKey) }
    }
    
    // MARK: - Budget Alerts
    
    public func sendBudgetAlert(budgetName: String, percentage: Int, isExceeded: Bool, budgetId: UUID) {
        guard budgetAlertsEnabled else { return }
        
        let calendar = Calendar.current
        let comps = calendar.dateComponents([.year, .month], from: Date())
        let yearMonthKey = "\(comps.year ?? 0)_\(comps.month ?? 0)"
        let alertDedupKey = "BudgetAlert_Sent_\(budgetId.uuidString)_\(percentage)_\(yearMonthKey)"
        
        // Prevent duplicate notifications for the same threshold in the same month
        if UserDefaults.standard.bool(forKey: alertDedupKey) {
            return
        }
        
        let content = UNMutableNotificationContent()
        content.sound = .default
        
        if isExceeded {
            content.title = "Budget Exceeded!"
            content.body = "Your \(budgetName) budget has been exceeded."
        } else {
            content.title = "Budget Warning"
            content.body = "You've used \(percentage)% of your \(budgetName) budget."
        }
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: alertDedupKey, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if error == nil {
                UserDefaults.standard.set(true, forKey: alertDedupKey)
            }
        }
    }
    
    // MARK: - Bill Reminders
    
    public func scheduleBillReminder(title: String, amount: Double, dueDate: Date, reminderId: String) {
        guard billRemindersEnabled else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Upcoming Bill Due"
        content.body = "\(title) (\(CurrencyManager.shared.format(amount))) is due tomorrow."
        content.sound = .default
        
        // Remind 1 day before due date at 9:00 AM
        let calendar = Calendar.current
        guard let reminderDate = calendar.date(byAdding: .day, value: -1, to: dueDate) else { return }
        var comps = calendar.dateComponents([.year, .month, .day], from: reminderDate)
        comps.hour = 9
        comps.minute = 0
        
        guard let scheduledDate = calendar.date(from: comps), scheduledDate > Date() else { return }
        
        let triggerComps = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: scheduledDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComps, repeats: false)
        let request = UNNotificationRequest(identifier: "BillReminder_\(reminderId)", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Savings Goal Reminder
    
    public func sendSavingsMilestoneReminder(goalName: String, remainingAmount: Double) {
        guard savingsRemindersEnabled else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Savings Goal Update"
        content.body = "You're \(CurrencyManager.shared.format(remainingAmount)) away from your \(goalName) goal!"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}
