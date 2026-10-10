//
//  CalendarView.swift
//  BudgetTracker
//
//  Created by ali on 10/10/2026.
//

import SwiftUI

public struct CalendarView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var theme = ThemeManager.shared
    @ObservedObject private var currency = CurrencyManager.shared
    
    @State private var currentMonth: Date = Date()
    @State private var selectedDate: Date = Date()
    @State private var allTransactions: [TransactionEntity] = []
    @State private var selectedDayTransactions: [TransactionEntity] = []
    @State private var selectedDetailTransaction: TransactionEntity?
    
    private let calendar = Calendar.current
    private let daysOfWeek = ["S", "M", "T", "W", "T", "F", "S"]
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 1. Month Navigation Header
                    monthNavigationHeader
                    
                    // 2. Calendar Grid Card
                    calendarGridCard
                    
                    // 3. Selected Day Summary & Transactions
                    selectedDaySection
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(theme.colors.backgroundColor.ignoresSafeArea())
            .navigationTitle("Calendar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button("Today") {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        currentMonth = Date()
                        selectedDate = Date()
                        updateSelectedDayTransactions()
                    }
                    .font(.system(size: 14, weight: .semibold))
                }
            }
            .sheet(item: $selectedDetailTransaction) { item in
                TransactionDetailView(transaction: item, onDismiss: {
                    loadData()
                })
            }
            .onAppear {
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
                    .padding(10)
                    .background(theme.colors.cardColor)
                    .clipShape(Circle())
            }
            
            Spacer()
            
            Text(monthTitle(for: currentMonth))
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(theme.colors.textColor)
            
            Spacer()
            
            Button(action: {
                changeMonth(by: 1)
            }) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(theme.colors.textColor)
                    .padding(10)
                    .background(theme.colors.cardColor)
                    .clipShape(Circle())
            }
        }
    }
    
    // MARK: - Calendar Grid Card
    
    private var calendarGridCard: some View {
        CardContainer {
            VStack(spacing: 12) {
                // Days of week row
                HStack {
                    ForEach(daysOfWeek, id: \.self) { day in
                        Text(day)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(theme.colors.secondaryTextColor)
                            .frame(maxWidth: .infinity)
                    }
                }
                
                Divider()
                    .background(theme.colors.separatorColor.opacity(0.4))
                
                // Days grid
                let days = generateDaysInMonth(for: currentMonth)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
                    ForEach(days, id: \.self) { date in
                        if let date = date {
                            dayCell(for: date)
                        } else {
                            Text("")
                                .frame(height: 38)
                        }
                    }
                }
            }
        }
    }
    
    private func dayCell(for date: Date) -> some View {
        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
        let isToday = calendar.isDateInToday(date)
        let dayNumber = calendar.component(.day, from: date)
        
        let dayTransactions = allTransactions.filter { item in
            guard let itemDate = item.date else { return false }
            return calendar.isDate(itemDate, inSameDayAs: date)
        }
        let hasIncome = dayTransactions.contains { $0.type == "income" }
        let hasExpense = dayTransactions.contains { $0.type == "expense" }
        
        return Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            selectedDate = date
            updateSelectedDayTransactions()
        }) {
            VStack(spacing: 4) {
                Text("\(dayNumber)")
                    .font(.system(size: 14, weight: isSelected || isToday ? .bold : .medium))
                    .foregroundColor(isSelected ? .white : (isToday ? theme.colors.primaryColor : theme.colors.textColor))
                
                // Transaction Indicator Dots
                HStack(spacing: 3) {
                    if hasIncome {
                        Circle()
                            .fill(isSelected ? Color.white : theme.colors.successColor)
                            .frame(width: 4, height: 4)
                    }
                    if hasExpense {
                        Circle()
                            .fill(isSelected ? Color.white : theme.colors.dangerColor)
                            .frame(width: 4, height: 4)
                    }
                }
                .frame(height: 4)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 38)
            .background(isSelected ? theme.colors.primaryColor : (isToday ? theme.colors.primaryColor.opacity(0.12) : Color.clear))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Selected Day Section
    
    private var selectedDaySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(formattedSelectedDate)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(theme.colors.textColor)
                
                Spacer()
                
                if !selectedDayTransactions.isEmpty {
                    let totalSpent = selectedDayTransactions.filter { $0.type == "expense" }.reduce(0) { $0 + $1.amount }
                    if totalSpent > 0 {
                        Text("Spent: \(currency.format(totalSpent))")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(theme.colors.dangerColor)
                    }
                }
            }
            
            if selectedDayTransactions.isEmpty {
                CardContainer {
                    Text("No transactions logged for this date.")
                        .font(.system(size: 14))
                        .foregroundColor(theme.colors.secondaryTextColor)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 16)
                }
            } else {
                VStack(spacing: 8) {
                    ForEach(selectedDayTransactions, id: \.id) { item in
                        Button(action: {
                            selectedDetailTransaction = item
                        }) {
                            HStack(spacing: 12) {
                                let isIncome = item.type == "income"
                                let cat = CategoryManager.shared.category(named: item.category ?? "Other")
                                
                                Circle()
                                    .fill((isIncome ? theme.colors.successColor : cat.color).opacity(0.14))
                                    .frame(width: 38, height: 38)
                                    .overlay(
                                        Image(systemName: isIncome ? "arrow.down" : cat.iconName)
                                            .font(.system(size: 16))
                                            .foregroundColor(isIncome ? theme.colors.successColor : cat.color)
                                    )
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.title ?? "Transaction")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(theme.colors.textColor)
                                    
                                    Text(item.category ?? "Other")
                                        .font(.system(size: 12))
                                        .foregroundColor(theme.colors.secondaryTextColor)
                                }
                                
                                Spacer()
                                
                                let sign = isIncome ? "+" : "-"
                                let color = isIncome ? theme.colors.successColor : theme.colors.dangerColor
                                Text("\(sign)\(currency.format(item.amount))")
                                    .font(.system(size: 15, weight: .bold, design: .monospaced))
                                    .foregroundColor(color)
                            }
                            .padding(12)
                            .background(theme.colors.cardColor)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(theme.colors.separatorColor.opacity(0.3), lineWidth: 0.75)
                            )
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                }
            }
        }
    }
    
    // MARK: - Logic & Helpers
    
    private func loadData() {
        allTransactions = TransactionManager.shared.getAllTransactions()
        updateSelectedDayTransactions()
    }
    
    private func updateSelectedDayTransactions() {
        selectedDayTransactions = allTransactions.filter { item in
            guard let itemDate = item.date else { return false }
            return calendar.isDate(itemDate, inSameDayAs: selectedDate)
        }
    }
    
    private func changeMonth(by value: Int) {
        if let newDate = calendar.date(byAdding: .month, value: value, to: currentMonth) {
            currentMonth = newDate
        }
    }
    
    private func monthTitle(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
    
    private var formattedSelectedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: selectedDate)
    }
    
    private func generateDaysInMonth(for date: Date) -> [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: date) else { return [] }
        let startOfMonth = monthInterval.start
        
        let weekday = calendar.component(.weekday, from: startOfMonth)
        let paddingDays = weekday - 1
        
        var days: [Date?] = Array(repeating: nil, count: paddingDays)
        
        let range = calendar.range(of: .day, in: .month, for: date)!
        for day in range {
            if let d = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                days.append(d)
            }
        }
        
        return days
    }
}
