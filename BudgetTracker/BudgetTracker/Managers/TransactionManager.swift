//
//  TransactionManager.swift
//  BudgetTracker
//
//  Created by ali on 10/10/2026.
//

import Foundation
import CoreData

public struct TransactionGroup: Identifiable {
    public var id: String { title }
    public let title: String
    public let date: Date
    public var transactions: [TransactionEntity]
    
    public var totalExpense: Double {
        return transactions.filter { $0.type == TransactionType.expense.rawValue }.reduce(0) { $0 + $1.amount }
    }
    
    public var totalIncome: Double {
        return transactions.filter { $0.type == TransactionType.income.rawValue }.reduce(0) { $0 + $1.amount }
    }
    
    public var netTotal: Double {
        return totalIncome - totalExpense
    }
}

public struct FinancialSummary {
    public let totalBalance: Double
    public let totalIncome: Double
    public let totalExpenses: Double
    public let totalSavings: Double
    public let savingsRate: Double // e.g. 0.43 for 43%
    
    public init(
        totalBalance: Double = 0,
        totalIncome: Double = 0,
        totalExpenses: Double = 0,
        totalSavings: Double = 0,
        savingsRate: Double = 0
    ) {
        self.totalBalance = totalBalance
        self.totalIncome = totalIncome
        self.totalExpenses = totalExpenses
        self.totalSavings = totalSavings
        self.savingsRate = savingsRate
    }
}

public class TransactionManager {
    public static let shared = TransactionManager()
    
    private let coreData = CoreDataManager.shared
    
    private init() {}
    
    // MARK: - CRUD
    
    @discardableResult
    public func createTransaction(
        title: String,
        amount: Double,
        type: TransactionType,
        category: String,
        merchant: String? = nil,
        note: String? = nil,
        date: Date = Date(),
        paymentMethod: String? = "Cash",
        receiptImagePath: String? = nil,
        isRecurring: Bool = false,
        recurringRule: String? = nil,
        accountId: UUID? = nil,
        transferToAccountId: UUID? = nil
    ) -> TransactionEntity {
        let context = coreData.viewContext
        let transaction = TransactionEntity(context: context)
        transaction.id = UUID()
        transaction.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        transaction.amount = amount
        transaction.type = type.rawValue
        transaction.category = category
        transaction.merchant = merchant?.trimmingCharacters(in: .whitespacesAndNewlines)
        transaction.note = note?.trimmingCharacters(in: .whitespacesAndNewlines)
        transaction.date = date
        transaction.paymentMethod = paymentMethod
        transaction.receiptImagePath = receiptImagePath
        transaction.isRecurring = isRecurring
        transaction.recurringRule = recurringRule
        transaction.createdAt = Date()
        transaction.accountId = accountId
        transaction.transferToAccountId = transferToAccountId
        
        // Update account balances
        if type == .transfer, let fromId = accountId, let toId = transferToAccountId {
            AccountManager.shared.adjustBalance(accountId: fromId, amountDelta: -amount)
            AccountManager.shared.adjustBalance(accountId: toId, amountDelta: amount)
        } else if let accId = accountId {
            let delta = (type == .income) ? amount : -amount
            AccountManager.shared.adjustBalance(accountId: accId, amountDelta: delta)
        }
        
        coreData.saveContext()
        
        // Check budget thresholds when expense is created
        if type == .expense {
            BudgetManager.shared.evaluateBudgetsAfterExpense(amount: amount, category: category, date: date)
        }
        
        NotificationCenter.default.post(name: .transactionsDidChange, object: nil)
        return transaction
    }
    
    public func updateTransaction(
        transaction: TransactionEntity,
        title: String,
        amount: Double,
        type: TransactionType,
        category: String,
        merchant: String?,
        note: String?,
        date: Date,
        paymentMethod: String?,
        receiptImagePath: String?,
        accountId: UUID?
    ) {
        // Revert old account balance delta if account was set
        let oldType = transaction.transactionType
        let oldAmount = transaction.amount
        if let oldAccId = transaction.accountId {
            let oldDelta = (oldType == .income) ? -oldAmount : oldAmount
            AccountManager.shared.adjustBalance(accountId: oldAccId, amountDelta: oldDelta)
        }
        
        transaction.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        transaction.amount = amount
        transaction.type = type.rawValue
        transaction.category = category
        transaction.merchant = merchant?.trimmingCharacters(in: .whitespacesAndNewlines)
        transaction.note = note?.trimmingCharacters(in: .whitespacesAndNewlines)
        transaction.date = date
        transaction.paymentMethod = paymentMethod
        if let receiptImagePath = receiptImagePath {
            transaction.receiptImagePath = receiptImagePath
        }
        transaction.accountId = accountId
        
        // Apply new account balance delta
        if let newAccId = accountId {
            let newDelta = (type == .income) ? amount : -amount
            AccountManager.shared.adjustBalance(accountId: newAccId, amountDelta: newDelta)
        }
        
        coreData.saveContext()
        NotificationCenter.default.post(name: .transactionsDidChange, object: nil)
    }
    
