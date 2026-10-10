//
//  SettingsView.swift
//  BudgetTracker
//
//  Created by ali on 10/10/2026.
//

import SwiftUI
import CoreData

public struct SettingsView: View {
    @ObservedObject private var theme = ThemeManager.shared
    @ObservedObject private var currency = CurrencyManager.shared
    @ObservedObject private var auth = BiometricAuthManager.shared
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = true
    
    @State private var dailyReminderEnabled: Bool = NotificationManager.shared.isDailyReminderEnabled()
    @State private var reminderTime: Date = NotificationManager.shared.getReminderTime()
    @State private var budgetAlertsEnabled: Bool = NotificationManager.shared.isBudgetAlertsEnabled()
    
    @State private var showResetConfirmation = false
    @State private var showSampleDataLoadedAlert = false
    @State private var exportURL: URL?
    @State private var showShareSheet = false
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            List {
                // 1. Appearance Section
                Section(header: Text("APPEARANCE").font(.caption.bold())) {
                    Picker("Color Theme", selection: $theme.currentTheme) {
                        ForEach(AppThemeType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                // 2. Currency Section
                Section(header: Text("CURRENCY").font(.caption.bold())) {
                    Picker("Primary Currency", selection: $currency.currentCurrency) {
                        ForEach(CurrencyModel.popularCurrencies) { c in
                            Text("\(c.code) (\(c.symbol)) - \(c.name)").tag(c)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                // 3. Security & Privacy Section
                Section(header: Text("SECURITY & PRIVACY").font(.caption.bold())) {
                    Toggle(isOn: $auth.isBiometricAuthEnabled) {
                        Label("Face ID / Passcode Lock", systemImage: "faceid")
                    }
                    
                    Toggle(isOn: $auth.hideBalance) {
                        Label("Hide Balances by Default", systemImage: "eye.slash")
                    }
                    
                    Toggle(isOn: $auth.hideTransactionAmounts) {
                        Label("Hide Amounts in List", systemImage: "lock.shield")
                    }
                }
                
                // 4. Notifications Section
                Section(header: Text("NOTIFICATIONS").font(.caption.bold())) {
                    Toggle(isOn: $dailyReminderEnabled) {
                        Label("Daily Logging Reminder", systemImage: "bell.badge")
                    }
                    .onChange(of: dailyReminderEnabled) { enabled in
                        NotificationManager.shared.setDailyReminder(enabled: enabled, at: reminderTime)
                    }
                    
                    if dailyReminderEnabled {
                        DatePicker("Reminder Time", selection: $reminderTime, displayedComponents: [.hourAndMinute])
                            .onChange(of: reminderTime) { newTime in
                                NotificationManager.shared.setDailyReminder(enabled: true, at: newTime)
                            }
                    }
                    
                    Toggle(isOn: $budgetAlertsEnabled) {
                        Label("Budget Threshold Alerts", systemImage: "exclamationmark.triangle")
                    }
                    .onChange(of: budgetAlertsEnabled) { enabled in
                        NotificationManager.shared.setBudgetAlerts(enabled: enabled)
                    }
                }
                
                // 5. Financial Management Tools
                Section(header: Text("FINANCIAL TOOLS").font(.caption.bold())) {
                    NavigationLink(destination: AccountsView()) {
                        Label("Accounts & Wallets", systemImage: "building.columns.fill")
                    }
                    
                    NavigationLink(destination: DebtTrackerView()) {
                        Label("Debt Payoff Accelerator", systemImage: "creditcard.and.123")
                    }
                    
                    NavigationLink(destination: NetWorthView()) {
                        Label("Net Worth Tracker", systemImage: "chart.line.uptrend.xyaxis.circle.fill")
                    }
                    
                    NavigationLink(destination: CategoryManagerView()) {
                        Label("Manage Categories", systemImage: "tag.fill")
                    }
                }
                
                // 6. Data Management Section
                Section(header: Text("DATA & EXPORT").font(.caption.bold())) {
                    Button(action: { exportPDF() }) {
                        Label("Export Financial PDF", systemImage: "doc.richtext")
                            .foregroundColor(theme.colors.textColor)
                    }
                    
                    Button(action: { exportCSV() }) {
                        Label("Export Transactions CSV", systemImage: "tablecells")
                            .foregroundColor(theme.colors.textColor)
                    }
                    
                    Button(action: { loadSampleData() }) {
                        Label("Load Demo Sample Data", systemImage: "wand.and.stars")
                            .foregroundColor(theme.colors.primaryColor)
                    }
                    
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        hasCompletedOnboarding = false
                    }) {
                        Label("Replay Onboarding Tour", systemImage: "arrow.counterclockwise")
                            .foregroundColor(theme.colors.textColor)
                    }
                    
                    Button(role: .destructive, action: { showResetConfirmation = true }) {
                        Label("Erase All Data", systemImage: "trash.fill")
                    }
                }
                
                // 7. About & Privacy Guarantee
                Section(header: Text("ABOUT & PRIVACY").font(.caption.bold())) {
                    HStack {
                        Text("App Version")
                        Spacer()
                        Text("1.0.0 (Build 1)")
                            .foregroundColor(theme.colors.secondaryTextColor)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.shield.fill")
                                .foregroundColor(theme.colors.successColor)
                            Text("100% Offline & Private")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(theme.colors.textColor)
                        }
                        
                        Text("BudgetTracker operates purely on your device. No analytics, no third-party servers, and zero cloud tracking. Your financial privacy is strictly yours.")
                            .font(.system(size: 12))
                            .foregroundColor(theme.colors.secondaryTextColor)
                            .lineSpacing(2)
                    }
                    .padding(.vertical, 4)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showShareSheet) {
                if let url = exportURL {
                    ShareActivityView(activityItems: [url])
                }
            }
            .alert("Load Sample Data", isPresented: $showSampleDataLoadedAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Sample transactions, budgets, accounts, and debts have been populated successfully!")
            }
            .alert("Reset All Data", isPresented: $showResetConfirmation) {
                Button("Erase Everything", role: .destructive) {
                    resetAllData()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure? This will permanently delete all transactions, budgets, accounts, and goals from this device.")
            }
        }
    }
    
    // MARK: - Handlers
    
    private func exportPDF() {
        if let url = ExportManager.shared.generatePDFReport() {
            exportURL = url
            showShareSheet = true
        }
    }
    
    private func exportCSV() {
        if let url = ExportManager.shared.exportTransactionsCSV() {
            exportURL = url
            showShareSheet = true
        }
    }
    
    private func loadSampleData() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        SampleDataLoader.shared.loadSampleDataIfEmpty()
        showSampleDataLoadedAlert = true
    }
    
    private func resetAllData() {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        let context = CoreDataManager.shared.viewContext
        let entities = ["TransactionEntity", "BudgetEntity", "AccountEntity", "RecurringTransactionEntity", "DebtEntity", "SavingsGoalEntity"]
        for entity in entities {
            let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
            let deleteReq = NSBatchDeleteRequest(fetchRequest: fetch)
            _ = try? context.execute(deleteReq)
        }
        CoreDataManager.shared.saveContext()
        AccountManager.shared.ensureDefaultAccountsExist()
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}
