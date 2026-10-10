//
//  CoreDataEntities.swift
//  BudgetTracker
//
//  Created by ali on 10/10/2026.
//

import Foundation
import CoreData

// MARK: - Transaction Entity

@objc(TransactionEntity)
public class TransactionEntity: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var amount: Double
    @NSManaged public var type: String? // "income", "expense", "transfer"
    @NSManaged public var category: String?
    @NSManaged public var title: String?
    @NSManaged public var merchant: String?
    @NSManaged public var note: String?
    @NSManaged public var date: Date?
    @NSManaged public var paymentMethod: String?
    @NSManaged public var receiptImagePath: String?
    @NSManaged public var isRecurring: Bool
    @NSManaged public var recurringRule: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var accountId: UUID?
    @NSManaged public var transferToAccountId: UUID?
    
    public var transactionType: TransactionType {
        get { TransactionType(rawValue: type ?? "expense") ?? .expense }
        set { type = newValue.rawValue }
    }
}

public enum TransactionType: String, CaseIterable, Codable {
    case expense = "expense"
    case income = "income"
    case transfer = "transfer"
    
    public var title: String {
        switch self {
        case .expense: return "Expense"
        case .income: return "Income"
        case .transfer: return "Transfer"
        }
    }
}

// MARK: - Budget Entity

@objc(BudgetEntity)
public class BudgetEntity: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var category: String? // nil means overall monthly budget
    @NSManaged public var limit: Double
    @NSManaged public var month: Date? // normalized to start of month
    @NSManaged public var alert50Enabled: Bool
    @NSManaged public var alert75Enabled: Bool
    @NSManaged public var alert90Enabled: Bool
    @NSManaged public var createdAt: Date?
    
    public var isOverall: Bool {
        return category == nil || category?.isEmpty == true
    }
}

// MARK: - Savings Goal Entity

@objc(SavingsGoalEntity)
public class SavingsGoalEntity: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var targetAmount: Double
    @NSManaged public var currentAmount: Double
    @NSManaged public var deadline: Date?
    @NSManaged public var createdAt: Date?
    @NSManaged public var icon: String?
    
    public var progressPercentage: Double {
        guard targetAmount > 0 else { return 0 }
        return min(max(currentAmount / targetAmount, 0), 1.0)
    }
    
    public var remainingAmount: Double {
        return max(targetAmount - currentAmount, 0)
    }
}

// MARK: - Account Entity

@objc(AccountEntity)
public class AccountEntity: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var type: String? // "Cash", "Bank", "Savings", "Credit Card", "Investment", "Custom"
    @NSManaged public var balance: Double
    @NSManaged public var createdAt: Date?
    @NSManaged public var isDefault: Bool
}

public enum AccountType: String, CaseIterable {
    case cash = "Cash"
    case bank = "Bank"
    case savings = "Savings"
    case creditCard = "Credit Card"
    case investment = "Investment"
    case custom = "Custom"
    
    public var iconName: String {
        switch self {
        case .cash: return "banknote.fill"
        case .bank: return "building.columns.fill"
        case .savings: return "tray.full.fill"
        case .creditCard: return "creditcard.fill"
        case .investment: return "chart.line.uptrend.xyaxis"
        case .custom: return "wallet.pass.fill"
        }
    }
}

// MARK: - Recurring Transaction Entity

@objc(RecurringTransactionEntity)
public class RecurringTransactionEntity: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var title: String?
    @NSManaged public var amount: Double
    @NSManaged public var type: String? // "income" or "expense"
    @NSManaged public var category: String?
    @NSManaged public var frequency: String? // "daily", "weekly", "monthly", "yearly"
    @NSManaged public var nextDate: Date?
    @NSManaged public var isEnabled: Bool
    @NSManaged public var createdAt: Date?
    @NSManaged public var accountId: UUID?
}

public enum RecurringFrequency: String, CaseIterable {
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
    case yearly = "yearly"
    
    public var title: String {
        switch self {
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        case .yearly: return "Yearly"
        }
    }
    
    public func nextOccurrence(from date: Date) -> Date {
        let calendar = Calendar.current
        switch self {
        case .daily:
            return calendar.date(byAdding: .day, value: 1, to: date) ?? date
        case .weekly:
            return calendar.date(byAdding: .day, value: 7, to: date) ?? date
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: date) ?? date
        case .yearly:
            return calendar.date(byAdding: .year, value: 1, to: date) ?? date
        }
    }
}

// MARK: - Debt Entity

@objc(DebtEntity)
public class DebtEntity: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var totalAmount: Double
    @NSManaged public var remainingAmount: Double
    @NSManaged public var interestRate: Double // e.g. 18.5 for 18.5%
    @NSManaged public var minimumPayment: Double
    @NSManaged public var dueDate: Date?
    @NSManaged public var createdAt: Date?
    @NSManaged public var debtType: String?
    
    public var progressPercentage: Double {
        guard totalAmount > 0 else { return 0 }
        let paid = max(totalAmount - remainingAmount, 0)
        return min(max(paid / totalAmount, 0), 1.0)
    }
}

public enum DebtType: String, CaseIterable {
    case creditCard = "Credit Card"
    case personalLoan = "Personal Loan"
    case studentLoan = "Student Loan"
    case mortgage = "Mortgage"
    case autoLoan = "Auto Loan"
    case custom = "Custom"
}
