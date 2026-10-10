//
//  AnalyticsChartsView.swift
//  BudgetTracker
//
//  Created by ali on 10/10/2026.
//

import SwiftUI
import Charts

public enum AnalyticsPeriod: String, CaseIterable, Identifiable {
    case sevenDays = "7 Days"
    case thirtyDays = "30 Days"
    case sixMonths = "6 Months"
    case oneYear = "1 Year"
    
    public var id: String { rawValue }
    
    public var days: Int {
        switch self {
        case .sevenDays: return 7
        case .thirtyDays: return 30
        case .sixMonths: return 180
        case .oneYear: return 365
        }
    }
}

public struct SpendingPoint: Identifiable {
    public let id = UUID()
    public let date: Date
    public let label: String
    public let amount: Double
}

public struct CategorySpendPoint: Identifiable {
    public let id = UUID()
    public let category: String
    public let amount: Double
    public let color: Color
}

public struct ComparisonPoint: Identifiable {
    public let id = UUID()
    public let type: String
    public let amount: Double
    public let color: Color
}

public struct AnalyticsChartsView: View {
    @State private var selectedPeriod: AnalyticsPeriod = .thirtyDays
    @State private var spendingData: [SpendingPoint] = []
    @State private var categoryData: [CategorySpendPoint] = []
    @State private var comparisonData: [ComparisonPoint] = []
    @State private var savingsData: [SpendingPoint] = []
    
    @State private var totalIncome: Double = 0
    @State private var totalExpense: Double = 0
    @State private var totalSavings: Double = 0
    @State private var savingsRate: Double = 0
    
