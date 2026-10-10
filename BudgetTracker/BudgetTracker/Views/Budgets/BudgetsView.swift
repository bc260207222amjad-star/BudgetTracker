//
//  BudgetsView.swift
//  BudgetTracker
//
//  Created by ali on 10/10/2026.
//

import SwiftUI

public struct BudgetsView: View {
    @ObservedObject private var theme = ThemeManager.shared
    @ObservedObject private var currency = CurrencyManager.shared
    
    @State private var currentMonth: Date = Date()
    @State private var budgetStatuses: [BudgetStatus] = []
    @State private var overallStatus: BudgetStatus?
    @State private var showAddBudget = false
    @State private var editingBudget: BudgetEntity?
    @State private var budgetToDelete: BudgetEntity?
    @State private var showDeleteAlert = false
    
    private let calendar = Calendar.current
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 1. Month Navigation Header
                    monthNavigationHeader
                    
                    // 2. Overall Monthly Budget Card (if exists)
                    if let overall = overallStatus {
                        overallBudgetHeroCard(status: overall)
                    }
                    
                    // 3. Category Budgets
                    categoryBudgetsSection
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(theme.colors.backgroundColor.ignoresSafeArea())
            .navigationTitle("Budgets")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showAddBudget = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                    }
                }
            }
            .sheet(isPresented: $showAddBudget) {
                AddBudgetView(onDismiss: { loadData() })
            }
            .sheet(item: $editingBudget) { budget in
                AddBudgetView(budgetToEdit: budget, onDismiss: { loadData() })
            }
            .alert("Delete Budget", isPresented: $showDeleteAlert, presenting: budgetToDelete) { b in
                Button("Delete", role: .destructive) {
                    BudgetManager.shared.deleteBudget(b)
                    loadData()
                }
                Button("Cancel", role: .cancel) {}
            } message: { b in
                Text("Are you sure you want to delete '\(b.name ?? "Budget")'?")
            }
            .onAppear {
                loadData()
            }
            .refreshable {
                loadData()
            }
        }
    }
    
    // MARK: - Month Navigation Header
    
    private var monthNavigationHeader: some View {
        HStack {
            Button(action: {
                changeMonth(by: -1)
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(theme.colors.textColor)
                    .padding(8)
                    .background(theme.colors.cardColor)
                    .clipShape(Circle())
            }
            
            Spacer()
            
            Text(formattedMonth(currentMonth))
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(theme.colors.textColor)
            
            Spacer()
            
            Button(action: {
                changeMonth(by: 1)
            }) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(theme.colors.textColor)
                    .padding(8)
                    .background(theme.colors.cardColor)
                    .clipShape(Circle())
            }
        }
    }
    
    // MARK: - Overall Budget Card
    
    private func overallBudgetHeroCard(status: BudgetStatus) -> some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("OVERALL MONTHLY BUDGET")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(theme.colors.secondaryTextColor)
                            .tracking(0.5)
                        
                        Text(status.budget.name ?? "Monthly Budget")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(theme.colors.textColor)
                    }
                    
                    Spacer()
                    
                    statusPill(status: status)
                }
                
                // Progress Bar
                CustomProgressBar(
                    progress: min(status.percentage, 1.0),
                    color: Color(status.level.color)
                )
                
                // Metrics
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Spent")
                            .font(.system(size: 12))
                            .foregroundColor(theme.colors.secondaryTextColor)
                        Text(currency.format(status.usedAmount))
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .foregroundColor(theme.colors.textColor)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .center, spacing: 2) {
                        Text("Limit")
                            .font(.system(size: 12))
                            .foregroundColor(theme.colors.secondaryTextColor)
                        Text(currency.format(status.limitAmount))
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .foregroundColor(theme.colors.textColor)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Remaining")
                            .font(.system(size: 12))
                            .foregroundColor(theme.colors.secondaryTextColor)
                        let remaining = status.remainingAmount
                        Text(currency.format(max(remaining, 0)))
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .foregroundColor(remaining >= 0 ? theme.colors.successColor : theme.colors.dangerColor)
                    }
                }
                
                Divider()
                    .background(theme.colors.separatorColor.opacity(0.4))
                
                // Daily Safe Spend
                let daysLeft = daysRemainingInMonth()
                let dailySafe = daysLeft > 0 ? max(status.remainingAmount, 0) / Double(daysLeft) : 0
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundColor(theme.colors.primaryColor)
                        .font(.system(size: 14))
                    
                    Text("Daily safe spend: ")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(theme.colors.secondaryTextColor)
                    +
                    Text("\(currency.format(dailySafe)) / day")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(theme.colors.textColor)
                    
                    Spacer()
                    
                    Text("\(daysLeft) days left")
                        .font(.system(size: 12))
                        .foregroundColor(theme.colors.secondaryTextColor)
                }
            }
        }
    }
    
    // MARK: - Category Budgets Section
    
    private var categoryBudgetsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            let categoryStatuses = budgetStatuses.filter { $0.budget.category != nil }
            
            HStack {
                Text("Category Budgets")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(theme.colors.textColor)
                
                Spacer()
                
                Text("\(categoryStatuses.count) active")
                    .font(.system(size: 13))
                    .foregroundColor(theme.colors.secondaryTextColor)
            }
            
            if categoryStatuses.isEmpty && overallStatus == nil {
                EmptyStateContainer(
                    iconName: "chart.pie.fill",
                    title: "No Budgets Yet",
                    subtitle: "Set monthly spending limits for categories like Food, Transport, and Shopping to stay in control.",
                    buttonTitle: "+ Create Budget",
                    action: { showAddBudget = true }
                )
            } else if categoryStatuses.isEmpty {
                CardContainer {
                    Text("No category-specific budgets set for this month.")
                        .font(.system(size: 14))
                        .foregroundColor(theme.colors.secondaryTextColor)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 16)
                }
            } else {
                VStack(spacing: 12) {
                    ForEach(categoryStatuses, id: \.budget.id) { status in
                        categoryBudgetCard(status: status)
                    }
                }
            }
        }
    }
    
    private func categoryBudgetCard(status: BudgetStatus) -> some View {
        let catName = status.budget.category ?? "Other"
        let cat = CategoryManager.shared.category(named: catName)
        let statusColor = Color(status.level.color)
        
        return CardContainer {
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    Circle()
                        .fill(cat.color.opacity(0.15))
                        .frame(width: 42, height: 42)
                        .overlay(
                            Image(systemName: cat.iconName)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(cat.color)
                        )
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(status.budget.name ?? catName)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(theme.colors.textColor)
                        
                        Text("\(currency.format(status.usedAmount)) of \(currency.format(status.limitAmount))")
                            .font(.system(size: 12))
                            .foregroundColor(theme.colors.secondaryTextColor)
                    }
                    
                    Spacer()
                    
                    statusPill(status: status)
                    
                    Menu {
                        Button(action: {
                            editingBudget = status.budget
                        }) {
                            Label("Edit", systemImage: "pencil")
                        }
                        
                        Button(role: .destructive, action: {
                            budgetToDelete = status.budget
                            showDeleteAlert = true
                        }) {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 16))
                            .foregroundColor(theme.colors.secondaryTextColor)
                            .padding(6)
                    }
                }
                
                CustomProgressBar(
                    progress: min(status.percentage, 1.0),
                    color: statusColor
                )
                
                HStack {
                    Text("\(Int(min(status.percentage * 100, 999)))% used")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(statusColor)
                    
                    Spacer()
                    
                    let remaining = status.remainingAmount
                    Text(remaining >= 0 ? "\(currency.format(remaining)) left" : "Over by \(currency.format(abs(remaining)))")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(remaining >= 0 ? theme.colors.secondaryTextColor : theme.colors.dangerColor)
                }
            }
        }
    }
    
    private func statusPill(status: BudgetStatus) -> some View {
        let color = Color(status.level.color)
        return Text(status.level.label)
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }
    
    // MARK: - Logic & Helpers
    
    private func loadData() {
        budgetStatuses = BudgetManager.shared.getBudgetStatuses(for: currentMonth)
        overallStatus = budgetStatuses.first { $0.budget.category == nil }
    }
    
    private func changeMonth(by value: Int) {
        if let newDate = calendar.date(byAdding: .month, value: value, to: currentMonth) {
            currentMonth = newDate
            loadData()
        }
    }
    
    private func formattedMonth(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
    
    private func daysRemainingInMonth() -> Int {
        guard let range = calendar.range(of: .day, in: .month, for: currentMonth) else { return 0 }
        let currentDay = calendar.component(.day, from: Date())
        let totalDays = range.count
        return max(totalDays - currentDay, 1)
    }
}
