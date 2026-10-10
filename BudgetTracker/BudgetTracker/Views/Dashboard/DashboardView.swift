//
//  DashboardView.swift
//  BudgetTracker
//
//  Created by ali on 10/10/2026.
//

import SwiftUI
import CoreData

public struct DashboardView: View {
    @ObservedObject private var theme = ThemeManager.shared
    @ObservedObject private var currency = CurrencyManager.shared
    @ObservedObject private var auth = BiometricAuthManager.shared
    
    @State private var summary = FinancialSummary()
    @State private var upcomingExpenses: [RecurringTransactionEntity] = []
    @State private var budgetStatuses: [BudgetStatus] = []
    @State private var recentTransactions: [TransactionEntity] = []
    
    @State private var showAddExpense = false
    @State private var showAddIncome = false
    @State private var showReceiptScanner = false
    @State private var showAIAssistant = false
    @State private var selectedTransactionForDetail: TransactionEntity?
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header: Greeting + Month
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(greetingText)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(theme.colors.textColor)
                            
                            Text(currentMonthText)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(theme.colors.secondaryTextColor)
                                .textCase(.uppercase)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            loadSampleDataAlert()
                        }) {
                            Image(systemName: "wand.and.stars")
                                .font(.system(size: 18))
                                .foregroundColor(theme.colors.primaryColor)
                                .padding(8)
                                .background(theme.colors.cardColor)
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    
                    // 1. Hero Balance Card
                    HeroBalanceCardView(summary: summary)
                        .padding(.horizontal, 16)
                    
                    // 2. Quick Action Circular Buttons
                    HStack(spacing: 16) {
                        ActionIconButtonView(title: "+ Expense", iconName: "plus", color: .red) {
                            showAddExpense = true
                        }
                        
                        ActionIconButtonView(title: "+ Income", iconName: "arrow.down", color: .green) {
                            showAddIncome = true
                        }
                        
                        ActionIconButtonView(title: "Scan Receipt", iconName: "doc.viewfinder.fill", color: .orange) {
                            showAddExpense = true
                        }
                        
                        ActionIconButtonView(title: "AI Assistant", iconName: "sparkles", color: .purple) {
                            showAIAssistant = true
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    
                    // 3. Upcoming Recurring Expenses
                    upcomingExpensesSection
                        .padding(.horizontal, 16)
                    
                    // 4. Budget Overview Section
                    budgetOverviewSection
                        .padding(.horizontal, 16)
                    
                    // 5. Recent Transactions Section
                    recentTransactionsSection
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)
                }
            }
            .background(theme.colors.backgroundColor.ignoresSafeArea())
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(theme.colors.backgroundColor, for: .navigationBar)
            .sheet(isPresented: $showAddExpense) {
                AddExpenseView(onDismiss: { reloadAllData() })
            }
            .sheet(isPresented: $showAddIncome) {
                AddIncomeView(onDismiss: { reloadAllData() })
            }
            .sheet(isPresented: $showAIAssistant) {
                AIAssistantView()
            }
            .sheet(item: $selectedTransactionForDetail) { item in
                TransactionDetailView(transaction: item, onDismiss: { reloadAllData() })
            }
            .onAppear {
                reloadAllData()
            }
            .refreshable {
                reloadAllData()
            }
        }
    }
    
    // MARK: - Upcoming Expenses Section
    
    private var upcomingExpensesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Upcoming Expenses")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(theme.colors.textColor)
            
            CardContainer {
                if upcomingExpenses.isEmpty {
                    Text("No upcoming recurring expenses due this month.")
                        .font(.system(size: 14))
                        .foregroundColor(theme.colors.secondaryTextColor)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 6)
                } else {
                    VStack(spacing: 12) {
                        ForEach(upcomingExpenses, id: \.id) { item in
                            HStack {
                                Circle()
                                    .fill(Color.orange.opacity(0.14))
                                    .frame(width: 36, height: 36)
                                    .overlay(
                                        Image(systemName: "calendar.badge.clock")
                                            .font(.system(size: 15))
                                            .foregroundColor(.orange)
                                    )
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.title ?? "Recurring Expense")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(theme.colors.textColor)
                                    
                                    if let nextDate = item.nextDate {
                                        Text(formattedDueDate(nextDate))
                                            .font(.system(size: 12))
                                            .foregroundColor(theme.colors.secondaryTextColor)
                                    }
                                }
                                
                                Spacer()
                                
                                Text("-\(currency.format(item.amount))")
                                    .font(.system(size: 15, weight: .bold, design: .monospaced))
                                    .foregroundColor(theme.colors.dangerColor)
                            }
                            
                            if item.id != upcomingExpenses.last?.id {
                                Divider()
                                    .background(theme.colors.separatorColor.opacity(0.3))
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Budget Overview Section
    
    private var budgetOverviewSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Budget Overview")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(theme.colors.textColor)
            
            CardContainer {
                if budgetStatuses.isEmpty {
                    Text("No budgets created yet. Set spending targets in the Budgets tab.")
                        .font(.system(size: 14))
                        .foregroundColor(theme.colors.secondaryTextColor)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 6)
                } else {
                    VStack(spacing: 16) {
                        ForEach(Array(budgetStatuses.prefix(3)), id: \.budget.id) { status in
                            VStack(spacing: 8) {
                                HStack {
                                    Text(status.budget.name ?? "Budget")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(theme.colors.textColor)
                                    
                                    Spacer()
                                    
                                    Text("\(currency.format(status.usedAmount)) / \(currency.format(status.limitAmount))")
                                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                                        .foregroundColor(theme.colors.secondaryTextColor)
                                }
                                
                                let progColor = status.percentage >= 1.0 ? theme.colors.dangerColor : (status.percentage >= 0.8 ? theme.colors.warningColor : theme.colors.primaryColor)
                                CustomProgressBar(progress: status.percentage, color: progColor)
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Recent Transactions Section
    
    private var recentTransactionsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Recent Transactions")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(theme.colors.textColor)
                
                Spacer()
            }
            
            CardContainer {
                if recentTransactions.isEmpty {
                    Text("No transactions logged yet. Tap + Expense or + Income to begin.")
                        .font(.system(size: 14))
                        .foregroundColor(theme.colors.secondaryTextColor)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                } else {
                    VStack(spacing: 12) {
                        ForEach(recentTransactions, id: \.id) { item in
                            Button(action: {
                                selectedTransactionForDetail = item
                            }) {
                                HStack(spacing: 12) {
                                    let cat = CategoryManager.shared.category(named: item.category ?? "")
                                    Circle()
                                        .fill(cat.color.opacity(0.14))
                                        .frame(width: 40, height: 40)
                                        .overlay(
                                            Image(systemName: cat.iconName)
                                                .font(.system(size: 16, weight: .semibold))
                                                .foregroundColor(cat.color)
                                        )
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.title ?? "Transaction")
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(theme.colors.textColor)
                                        
                                        Text(item.category ?? "General")
                                            .font(.system(size: 12))
                                            .foregroundColor(theme.colors.secondaryTextColor)
                                    }
                                    
                                    Spacer()
                                    
                                    let isIncome = item.type == TransactionType.income.rawValue
                                    if auth.hideTransactionAmounts {
                                        Text("••••••")
                                            .font(.system(size: 15, weight: .bold, design: .monospaced))
                                            .foregroundColor(theme.colors.secondaryTextColor)
                                    } else {
                                        Text(currency.formatWithSign(item.amount, isIncome: isIncome))
                                            .font(.system(size: 15, weight: .bold, design: .monospaced))
                                            .foregroundColor(isIncome ? theme.colors.successColor : theme.colors.dangerColor)
                                    }
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            if item.id != recentTransactions.last?.id {
                                Divider()
                                    .background(theme.colors.separatorColor.opacity(0.3))
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return "Good morning ☀️" }
        if hour < 17 { return "Good afternoon 👋" }
        return "Good evening 🌙"
    }
    
    private var currentMonthText: String {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f.string(from: Date())
    }
    
    private func formattedDueDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return "Due " + f.string(from: date)
    }
    
    private func reloadAllData() {
        summary = TransactionManager.shared.getFinancialSummary()
        recentTransactions = TransactionManager.shared.fetchTransactions(limit: 6)
        budgetStatuses = BudgetManager.shared.getBudgetStatuses()
        
        let now = Date()
        let request = NSFetchRequest<RecurringTransactionEntity>(entityName: "RecurringTransactionEntity")
        request.predicate = NSPredicate(format: "isEnabled == YES AND nextDate >= %@", now as NSDate)
        request.sortDescriptors = [NSSortDescriptor(key: "nextDate", ascending: true)]
        request.fetchLimit = 3
        upcomingExpenses = (try? CoreDataManager.shared.viewContext.fetch(request)) ?? []
    }
    
    private func loadSampleDataAlert() {
        SampleDataLoader.shared.loadRealisticSampleData()
        reloadAllData()
    }
}
