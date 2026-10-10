//
//  BudgetTrackerWidget.swift
//  BudgetTracker
//
//  Created by ali on 10/10/2026.
//

import WidgetKit
import SwiftUI

public struct WidgetBudgetSnapshot: Codable {
    public let balance: Double
    public let income: Double
    public let expense: Double
    public let categoryProgress: [WidgetCategoryItem]
    public let isLocked: Bool
    public let currencySymbol: String
    public let lastUpdated: Date
    
    public static var previewData: WidgetBudgetSnapshot {
        WidgetBudgetSnapshot(
            balance: 4250.0,
            income: 5000.0,
            expense: 2850.0,
            categoryProgress: [
                WidgetCategoryItem(name: "Food", percentage: 0.60),
                WidgetCategoryItem(name: "Shopping", percentage: 0.72),
                WidgetCategoryItem(name: "Transport", percentage: 0.40)
            ],
            isLocked: false,
            currencySymbol: "$",
            lastUpdated: Date()
        )
    }
}

public struct WidgetCategoryItem: Codable, Identifiable {
    public var id: String { name }
    public let name: String
    public let percentage: Double
}

public class WidgetDataProvider {
    public static let shared = WidgetDataProvider()
    private let key = "BudgetTracker_WidgetData"
    
    private init() {}
    
    public func updateWidgetData() {
        let summary = TransactionManager.shared.getFinancialSummary()
        let statuses = BudgetManager.shared.getBudgetStatuses()
        let curr = CurrencyManager.shared.currentCurrency
        let isLocked = BiometricAuthManager.shared.isBiometricsEnabled
        
        let catItems = statuses.prefix(4).map {
            WidgetCategoryItem(name: $0.budget.name ?? ($0.budget.category ?? "Category"), percentage: $0.percentage)
        }
        
        let snapshot = WidgetBudgetSnapshot(
            balance: summary.totalBalance,
            income: summary.totalIncome,
            expense: summary.totalExpenses,
            categoryProgress: Array(catItems),
            isLocked: isLocked,
            currencySymbol: curr.symbol,
            lastUpdated: Date()
        )
        
        if let data = try? JSONEncoder().encode(snapshot) {
            UserDefaults.standard.set(data, forKey: key)
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    
    public func loadSnapshot() -> WidgetBudgetSnapshot {
        if let data = UserDefaults.standard.data(forKey: key),
           let snapshot = try? JSONDecoder().decode(WidgetBudgetSnapshot.self, from: data) {
            return snapshot
        }
        return WidgetBudgetSnapshot.previewData
    }
}

// MARK: - WidgetKit Timeline Provider

public struct BudgetEntry: TimelineEntry {
    public let date: Date
    public let snapshot: WidgetBudgetSnapshot
}

public struct BudgetTimelineProvider: TimelineProvider {
    public func placeholder(in context: Context) -> BudgetEntry {
        BudgetEntry(date: Date(), snapshot: .previewData)
    }
    
    public func getSnapshot(in context: Context, completion: @escaping (BudgetEntry) -> Void) {
        let entry = BudgetEntry(date: Date(), snapshot: WidgetDataProvider.shared.loadSnapshot())
        completion(entry)
    }
    
    public func getTimeline(in context: Context, completion: @escaping (Timeline<BudgetEntry>) -> Void) {
        let snapshot = WidgetDataProvider.shared.loadSnapshot()
        let currentEntry = BudgetEntry(date: Date(), snapshot: snapshot)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
        let timeline = Timeline(entries: [currentEntry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Widget Views

public struct BudgetTrackerWidgetEntryView: View {
    public var entry: BudgetEntry
    @Environment(\.widgetFamily) var family
    
    public var body: some View {
        ZStack {
            Color(UIColor.secondarySystemBackground)
            
            if entry.snapshot.isLocked {
                VStack(spacing: 8) {
                    Image(systemName: "lock.shield.fill")
                        .font(.title)
                        .foregroundColor(.secondary)
                    Text("App Locked")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                }
            } else {
                switch family {
                case .systemSmall:
                    smallWidgetView(entry.snapshot)
                case .systemMedium:
                    mediumWidgetView(entry.snapshot)
                default:
                    largeWidgetView(entry.snapshot)
                }
            }
        }
    }
    
    private func smallWidgetView(_ s: WidgetBudgetSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Balance")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Image(systemName: "wallet.pass.fill")
                    .foregroundColor(.blue)
            }
            Text("\(s.currencySymbol)\(String(format: "%.2f", s.balance))")
                .font(.title2.bold())
                .foregroundColor(.primary)
            Spacer()
            Text("Updated \(s.lastUpdated.formatted(date: .omitted, time: .shortened))")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
    }
    
    private func mediumWidgetView(_ s: WidgetBudgetSnapshot) -> some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Balance")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(s.currencySymbol)\(String(format: "%.2f", s.balance))")
                        .font(.title3.bold())
                }
                Spacer()
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(.blue)
            }
            
            Divider()
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Income")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("+\(s.currencySymbol)\(String(format: "%.0f", s.income))")
                        .font(.subheadline.bold())
                        .foregroundColor(.green)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Expenses")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("-\(s.currencySymbol)\(String(format: "%.0f", s.expense))")
                        .font(.subheadline.bold())
                        .foregroundColor(.red)
                }
            }
        }
        .padding()
    }
    
    private func largeWidgetView(_ s: WidgetBudgetSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Budget Overview")
                    .font(.headline)
                Spacer()
                Text("\(s.currencySymbol)\(String(format: "%.2f", s.balance))")
                    .font(.subheadline.bold())
                    .foregroundColor(.blue)
            }
            
            Divider()
            
            ForEach(s.categoryProgress) { cat in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(cat.name)
                            .font(.caption.bold())
                        Spacer()
                        Text("\(Int(cat.percentage * 100))%")
                            .font(.caption)
                            .foregroundColor(cat.percentage >= 1.0 ? .red : .primary)
                    }
                    ProgressView(value: min(cat.percentage, 1.0))
                        .tint(cat.percentage >= 1.0 ? .red : (cat.percentage >= 0.75 ? .orange : .blue))
                }
            }
            
            Spacer()
        }
        .padding()
    }
}

public struct BudgetTrackerWidget: Widget {
    public let kind: String = "BudgetTrackerWidget"
    
    public init() {}
    
    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BudgetTimelineProvider()) { entry in
            BudgetTrackerWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Budget Overview")
        .description("Track your live balances and category budgets.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