    public func deleteTransaction(_ transaction: TransactionEntity) {
        // Adjust account balance
        let type = transaction.transactionType
        let amount = transaction.amount
        if let accId = transaction.accountId {
            let delta = (type == .income) ? -amount : amount
            AccountManager.shared.adjustBalance(accountId: accId, amountDelta: delta)
        }
        
        // Remove receipt file if exists
        if let receiptPath = transaction.receiptImagePath {
            let fileURL = URL(fileURLWithPath: receiptPath)
            try? FileManager.default.removeItem(at: fileURL)
        }
        
        coreData.viewContext.delete(transaction)
        coreData.saveContext()
        NotificationCenter.default.post(name: .transactionsDidChange, object: nil)
    }
    
    // MARK: - Querying & Filtering
    
    public func getAllTransactions() -> [TransactionEntity] {
        return fetchTransactions()
    }
    
    public func fetchTransactions(
        type: TransactionType? = nil,
        category: String? = nil,
        searchQuery: String? = nil,
        startDate: Date? = nil,
        endDate: Date? = nil,
        paymentMethod: String? = nil,
        minAmount: Double? = nil,
        maxAmount: Double? = nil,
        accountId: UUID? = nil,
        limit: Int? = nil
    ) -> [TransactionEntity] {
        let request = NSFetchRequest<TransactionEntity>(entityName: "TransactionEntity")
        var predicates: [NSPredicate] = []
        
        if let type = type {
            predicates.append(NSPredicate(format: "type == %@", type.rawValue))
        }
        
        if let category = category, !category.isEmpty, category != "All" {
            predicates.append(NSPredicate(format: "category ==[cd] %@", category))
        }
        
        if let query = searchQuery?.trimmingCharacters(in: .whitespacesAndNewlines), !query.isEmpty {
            if let doubleVal = Double(query) {
                let amountPredicate = NSPredicate(format: "amount == %lf", doubleVal)
                let textPredicate = NSPredicate(format: "title CONTAINS[cd] %@ OR merchant CONTAINS[cd] %@ OR category CONTAINS[cd] %@ OR note CONTAINS[cd] %@", query, query, query, query)
                predicates.append(NSCompoundPredicate(orPredicateWithSubpredicates: [amountPredicate, textPredicate]))
            } else {
                predicates.append(NSPredicate(format: "title CONTAINS[cd] %@ OR merchant CONTAINS[cd] %@ OR category CONTAINS[cd] %@ OR note CONTAINS[cd] %@", query, query, query, query))
            }
        }
        
        if let start = startDate {
            predicates.append(NSPredicate(format: "date >= %@", start as NSDate))
        }
        
        if let end = endDate {
            predicates.append(NSPredicate(format: "date <= %@", end as NSDate))
        }
        
        if let pm = paymentMethod, !pm.isEmpty, pm != "All" {
            predicates.append(NSPredicate(format: "paymentMethod ==[cd] %@", pm))
        }
        
        if let minA = minAmount {
            predicates.append(NSPredicate(format: "amount >= %lf", minA))
        }
        
        if let maxA = maxAmount {
            predicates.append(NSPredicate(format: "amount <= %lf", maxA))
        }
        
        if let accId = accountId {
            predicates.append(NSPredicate(format: "accountId == %@", accId as CVarArg))
        }
        
        if !predicates.isEmpty {
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        }
        
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        if let limit = limit {
            request.fetchLimit = limit
        }
        
        do {
            return try coreData.viewContext.fetch(request)
        } catch {
            print("Failed to fetch transactions: \(error)")
            return []
        }
    }
    
    // MARK: - Grouping for UI
    
    public func groupTransactionsByDate(_ transactions: [TransactionEntity]) -> [TransactionGroup] {
        let calendar = Calendar.current
        var dict: [Date: [TransactionEntity]] = [:]
        
        for item in transactions {
            let itemDate = item.date ?? Date()
            let normalizedDate = calendar.startOfDay(for: itemDate)
            dict[normalizedDate, default: []].append(item)
        }
        
        let sortedKeys = dict.keys.sorted(by: >)
        let now = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: now)!
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE, MMM d, yyyy"
        
