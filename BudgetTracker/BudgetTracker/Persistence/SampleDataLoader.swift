//
//  SampleDataLoader.swift
//  BudgetTracker
//
//  Created by ali on 10/10/2026.
//

import Foundation
import CoreData

public class SampleDataLoader {
    public static let shared = SampleDataLoader()
    
    private init() {}
    
    public func loadRealisticSampleData() {
        let coreData = CoreDataManager.shared
        coreData.deleteAllData()
        
        let accountManager = AccountManager.shared
        let transactionManager = TransactionManager.shared
        let budgetManager = BudgetManager.shared
        let savingsManager = SavingsManager.shared
        let debtManager = DebtManager.shared
        
        // 1. Accounts
        let cashAcc = accountManager.createAccount(name: "Cash Wallet", type: .cash, initialBalance: 350.0, isDefault: true)
        let checkingAcc = accountManager.createAccount(name: "Chase Checking", type: .bank, initialBalance: 4250.0, isDefault: false)
        let savingsAcc = accountManager.createAccount(name: "Marcus High Yield", type: .savings, initialBalance: 8500.0, isDefault: false)
        let creditAcc = accountManager.createAccount(name: "Apple Card", type: .creditCard, initialBalance: -450.0, isDefault: false)
        
        let calendar = Calendar.current
        let now = Date()
        
        // 2. Budgets
        budgetManager.createBudget(name: "Monthly Overall Budget", category: nil, limit: 2500, month: now, alert50: true, alert75: true, alert90: true)
        budgetManager.createBudget(name: "Food & Dining", category: "Food", limit: 500, month: now, alert50: true, alert75: true, alert90: true)
        budgetManager.createBudget(name: "Shopping & Retail", category: "Shopping", limit: 400, month: now, alert50: true, alert75: true, alert90: true)
        budgetManager.createBudget(name: "Transportation", category: "Transport", limit: 300, month: now, alert50: true, alert75: true, alert90: true)
        budgetManager.createBudget(name: "Entertainment", category: "Entertainment", limit: 200, month: now, alert50: true, alert75: true, alert90: true)
        
        // 3. Incomes
        if let salaryDate = calendar.date(byAdding: .day, value: -9, to: now) {
            transactionManager.createTransaction(
                title: "Monthly Salary",
                amount: 5000.0,
                type: .income,
                category: "Salary",
                merchant: "Tech Corp Inc",
                note: "Primary payroll deposit",
                date: salaryDate,
                paymentMethod: "Bank",
                accountId: checkingAcc.id
            )
        }
        if let freelanceDate = calendar.date(byAdding: .day, value: -4, to: now) {
            transactionManager.createTransaction(
                title: "UI Design Project",
                amount: 750.0,
                type: .income,
                category: "Freelance",
                merchant: "Acme Client LLC",
                note: "Sprint milestone payment",
                date: freelanceDate,
                paymentMethod: "Bank",
                accountId: checkingAcc.id
            )
        }
        
        // 4. Expenses (Current Month)
        let sampleExpenses: [(title: String, amount: Double, category: String, merchant: String, daysAgo: Int, payment: String, accId: UUID?)] = [
            ("Monthly Apartment Rent", 900.0, "Rent", "Skyline Properties", 8, "Bank", checkingAcc.id),
            ("Whole Foods Groceries", 145.20, "Food", "Whole Foods Market", 1, "Credit Card", creditAcc.id),
            ("Trader Joe's Snacks", 65.40, "Food", "Trader Joe's", 3, "Credit Card", creditAcc.id),
            ("Lunch with Coworkers", 24.50, "Food", "Chipotle Mexican Grill", 0, "Cash", cashAcc.id),
            ("Morning Espresso", 5.75, "Food", "Blue Bottle Coffee", 0, "Cash", cashAcc.id),
            ("Uber to Airport", 42.80, "Transport", "Uber", 2, "Credit Card", creditAcc.id),
            ("Chevron Gas Station", 55.00, "Transport", "Chevron", 5, "Debit Card", checkingAcc.id),
            ("Subway Transit Pass", 30.00, "Transport", "MTA Transit", 7, "Debit Card", checkingAcc.id),
            ("Zara Fall Jacket", 120.00, "Shopping", "Zara", 2, "Credit Card", creditAcc.id),
            ("Amazon Household Essentials", 85.30, "Shopping", "Amazon", 4, "Credit Card", creditAcc.id),
            ("High-speed Fiber Internet", 60.00, "Bills", "Verizon Fios", 6, "Bank", checkingAcc.id),
            ("Electric & Power Utility", 75.00, "Bills", "National Grid", 7, "Bank", checkingAcc.id),
            ("Netflix Premium", 19.99, "Entertainment", "Netflix", 5, "Credit Card", creditAcc.id),
            ("AMC Movie Night", 32.00, "Entertainment", "AMC Theatres", 3, "Cash", cashAcc.id),
            ("CVS Prescription", 28.50, "Health", "CVS Pharmacy", 4, "Cash", cashAcc.id)
        ]
        
        for exp in sampleExpenses {
            if let date = calendar.date(byAdding: .day, value: -exp.daysAgo, to: now) {
                transactionManager.createTransaction(
                    title: exp.title,
                    amount: exp.amount,
                    type: .expense,
                    category: exp.category,
                    merchant: exp.merchant,
                    note: "Sample transaction for testing",
                    date: date,
                    paymentMethod: exp.payment,
                    accountId: exp.accId
                )
            }
        }
        
        // 5. Savings Goals
        let deadline1 = calendar.date(byAdding: .month, value: 4, to: now)
        let deadline2 = calendar.date(byAdding: .month, value: 8, to: now)
        let deadline3 = calendar.date(byAdding: .month, value: 12, to: now)
        
        savingsManager.createGoal(name: "iPhone 16 Pro", targetAmount: 1500, currentAmount: 850, deadline: deadline1, icon: "iphone")
        savingsManager.createGoal(name: "Japan Vacation", targetAmount: 3500, currentAmount: 1750, deadline: deadline2, icon: "airplane")
        savingsManager.createGoal(name: "Emergency Fund", targetAmount: 10000, currentAmount: 6200, deadline: deadline3, icon: "shield.fill")
        
        // 6. Recurring Transactions
        let context = coreData.viewContext
        let recurringItems: [(title: String, amount: Double, type: String, category: String, freq: RecurringFrequency, nextDays: Int)] = [
            ("Monthly Salary", 5000.0, "income", "Salary", .monthly, 21),
            ("Apartment Rent", 900.0, "expense", "Rent", .monthly, 22),
            ("Fiber Internet", 60.0, "expense", "Bills", .monthly, 2),
            ("Netflix Subscription", 19.99, "expense", "Entertainment", .monthly, 5),
            ("Gym Membership", 45.0, "expense", "Health", .monthly, 14)
        ]
        
        for item in recurringItems {
            let entity = RecurringTransactionEntity(context: context)
            entity.id = UUID()
            entity.title = item.title
            entity.amount = item.amount
            entity.type = item.type
            entity.category = item.category
            entity.frequency = item.freq.rawValue
            entity.nextDate = calendar.date(byAdding: .day, value: item.nextDays, to: now)
            entity.isEnabled = true
            entity.createdAt = now
            entity.accountId = checkingAcc.id
        }
        
        // 7. Debts
        let debtDate1 = calendar.date(byAdding: .day, value: 15, to: now)
        let debtDate2 = calendar.date(byAdding: .day, value: 20, to: now)
        debtManager.createDebt(name: "Apple Card Balance", totalAmount: 1500, remainingAmount: 450, interestRate: 21.99, minimumPayment: 45, dueDate: debtDate1, debtType: .creditCard)
        debtManager.createDebt(name: "Undergrad Student Loan", totalAmount: 12000, remainingAmount: 6800, interestRate: 4.99, minimumPayment: 180, dueDate: debtDate2, debtType: .studentLoan)
        
        coreData.saveContext()
        NotificationCenter.default.post(name: .transactionsDidChange, object: nil)
        NotificationCenter.default.post(name: .budgetsDidChange, object: nil)
        NotificationCenter.default.post(name: .accountsDidChange, object: nil)
        NotificationCenter.default.post(name: .savingsGoalsDidChange, object: nil)
        NotificationCenter.default.post(name: .debtsDidChange, object: nil)
    }
}