    public init() {}
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Period Picker
                Picker("Period", selection: $selectedPeriod) {
                    ForEach(AnalyticsPeriod.allCases) { period in
                        Text(period.rawValue).tag(period)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .onChange(of: selectedPeriod) { _ in
                    loadAnalyticsData()
                }
                
                // Key Metrics Row
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    metricCard(title: "Income", value: totalIncome, color: .green)
                    metricCard(title: "Expenses", value: totalExpense, color: .red)
                    metricCard(title: "Savings", value: totalSavings, color: .blue)
                    metricCard(title: "Savings Rate", percentage: savingsRate, color: .purple)
                }
                .padding(.horizontal)
                
                // 1. Spending Overview Chart
                chartContainer(title: "Spending Overview", subtitle: "Daily expense trend over \(selectedPeriod.rawValue)") {
                    if spendingData.isEmpty {
                        emptyChartMessage()
                    } else {
                        Chart(spendingData) { point in
                            BarMark(
                                x: .value("Date", point.label),
                                y: .value("Amount", point.amount)
                            )
                            .foregroundStyle(Color.red.gradient)
                            .cornerRadius(4)
                        }
                        .frame(height: 200)
                    }
                }
                
                // 2. Category Breakdown Chart
                chartContainer(title: "Category Breakdown", subtitle: "Expenses distributed by category") {
                    if categoryData.isEmpty {
                        emptyChartMessage()
                    } else {
                        if #available(iOS 17.0, *) {
                            Chart(categoryData) { point in
                                SectorMark(
                                    angle: .value("Amount", point.amount),
                                    innerRadius: .ratio(0.55),
                                    angularInset: 1.5
                                )
                                .cornerRadius(5)
                                .foregroundStyle(point.color)
                            }
                            .frame(height: 200)
                        } else {
                            Chart(categoryData) { point in
                                BarMark(
                                    x: .value("Category", point.category),
                                    y: .value("Amount", point.amount)
                                )
                                .foregroundStyle(point.color)
                                .cornerRadius(4)
                            }
                            .frame(height: 200)
                        }
                        
                        // Legend
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                            ForEach(categoryData) { item in
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(item.color)
                                        .frame(width: 8, height: 8)
                                    Text(item.category)
                                        .font(.caption)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Text(CurrencyManager.shared.format(item.amount))
                                        .font(.caption2.bold())
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(.top, 10)
                    }
                }
                
                // 3. Income vs Expenses vs Savings
                chartContainer(title: "Income vs Expenses", subtitle: "Financial flow comparison") {
                    if comparisonData.isEmpty {
                        emptyChartMessage()
                    } else {
                        Chart(comparisonData) { point in
                            BarMark(
                                x: .value("Type", point.type),
                                y: .value("Amount", point.amount)
                            )
                            .foregroundStyle(point.color.gradient)
                            .cornerRadius(6)
                        }
                        .frame(height: 180)
                    }
                }
                
                // 4. Savings Trend
                chartContainer(title: "Savings Trend", subtitle: "Net accumulated savings trajectory") {
                    if savingsData.isEmpty {
                        emptyChartMessage()
                    } else {
                        Chart(savingsData) { point in
                            LineMark(
                                x: .value("Date", point.label),
                                y: .value("Savings", point.amount)
                            )
                            .foregroundStyle(Color.blue)
                            .interpolationMethod(.catmullRom)
                            
                            AreaMark(
                                x: .value("Date", point.label),
                                y: .value("Savings", point.amount)
                            )
                            .foregroundStyle(LinearGradient(colors: [Color.blue.opacity(0.4), Color.blue.opacity(0.0)], startPoint: .top, endPoint: .bottom))
                            .interpolationMethod(.catmullRom)
                        }
                        .frame(height: 200)
                    }
                }
            }
            .padding(.vertical)
        }
        .onAppear {
            loadAnalyticsData()
        }
        .onReceive(NotificationCenter.default.publisher(for: .transactionsDidChange)) { _ in
            loadAnalyticsData()
        }
    }
    
    // MARK: - View Builders
    
    private func chartContainer<Content: View>(title: String, subtitle: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
            
            content()
                .padding(.top, 6)
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .padding(.horizontal)
    }
    
    private func metricCard(title: String, value: Double? = nil, percentage: Double? = nil, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            if let val = value {
                Text(CurrencyManager.shared.format(val))
                    .font(.title3.bold())
                    .foregroundColor(color)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
            } else if let pct = percentage {
                Text(String(format: "%.1f%%", pct * 100))
                    .font(.title3.bold())
                    .foregroundColor(color)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
    
    private func emptyChartMessage() -> some View {
        Text("Not enough data recorded in this period.")
            .font(.footnote)
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .frame(height: 120)
    }
    
    // MARK: - Data Loading
    
    private func loadAnalyticsData() {
        let calendar = Calendar.current
        let now = Date()
        let days = selectedPeriod.days
        guard let startDate = calendar.date(byAdding: .day, value: -days, to: now) else { return }
        
        let txs = TransactionManager.shared.fetchTransactions(startDate: startDate, endDate: now)
        
        var inc: Double = 0
        var exp: Double = 0
        var catMap: [String: Double] = [:]
        var dailyExpense: [String: Double] = [:]
        var dailySavings: [String: Double] = [:]
        
        let labelFormatter = DateFormatter()
        labelFormatter.dateFormat = (days <= 30) ? "MMM d" : "MMM yy"
        
        for item in txs {
            let itemDate = item.date ?? now
            let lbl = labelFormatter.string(from: itemDate)
            
            if item.type == TransactionType.income.rawValue {
                inc += item.amount
                dailySavings[lbl, default: 0] += item.amount
            } else if item.type == TransactionType.expense.rawValue {
                exp += item.amount
                let cat = item.category ?? "Other"
                catMap[cat, default: 0] += item.amount
                dailyExpense[lbl, default: 0] += item.amount
                dailySavings[lbl, default: 0] -= item.amount
            }
        }
        
        self.totalIncome = inc
        self.totalExpense = exp
        self.totalSavings = max(inc - exp, 0)
        self.savingsRate = inc > 0 ? (totalSavings / inc) : 0
        
        // 1. Spending Points
        let sortedDates = dailyExpense.keys.sorted()
        self.spendingData = sortedDates.map { key in
            SpendingPoint(date: now, label: key, amount: dailyExpense[key] ?? 0)
        }
        
        // 2. Category Points
        let categoryItems = CategoryManager.shared.allCategories()
        self.categoryData = catMap.map { (cat, amount) in
            let cItem = categoryItems.first(where: { $0.name.lowercased() == cat.lowercased() })
            let uic = cItem?.color ?? .systemGray
            return CategorySpendPoint(category: cat, amount: amount, color: Color(uic))
        }.sorted { $0.amount > $1.amount }
        
        // 3. Comparison
        self.comparisonData = [
            ComparisonPoint(type: "Income", amount: inc, color: .green),
            ComparisonPoint(type: "Expenses", amount: exp, color: .red),
            ComparisonPoint(type: "Savings", amount: totalSavings, color: .blue)
        ]
        
        // 4. Savings Points
        var accum: Double = 0
        self.savingsData = sortedDates.map { key in
            accum += (dailySavings[key] ?? 0)
            return SpendingPoint(date: now, label: key, amount: max(accum, 0))
        }
    }
}
