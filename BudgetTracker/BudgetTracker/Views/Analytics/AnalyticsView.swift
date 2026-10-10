//
//  AnalyticsView.swift
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

public struct AnalyticsView: View {
    @ObservedObject private var theme = ThemeManager.shared
    @ObservedObject private var currency = CurrencyManager.shared
    
    @State private var selectedPeriod: AnalyticsPeriod = .thirtyDays
    @State private var spendingData: [SpendingPoint] = []
    @State private var categoryData: [CategorySpendPoint] = []
    @State private var comparisonData: [ComparisonPoint] = []
    @State private var savingsData: [SpendingPoint] = []
    
    @State private var totalIncome: Double = 0
    @State private var totalExpense: Double = 0
    @State private var totalSavings: Double = 0
    @State private var savingsRate: Double = 0
    
    @State private var exportFileURL: URL?
    @State private var showShareSheet = false
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 1. Period Segmented Control
                    Picker("Period", selection: $selectedPeriod) {
                        ForEach(AnalyticsPeriod.allCases) { period in
                            Text(period.rawValue).tag(period)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 16)
                    .onChange(of: selectedPeriod) { _ in
                        loadData()
                    }
                    
                    // 2. Key Metrics Grid
                    keyMetricsGrid
                        .padding(.horizontal, 16)
                    
                    // 3. Category Breakdown Chart
                    categoryBreakdownCard
                        .padding(.horizontal, 16)
                    
                    // 4. Daily Spending Trend Bar Chart
                    spendingTrendCard
                        .padding(.horizontal, 16)
                    
                    // 5. Income vs Expense Comparison Bar Chart
                    incomeVsExpenseCard
                        .padding(.horizontal, 16)
                    
                    // 6. Net Savings Cumulative Trajectory
                    savingsTrajectoryCard
                        .padding(.horizontal, 16)
                    
                    // 7. Export Action Section
                    exportButtonsSection
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)
                }
                .padding(.vertical, 12)
            }
            .background(theme.colors.backgroundColor.ignoresSafeArea())
            .navigationTitle("Analytics")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showShareSheet) {
                if let url = exportFileURL {
                    ShareActivityView(activityItems: [url])
                }
            }
            .onAppear {
                loadData()
            }
            .refreshable {
                loadData()
            }
        }
    }
    
    // MARK: - Key Metrics Grid
    
    private var keyMetricsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            metricCard(title: "Income", value: currency.format(totalIncome), icon: "arrow.down.left", color: theme.colors.successColor)
            metricCard(title: "Expenses", value: currency.format(totalExpense), icon: "arrow.up.right", color: theme.colors.dangerColor)
            metricCard(title: "Net Savings", value: currency.format(totalSavings), icon: "banknote.fill", color: theme.colors.primaryColor)
            metricCard(title: "Savings Rate", value: String(format: "%.1f%%", savingsRate), icon: "percent", color: .purple)
        }
    }
    
    private func metricCard(title: String, value: String, icon: String, color: Color) -> some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Circle()
                        .fill(color.opacity(0.14))
                        .frame(width: 32, height: 32)
                        .overlay(
                            Image(systemName: icon)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(color)
                        )
                    
                    Spacer()
                }
                
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(theme.colors.secondaryTextColor)
                
                Text(value)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(theme.colors.textColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
    }
    
    // MARK: - Category Breakdown Card
    
    private var categoryBreakdownCard: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Category Breakdown")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(theme.colors.textColor)
                        
                        Text("Expenses distributed by category")
                            .font(.system(size: 12))
                            .foregroundColor(theme.colors.secondaryTextColor)
                    }
                    
                    Spacer()
                }
                
                if categoryData.isEmpty {
                    Text("No expense data recorded in this period.")
                        .font(.system(size: 13))
                        .foregroundColor(theme.colors.secondaryTextColor)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 32)
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
                        .frame(height: 180)
                    }
                    
                    Divider()
                        .background(theme.colors.separatorColor.opacity(0.4))
                    
                    // Category Legend List
                    VStack(spacing: 8) {
                        ForEach(categoryData) { item in
                            HStack {
                                Circle()
                                    .fill(item.color)
                                    .frame(width: 10, height: 10)
                                
                                Text(item.category)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(theme.colors.textColor)
                                
                                Spacer()
                                
                                Text(currency.format(item.amount))
                                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                                    .foregroundColor(theme.colors.textColor)
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Daily Spending Trend Card
    
    private var spendingTrendCard: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Daily Spending Trend")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(theme.colors.textColor)
                    
                    Text("Daily expense pattern across \(selectedPeriod.rawValue)")
                        .font(.system(size: 12))
                        .foregroundColor(theme.colors.secondaryTextColor)
                }
                
                if spendingData.isEmpty {
                    Text("No daily spending recorded.")
                        .font(.system(size: 13))
                        .foregroundColor(theme.colors.secondaryTextColor)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 32)
                } else {
                    Chart(spendingData) { point in
                        BarMark(
                            x: .value("Date", point.label),
                            y: .value("Amount", point.amount)
                        )
                        .foregroundStyle(theme.colors.dangerColor.gradient)
                        .cornerRadius(4)
                    }
                    .frame(height: 190)
                }
            }
        }
    }
    
    // MARK: - Income vs Expenses Card
    
    private var incomeVsExpenseCard: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Income vs Expenses")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(theme.colors.textColor)
                    
                    Text("Cash flow balance")
                        .font(.system(size: 12))
                        .foregroundColor(theme.colors.secondaryTextColor)
                }
                
                if comparisonData.isEmpty {
                    Text("No cash flow data recorded.")
                        .font(.system(size: 13))
                        .foregroundColor(theme.colors.secondaryTextColor)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 32)
                } else {
                    Chart(comparisonData) { point in
                        BarMark(
                            x: .value("Type", point.type),
                            y: .value("Amount", point.amount)
                        )
                        .foregroundStyle(point.color.gradient)
                        .cornerRadius(6)
                    }
                    .frame(height: 160)
                }
            }
        }
    }
    
    // MARK: - Savings Trajectory Card
    
    private var savingsTrajectoryCard: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Net Savings Trajectory")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(theme.colors.textColor)
                    
                    Text("Cumulative net savings over time")
                        .font(.system(size: 12))
                        .foregroundColor(theme.colors.secondaryTextColor)
                }
                
                if savingsData.isEmpty {
                    Text("No savings trajectory data available.")
                        .font(.system(size: 13))
                        .foregroundColor(theme.colors.secondaryTextColor)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 32)
                } else {
                    Chart(savingsData) { point in
                        LineMark(
                            x: .value("Date", point.label),
                            y: .value("Savings", point.amount)
                        )
                        .foregroundStyle(theme.colors.primaryColor)
                        .interpolationMethod(.catmullRom)
                        
                        AreaMark(
                            x: .value("Date", point.label),
                            y: .value("Savings", point.amount)
                        )
                        .foregroundStyle(LinearGradient(colors: [theme.colors.primaryColor.opacity(0.35), theme.colors.primaryColor.opacity(0.0)], startPoint: .top, endPoint: .bottom))
                        .interpolationMethod(.catmullRom)
                    }
                    .frame(height: 180)
                }
            }
        }
    }
    
    // MARK: - Export Buttons Section
    
    private var exportButtonsSection: some View {
        VStack(spacing: 12) {
            Button(action: { exportPDF() }) {
                HStack(spacing: 10) {
                    Image(systemName: "doc.richtext.fill")
                        .font(.system(size: 17))
                    Text("Export PDF Report")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(theme.colors.primaryColor)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .shadow(color: theme.colors.primaryColor.opacity(0.3), radius: 6, x: 0, y: 3)
            }
            .buttonStyle(ScaleButtonStyle())
            
            Button(action: { exportCSV() }) {
                HStack(spacing: 10) {
                    Image(systemName: "tablecells.fill")
                        .font(.system(size: 17))
                    Text("Export CSV Transactions")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundColor(theme.colors.textColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(theme.colors.elevatedCardColor)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(theme.colors.separatorColor.opacity(0.4), lineWidth: 0.75)
                )
            }
            .buttonStyle(ScaleButtonStyle())
        }
    }
    
    // MARK: - Data Loading & Calculations
    
    private func loadData() {
        let calendar = Calendar.current
        let now = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -selectedPeriod.days, to: now) else { return }
        
        let allTx = TransactionManager.shared.getAllTransactions()
        let periodTx = allTx.filter { ($0.date ?? Date()) >= startDate }
        
        let inc = periodTx.filter { $0.type == "income" }.reduce(0.0) { $0 + $1.amount }
        let exp = periodTx.filter { $0.type == "expense" }.reduce(0.0) { $0 + $1.amount }
        
        totalIncome = inc
        totalExpense = exp
        totalSavings = inc - exp
        savingsRate = inc > 0 ? max(0, ((inc - exp) / inc) * 100) : 0
        
        // 1. Spending Trend By Day
        var dailySpend: [Date: Double] = [:]
        for tx in periodTx where tx.type == "expense" {
            if let d = tx.date {
                let startOfDay = calendar.startOfDay(for: d)
                dailySpend[startOfDay, default: 0] += tx.amount
            }
        }
        
        let sortedDates = dailySpend.keys.sorted()
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = selectedPeriod.days <= 30 ? "d MMM" : "MMM"
        
        spendingData = sortedDates.suffix(15).map { d in
            SpendingPoint(date: d, label: dayFormatter.string(from: d), amount: dailySpend[d] ?? 0)
        }
        
        // 2. Category Breakdown
        var catTotals: [String: Double] = [:]
        for tx in periodTx where tx.type == "expense" {
            let cat = tx.category ?? "Other"
            catTotals[cat, default: 0] += tx.amount
        }
        
        categoryData = catTotals.sorted { $0.value > $1.value }.map { entry in
            let c = CategoryManager.shared.category(named: entry.key)
            return CategorySpendPoint(
                category: entry.key,
                amount: entry.value,
                color: c.color
            )
        }
        
        // 3. Comparison
        comparisonData = [
            ComparisonPoint(type: "Income", amount: inc, color: theme.colors.successColor),
            ComparisonPoint(type: "Expenses", amount: exp, color: theme.colors.dangerColor),
            ComparisonPoint(type: "Net", amount: max(0, inc - exp), color: theme.colors.primaryColor)
        ]
        
        // 4. Savings Trajectory
        var runningSavings: Double = 0
        var traj: [SpendingPoint] = []
        let sortedAll = periodTx.sorted { ($0.date ?? Date()) < ($1.date ?? Date()) }
        for tx in sortedAll {
            if tx.type == "income" { runningSavings += tx.amount }
            else if tx.type == "expense" { runningSavings -= tx.amount }
            if let d = tx.date {
                traj.append(SpendingPoint(date: d, label: dayFormatter.string(from: d), amount: runningSavings))
            }
        }
        savingsData = Array(traj.suffix(15))
    }
    
    private func exportPDF() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        if let url = ExportManager.shared.generatePDFReport() {
            exportFileURL = url
            showShareSheet = true
        }
    }
    
    private func exportCSV() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        if let url = ExportManager.shared.exportTransactionsCSV() {
            exportFileURL = url
            showShareSheet = true
        }
    }
}

// MARK: - UIActivityViewController Wrapper for SwiftUI

public struct ShareActivityView: UIViewControllerRepresentable {
    public let activityItems: [Any]
    
    public func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    public func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
