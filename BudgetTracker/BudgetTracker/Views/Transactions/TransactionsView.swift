//
//  TransactionsView.swift
//  BudgetTracker
//
//  Created by ali on 10/10/2026.
//

import SwiftUI
import CoreData

public struct TransactionsView: View {
    @ObservedObject private var theme = ThemeManager.shared
    @ObservedObject private var currency = CurrencyManager.shared
    @ObservedObject private var auth = BiometricAuthManager.shared
    
    @State private var filterIndex = 0 // 0: All, 1: Income, 2: Expenses
    @State private var searchText = ""
    @State private var selectedCategory: String? = nil
    
    @State private var groups: [TransactionGroup] = []
    @State private var totalIncome: Double = 0
    @State private var totalExpenses: Double = 0
    
    @State private var showAddExpense = false
    @State private var showAddIncome = false
    @State private var showCalendar = false
    @State private var selectedTransaction: TransactionEntity?
    @State private var transactionToDelete: TransactionEntity?
    @State private var showDeleteConfirmation = false
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                // 1. Summary Banner Card
                summaryBanner
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
                
                // 2. Segmented Filter
                Picker("Filter", selection: $filterIndex) {
                    Text("All").tag(0)
                    Text("Income").tag(1)
                    Text("Expenses").tag(2)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .onChange(of: filterIndex) { _ in
                    loadData()
                }
                
                // 3. Transactions List grouped by date
                if groups.isEmpty {
                    Spacer()
                    EmptyStateContainer(
                        iconName: "list.bullet.rectangle.portrait",
                        title: "No transactions found",
                        subtitle: searchText.isEmpty ? "Start tracking by logging your income or expenses." : "No transactions match your search query.",
                        buttonTitle: "+ Add Expense",
                        action: { showAddExpense = true }
                    )
                    Spacer()
                } else {
                    List {
                        ForEach(groups) { group in
                            Section(header: sectionHeader(for: group)) {
                                ForEach(group.transactions, id: \.id) { item in
                                    transactionRow(item)
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            selectedTransaction = item
                                        }
                                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                            Button(role: .destructive) {
                                                transactionToDelete = item
                                                showDeleteConfirmation = true
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }
                                        }
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(theme.colors.backgroundColor.ignoresSafeArea())
            .navigationTitle("Transactions")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Search merchant, title, note...")
            .onChange(of: searchText) { _ in
                loadData()
            }
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button(action: { showCalendar = true }) {
                        Image(systemName: "calendar")
                    }
                    
                    Menu {
                        Button(action: { showAddExpense = true }) {
                            Label("Add Expense", systemImage: "plus")
                        }
                        Button(action: { showAddIncome = true }) {
                            Label("Add Income", systemImage: "arrow.down")
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                    }
                }
            }
            .sheet(isPresented: $showAddExpense) {
                AddExpenseView(onDismiss: { loadData() })
            }
            .sheet(isPresented: $showAddIncome) {
                AddIncomeView(onDismiss: { loadData() })
            }
            .sheet(isPresented: $showCalendar) {
                CalendarView()
            }
            .sheet(item: $selectedTransaction) { item in
                TransactionDetailView(transaction: item, onDismiss: { loadData() })
            }
            .alert("Delete Transaction", isPresented: $showDeleteConfirmation, presenting: transactionToDelete) { item in
                Button("Delete", role: .destructive) {
                    TransactionManager.shared.deleteTransaction(item)
                    loadData()
                }
                Button("Cancel", role: .cancel) {}
            } message: { item in
                Text("Are you sure you want to delete '\(item.title ?? "Transaction")'?")
            }
            .onAppear {
                loadData()
            }
        }
    }
    
    // MARK: - Summary Banner
    
    private var summaryBanner: some View {
        CardContainer {
            HStack(spacing: 8) {
                bannerPill(title: "INCOME", amount: totalIncome, color: theme.colors.successColor)
                
                Divider()
                    .frame(height: 32)
                
                bannerPill(title: "EXPENSES", amount: totalExpenses, color: theme.colors.dangerColor)
                
                Divider()
                    .frame(height: 32)
                
                let net = totalIncome - totalExpenses
                bannerPill(title: "NET", amount: net, color: net >= 0 ? theme.colors.primaryColor : theme.colors.dangerColor)
            }
        }
    }
    
    private func bannerPill(title: String, amount: Double, color: Color) -> some View {
        VStack(spacing: 3) {
            Text(title)
                .font(.system(size: 10, weight: .heavy))
                .foregroundColor(theme.colors.secondaryTextColor)
            
            if auth.hideTransactionAmounts {
                Text("••••••")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(color)
            } else {
                Text(currency.format(amount))
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Section Header & Row
    
    private func sectionHeader(for group: TransactionGroup) -> some View {
        HStack {
            Text(group.title)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(theme.colors.secondaryTextColor)
            
            Spacer()
            
            if !auth.hideTransactionAmounts {
                Text(currency.formatWithSign(group.netTotal, isIncome: group.netTotal >= 0))
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(group.netTotal >= 0 ? theme.colors.successColor : theme.colors.dangerColor)
            }
        }
    }
    
    private func subtitleText(for item: TransactionEntity) -> String {
        var details: [String] = []
        if let m = item.merchant, !m.isEmpty { details.append(m) }
        if let p = item.paymentMethod, !p.isEmpty { details.append(p) }
        if details.isEmpty { details.append(item.category ?? "General") }
        return details.joined(separator: " • ")
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
    
    private func transactionRow(_ item: TransactionEntity) -> some View {
        HStack(spacing: 12) {
            let cat = CategoryManager.shared.category(named: item.category ?? "")
            Circle()
                .fill(cat.color.opacity(0.14))
                .frame(width: 42, height: 42)
                .overlay(
                    Image(systemName: cat.iconName)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(cat.color)
                )
            
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 4) {
                    Text(item.title ?? "Transaction")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(theme.colors.textColor)
                    
                    if let receipt = item.receiptImagePath, !receipt.isEmpty {
                        Image(systemName: "paperclip")
                            .font(.system(size: 11))
                            .foregroundColor(theme.colors.secondaryTextColor)
                    }
                }
                
                Text(subtitleText(for: item))
                    .font(.system(size: 12))
                    .foregroundColor(theme.colors.secondaryTextColor)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 3) {
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
                
                if let d = item.date {
                    Text(formatTime(d))
                        .font(.system(size: 11))
                        .foregroundColor(theme.colors.secondaryTextColor.opacity(0.8))
                }
            }
        }
        .padding(.vertical, 4)
        .listRowBackground(theme.colors.cardColor)
    }
    
    // MARK: - Data Loading
    
    private func loadData() {
        var typeFilter: TransactionType? = nil
        if filterIndex == 1 { typeFilter = .income }
        if filterIndex == 2 { typeFilter = .expense }
        
        let all = TransactionManager.shared.fetchTransactions(
            type: typeFilter,
            category: selectedCategory,
            searchQuery: searchText.isEmpty ? nil : searchText
        )
        
        groups = TransactionManager.shared.groupTransactionsByDate(all)
        
        // Calculate totals
        var inc: Double = 0
        var exp: Double = 0
        for item in all {
            if item.type == TransactionType.income.rawValue {
                inc += item.amount
            } else if item.type == TransactionType.expense.rawValue {
                exp += item.amount
            }
        }
        totalIncome = inc
        totalExpenses = exp
    }
}