        return sortedKeys.map { day in
            let title: String
            if day == now {
                title = "TODAY"
            } else if day == yesterday {
                title = "YESTERDAY"
            } else {
                title = dateFormatter.string(from: day).uppercased()
            }
            let sortedItems = dict[day]!.sorted { ($0.date ?? Date()) > ($1.date ?? Date()) }
            return TransactionGroup(title: title, date: day, transactions: sortedItems)
        }
    }
    
    // MARK: - Financial Calculations (Single Source of Truth)
    
    public func getFinancialSummary(for monthDate: Date = Date()) -> FinancialSummary {
        let calendar = Calendar.current
        let comps = calendar.dateComponents([.year, .month], from: monthDate)
        guard let startOfMonth = calendar.date(from: comps),
              let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1, hour: 23, minute: 59, second: 59), to: startOfMonth) else {
            return FinancialSummary(totalBalance: 0, totalIncome: 0, totalExpenses: 0, totalSavings: 0, savingsRate: 0)
        }
        
        let monthTransactions = fetchTransactions(startDate: startOfMonth, endDate: endOfMonth)
        
        var income: Double = 0
        var expense: Double = 0
        
        for item in monthTransactions {
            if item.type == TransactionType.income.rawValue {
                income += item.amount
            } else if item.type == TransactionType.expense.rawValue {
                expense += item.amount
            }
        }
        
        let savings = max(income - expense, 0)
        let savingsRate = income > 0 ? (savings / income) : 0
        
        // Total balance across all accounts or all-time income minus all-time expense
        let allTransactions = fetchTransactions()
        var allIncome: Double = 0
        var allExpense: Double = 0
        for item in allTransactions {
            if item.type == TransactionType.income.rawValue {
                allIncome += item.amount
            } else if item.type == TransactionType.expense.rawValue {
                allExpense += item.amount
            }
        }
        let totalBalance = allIncome - allExpense
        
        return FinancialSummary(
            totalBalance: totalBalance,
            totalIncome: income,
            totalExpenses: expense,
            totalSavings: savings,
            savingsRate: savingsRate
        )
    }
    
    public func getCategorySpending(monthDate: Date = Date()) -> [String: Double] {
        let calendar = Calendar.current
        let comps = calendar.dateComponents([.year, .month], from: monthDate)
        guard let startOfMonth = calendar.date(from: comps),
              let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1, hour: 23, minute: 59, second: 59), to: startOfMonth) else {
            return [:]
        }
        
        let expenses = fetchTransactions(type: .expense, startDate: startOfMonth, endDate: endOfMonth)
        var dict: [String: Double] = [:]
        for item in expenses {
            let cat = item.category ?? "Other"
            dict[cat, default: 0] += item.amount
        }
        return dict
    }
    
    // MARK: - Recurring Transactions Processing
    
    public func processPendingRecurringTransactions() {
        let request = NSFetchRequest<RecurringTransactionEntity>(entityName: "RecurringTransactionEntity")
        request.predicate = NSPredicate(format: "isEnabled == YES AND nextDate <= %@", Date() as NSDate)
        
        guard let recurringList = try? coreData.viewContext.fetch(request) else { return }
        let now = Date()
        
        for recurring in recurringList {
            guard let nextDate = recurring.nextDate, nextDate <= now else { continue }
            
            let type = TransactionType(rawValue: recurring.type ?? "expense") ?? .expense
            createTransaction(
                title: recurring.title ?? "Recurring Transaction",
                amount: recurring.amount,
                type: type,
                category: recurring.category ?? "Other",
                merchant: recurring.title,
                note: "Automatically generated from recurring rule",
                date: nextDate,
                paymentMethod: "Bank",
                isRecurring: true,
                accountId: recurring.accountId
            )
            
            // Advance nextDate based on frequency
            let freq = RecurringFrequency(rawValue: recurring.frequency ?? "monthly") ?? .monthly
            recurring.nextDate = freq.nextOccurrence(from: nextDate)
        }
        
        coreData.saveContext()
    }
    
    @discardableResult
    public func createRecurringTransaction(
        title: String,
        amount: Double,
        type: TransactionType = .expense,
        category: String,
        frequency: String = "monthly",
        startDate: Date = Date(),
        accountId: UUID? = nil
    ) -> RecurringTransactionEntity {
        let context = coreData.viewContext
        let entity = RecurringTransactionEntity(context: context)
        entity.id = UUID()
        entity.title = title
        entity.amount = amount
        entity.type = type.rawValue
        entity.category = category
        entity.frequency = frequency.lowercased()
        entity.nextDate = startDate
        entity.isEnabled = true
        entity.createdAt = Date()
        entity.accountId = accountId
        
        coreData.saveContext()
        NotificationCenter.default.post(name: .transactionsDidChange, object: nil)
        return entity
    }
}

extension Notification.Name {
    public static let transactionsDidChange = Notification.Name("BudgetTracker_TransactionsDidChange")
}
