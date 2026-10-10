//
//  AccountManager.swift
//  BudgetTracker
//
//  Created by ali on 10/10/2026.
//

import Foundation
import CoreData

public class AccountManager {
    public static let shared = AccountManager()
    
    private let coreData = CoreDataManager.shared
    
    private init() {}
    
    public func ensureDefaultAccountsExist() {
        let accounts = fetchAccounts()
        if accounts.isEmpty {
            createAccount(name: "Cash", type: .cash, initialBalance: 500.0, isDefault: true)
            createAccount(name: "Bank Checking", type: .bank, initialBalance: 3250.0, isDefault: false)
            createAccount(name: "High Yield Savings", type: .savings, initialBalance: 5000.0, isDefault: false)
            createAccount(name: "Credit Card", type: .creditCard, initialBalance: -450.0, isDefault: false)
        }
    }
    
    @discardableResult
    public func createAccount(
        name: String,
        type: AccountType,
        initialBalance: Double = 0.0,
        isDefault: Bool = false
    ) -> AccountEntity {
        let context = coreData.viewContext
        let account = AccountEntity(context: context)
        account.id = UUID()
        account.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        account.type = type.rawValue
        account.balance = initialBalance
        account.createdAt = Date()
        account.isDefault = isDefault
        
        coreData.saveContext()
        NotificationCenter.default.post(name: .accountsDidChange, object: nil)
        return account
    }
    
    public func updateAccount(account: AccountEntity, name: String, type: AccountType) {
        account.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        account.type = type.rawValue
        coreData.saveContext()
        NotificationCenter.default.post(name: .accountsDidChange, object: nil)
    }
    
    public func deleteAccount(_ account: AccountEntity) {
        coreData.viewContext.delete(account)
        coreData.saveContext()
        NotificationCenter.default.post(name: .accountsDidChange, object: nil)
    }
    
    public func fetchAccounts() -> [AccountEntity] {
        let request = NSFetchRequest<AccountEntity>(entityName: "AccountEntity")
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
        return (try? coreData.viewContext.fetch(request)) ?? []
    }
    
    public func getAccount(byId id: UUID) -> AccountEntity? {
        let request = NSFetchRequest<AccountEntity>(entityName: "AccountEntity")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        return try? coreData.viewContext.fetch(request).first
    }
    
    public func adjustBalance(accountId: UUID, amountDelta: Double) {
        guard let account = getAccount(byId: accountId) else { return }
        account.balance += amountDelta
        coreData.saveContext()
        NotificationCenter.default.post(name: .accountsDidChange, object: nil)
    }
    
    public func transferMoney(
        from sourceAccount: AccountEntity,
        to targetAccount: AccountEntity,
        amount: Double,
        note: String? = nil,
        date: Date = Date()
    ) {
        guard let fromId = sourceAccount.id, let toId = targetAccount.id else { return }
        
        TransactionManager.shared.createTransaction(
            title: "Transfer to \(targetAccount.name ?? "Account")",
            amount: amount,
            type: .transfer,
            category: "Transfer",
            merchant: "Internal Transfer",
            note: note,
            date: date,
            paymentMethod: "Bank",
            accountId: fromId,
            transferToAccountId: toId
        )
    }
}

extension Notification.Name {
    public static let accountsDidChange = Notification.Name("BudgetTracker_AccountsDidChange")
}
