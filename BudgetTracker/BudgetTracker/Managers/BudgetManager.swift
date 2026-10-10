//
//  BudgetManager.swift
//  BudgetTracker
//
//  Created by ali on 10/10/2026.
//

import UIKit
import CoreData

public enum BudgetStatusLevel {
    case safe       // < 50%
    case warning    // 50% - 74%
    case high       // 75% - 89%
    case critical   // 90% - 99%
    case exceeded   // >= 100%
    
    public var color: UIColor {
        let colors = ThemeManager.shared.colors
        switch self {
        case .safe: return colors.success
        case .warning: return colors.warning
        case .high: return UIColor(hex: "#FF7B00") ?? colors.warning
        case .critical: return colors.danger
        case .exceeded: return UIColor(hex: "#D90429") ?? colors.danger
        }
    }
    
    public var label: String {
        switch self {
        case .safe: return "On Track"
        case .warning: return "50% Used"
        case .high: return "75% Used"
        case .critical: return "90% Used"
        case .exceeded: return "Exceeded"
        }
    }
}

public struct BudgetStatus {
    public let budget: BudgetEntity
    public let usedAmount: Double
    public let limitAmount: Double
    public let remainingAmount: Double
    public let percentage: Double // 0.0 to 1.0+
    public let level: BudgetStatusLevel
}

public class BudgetManager {
    public static let shared = BudgetManager()
    
    private let coreData = CoreDataManager.shared
    
    private init() {}
    
    // MARK: - CRUD
    
    @discardableResult
    public func createBudget(
        name: String,
        category: String?,
        limit: Double,
        month: Date = Date(),
        alert50: Bool = true,
        alert75: Bool = true,
        alert90: Bool = true
    ) -> BudgetEntity {
        let context = coreData.viewContext
        let budget = BudgetEntity(context: context)
        budget.id = UUID()
        budget.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        budget.category = category?.isEmpty == true ? nil : category
        budget.limit = limit
        
        let calendar = Calendar.current
        let comps = calendar.dateComponents([.year, .month], from: month)
        budget.month = calendar.date(from: comps) ?? month
        
        budget.alert50Enabled = alert50
        budget.alert75Enabled = alert75
        budget.alert90Enabled = alert90
        budget.createdAt = Date()
        
        coreData.saveContext()
        NotificationCenter.default.post(name: .budgetsDidChange, object: nil)
        return budget
    }
    
    public func updateBudget(
        budget: BudgetEntity,
        name: String,
        category: String?,
        limit: Double,
        alert50: Bool,
        alert75: Bool,
        alert90: Bool
    ) {
        budget.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        budget.category = category?.isEmpty == true ? nil : category
        budget.limit = limit
        budget.alert50Enabled = alert50
        budget.alert75Enabled = alert75
        budget.alert90Enabled = alert90
        
        coreData.saveContext()
        NotificationCenter.default.post(name: .budgetsDidChange, object: nil)
    }
    
    public func deleteBudget(_ budget: BudgetEntity) {
        coreData.viewContext.delete(budget)
        coreData.saveContext()
        NotificationCenter.default.post(name: .budgetsDidChange, object: nil)
    }
    
    // MARK: - Fetching & Status
    
    public func fetchBudgets(for month: Date = Date()) -> [BudgetEntity] {
        let calendar = Calendar.current
        let comps = calendar.dateComponents([.year, .month], from: month)
        guard let startOfMonth = calendar.date(from: comps),
              let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) else {
            return []
        }
        
        let request = NSFetchRequest<BudgetEntity>(entityName: "BudgetEntity")
        request.predicate = NSPredicate(format: "month >= %@ AND month <= %@", startOfMonth as NSDate, endOfMonth as NSDate)
        request.sortDescriptors = [NSSortDescriptor(key: "category", ascending: true)]
        
        return (try? coreData.viewContext.fetch(request)) ?? []
    }
    
    public func getBudgetStatuses(for month: Date = Date()) -> [BudgetStatus] {
        let budgets = fetchBudgets(for: month)
        let categorySpending = TransactionManager.shared.getCategorySpending(monthDate: month)
        let totalExpense = categorySpending.values.reduce(0, +)
        
        return budgets.map { budget in
            let used: Double
            if budget.isOverall {
                used = totalExpense
            } else if let cat = budget.category {
                used = categorySpending[cat] ?? 0
            } else {
                used = 0
            }
            
            let limit = budget.limit
            let remaining = max(limit - used, 0)
            let ratio = limit > 0 ? (used / limit) : 0
            
            let level: BudgetStatusLevel
            if ratio >= 1.0 {
                level = .exceeded
            } else if ratio >= 0.90 {
                level = .critical
            } else if ratio >= 0.75 {
                level = .high
            } else if ratio >= 0.50 {
                level = .warning
            } else {
                level = .safe
            }
            
            return BudgetStatus(
                budget: budget,
                usedAmount: used,
                limitAmount: limit,
                remainingAmount: remaining,
                percentage: ratio,
                level: level
            )
        }
    }
    
    // MARK: - Alert Evaluation
    
    public func evaluateBudgetsAfterExpense(amount: Double, category: String, date: Date) {
        let statuses = getBudgetStatuses(for: date)
        
        for status in statuses {
            let budget = status.budget
            guard let budgetId = budget.id else { continue }
            
            let name = budget.name ?? (budget.isOverall ? "Overall Monthly" : (budget.category ?? "Budget"))
            
            if status.percentage >= 1.0 {
                NotificationManager.shared.sendBudgetAlert(budgetName: name, percentage: 100, isExceeded: true, budgetId: budgetId)
            } else if status.percentage >= 0.90 && budget.alert90Enabled {
                NotificationManager.shared.sendBudgetAlert(budgetName: name, percentage: 90, isExceeded: false, budgetId: budgetId)
            } else if status.percentage >= 0.75 && budget.alert75Enabled {
                NotificationManager.shared.sendBudgetAlert(budgetName: name, percentage: 75, isExceeded: false, budgetId: budgetId)
            } else if status.percentage >= 0.50 && budget.alert50Enabled {
                NotificationManager.shared.sendBudgetAlert(budgetName: name, percentage: 50, isExceeded: false, budgetId: budgetId)
            }
        }
    }
}

extension Notification.Name {
    public static let budgetsDidChange = Notification.Name("BudgetTracker_BudgetsDidChange")
}
