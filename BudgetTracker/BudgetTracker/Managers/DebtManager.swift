//
//  DebtManager.swift
//  BudgetTracker
//
//  Created by ali on 10/10/2026.
//

import Foundation
import CoreData

public enum DebtStrategy: String, CaseIterable {
    case snowball = "Debt Snowball"
    case avalanche = "Debt Avalanche"
    
    public var description: String {
        switch self {
        case .snowball: return "Pay off smallest balances first for quick psychological wins."
        case .avalanche: return "Pay off highest interest rates first to minimize interest paid over time."
        }
    }
}

public class DebtManager {
    public static let shared = DebtManager()
    
    private let coreData = CoreDataManager.shared
    
    public static let disclaimerText = "Note: These payoff strategies are mathematical planning tools for personal budgeting and do not constitute professional financial advice."
    
    private init() {}
    
    @discardableResult
    public func createDebt(
        name: String,
        totalAmount: Double,
        remainingAmount: Double,
        interestRate: Double,
        minimumPayment: Double,
        dueDate: Date? = nil,
        debtType: DebtType = .creditCard
    ) -> DebtEntity {
        let context = coreData.viewContext
        let debt = DebtEntity(context: context)
        debt.id = UUID()
        debt.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        debt.totalAmount = totalAmount
        debt.remainingAmount = remainingAmount
        debt.interestRate = interestRate
        debt.minimumPayment = minimumPayment
        debt.dueDate = dueDate
        debt.debtType = debtType.rawValue
        debt.createdAt = Date()
        
        coreData.saveContext()
        NotificationCenter.default.post(name: .debtsDidChange, object: nil)
        return debt
    }
    
    public func recordPayment(debt: DebtEntity, paymentAmount: Double) {
        debt.remainingAmount = max(debt.remainingAmount - paymentAmount, 0)
        coreData.saveContext()
        NotificationCenter.default.post(name: .debtsDidChange, object: nil)
    }
    
    public func updateDebt(
        debt: DebtEntity,
        name: String,
        totalAmount: Double,
        remainingAmount: Double,
        interestRate: Double,
        minimumPayment: Double,
        dueDate: Date?,
        debtType: DebtType
    ) {
        debt.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        debt.totalAmount = totalAmount
        debt.remainingAmount = remainingAmount
        debt.interestRate = interestRate
        debt.minimumPayment = minimumPayment
        debt.dueDate = dueDate
        debt.debtType = debtType.rawValue
        
        coreData.saveContext()
        NotificationCenter.default.post(name: .debtsDidChange, object: nil)
    }
    
    public func deleteDebt(_ debt: DebtEntity) {
        coreData.viewContext.delete(debt)
        coreData.saveContext()
        NotificationCenter.default.post(name: .debtsDidChange, object: nil)
    }
    
    public func fetchDebts(strategy: DebtStrategy = .snowball) -> [DebtEntity] {
        let request = NSFetchRequest<DebtEntity>(entityName: "DebtEntity")
        let list = (try? coreData.viewContext.fetch(request)) ?? []
        
        switch strategy {
        case .snowball:
            return list.sorted { $0.remainingAmount < $1.remainingAmount }
        case .avalanche:
            return list.sorted { $0.interestRate > $1.interestRate }
        }
    }
    
    public func totalRemainingDebt() -> Double {
        return fetchDebts().reduce(0) { $0 + $1.remainingAmount }
    }
    
    public func totalMinimumMonthlyPayment() -> Double {
        return fetchDebts().reduce(0) { $0 + $1.minimumPayment }
    }
}

extension Notification.Name {
    public static let debtsDidChange = Notification.Name("BudgetTracker_DebtsDidChange")
}
