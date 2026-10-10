//
//  AIAssistantService.swift
//  BudgetTracker
//
//  Created by ali on 10/10/2026.
//

import Foundation

public struct ProposedTransaction {
    public var title: String
    public var amount: Double
    public var category: String
    public var type: TransactionType
    public var date: Date
    public var paymentMethod: String
}

public protocol AIProviderProtocol {
    func parseExpense(text: String) -> ProposedTransaction?
    func answerQuery(text: String) -> String
}

public class AIAssistantService: AIProviderProtocol {
    public static let shared = AIAssistantService()
    
    public static let disclaimer = "AI responses are for planning convenience only and do not constitute professional financial advice. All transactions require your manual review and confirmation."
    
    private init() {}
    
    // MARK: - Natural Language Expense Parsing
    
    public func parseExpense(text: String) -> ProposedTransaction? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        
        var amount: Double = 0
        var category = "Other"
        var title = "Expense"
        var date = Date()
        var paymentMethod = "Cash"
        
        // 1. Extract Amount: look for numbers with optional currency symbols
        let amountRegex = try? NSRegularExpression(pattern: #"(?:[$€£₨¥]|dollars|bucks)?\s*([0-9]+(?:\.[0-9]{1,2})?)\s*(?:dollars|bucks)?"#, options: [.caseInsensitive])
        let nsText = trimmed as NSString
        if let match = amountRegex?.firstMatch(in: trimmed, options: [], range: NSRange(location: 0, length: nsText.length)) {
            if match.numberOfRanges > 1 {
                let amountStr = nsText.substring(with: match.range(at: 1))
                amount = Double(amountStr) ?? 0
            }
        }
        
        guard amount > 0 else { return nil }
        
        let lower = trimmed.lowercased()
        
        // 2. Extract Category & Title
        if lower.contains("lunch") || lower.contains("dinner") || lower.contains("breakfast") || lower.contains("coffee") || lower.contains("food") || lower.contains("grocery") || lower.contains("groceries") || lower.contains("burger") || lower.contains("pizza") || lower.contains("restaurant") {
            category = "Food"
            if lower.contains("lunch") { title = "Lunch" }
            else if lower.contains("dinner") { title = "Dinner" }
            else if lower.contains("breakfast") { title = "Breakfast" }
            else if lower.contains("coffee") { title = "Coffee" }
            else if lower.contains("groceries") { title = "Groceries" }
            else { title = "Dining" }
        } else if lower.contains("uber") || lower.contains("taxi") || lower.contains("gas") || lower.contains("fuel") || lower.contains("subway") || lower.contains("bus") || lower.contains("train") || lower.contains("transport") {
            category = "Transport"
            if lower.contains("uber") { title = "Uber" }
            else if lower.contains("gas") || lower.contains("fuel") { title = "Gas Fuel" }
            else { title = "Transport" }
        } else if lower.contains("shopping") || lower.contains("clothes") || lower.contains("shoes") || lower.contains("amazon") {
            category = "Shopping"
            title = lower.contains("amazon") ? "Amazon Order" : "Shopping"
        } else if lower.contains("bill") || lower.contains("electricity") || lower.contains("internet") || lower.contains("water") {
            category = "Bills"
            title = "Utility Bill"
        } else if lower.contains("movie") || lower.contains("game") || lower.contains("cinema") || lower.contains("entertainment") || lower.contains("netflix") {
            category = "Entertainment"
            title = lower.contains("netflix") ? "Netflix Subscription" : "Entertainment"
        } else if lower.contains("doctor") || lower.contains("medicine") || lower.contains("pharmacy") || lower.contains("health") {
            category = "Health"
            title = "Healthcare"
        } else if lower.contains("rent") {
            category = "Rent"
            title = "Monthly Rent"
        } else if lower.contains("flight") || lower.contains("hotel") || lower.contains("travel") {
            category = "Travel"
            title = "Travel Expense"
        }
        
        // 3. Extract Date
        if lower.contains("yesterday") {
            date = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        }
        
        // 4. Payment Method
        if lower.contains("card") || lower.contains("credit") {
            paymentMethod = "Credit Card"
        } else if lower.contains("debit") {
            paymentMethod = "Debit Card"
        } else if lower.contains("bank") || lower.contains("transfer") {
            paymentMethod = "Bank"
        }
        
        return ProposedTransaction(
            title: title,
            amount: amount,
            category: category,
            type: .expense,
            date: date,
            paymentMethod: paymentMethod
        )
    }
    
    // MARK: - Local Financial Query Answering
    
    public func answerQuery(text: String) -> String {
        let lower = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let summary = TransactionManager.shared.getFinancialSummary()
        let categorySpending = TransactionManager.shared.getCategorySpending()
        let currency = CurrencyManager.shared
        
        // Query: "Where did I spend the most this month?"
        if lower.contains("most") || lower.contains("highest") || lower.contains("top") {
            if let top = categorySpending.max(by: { $0.value < $1.value }) {
                return "You spent the most on \(top.key) this month, totaling \(currency.format(top.value))."
            } else {
                return "You don't have any recorded expenses for this month yet."
            }
        }
        
        // Query: "How much did I spend on food?" (or any specific category)
        for cat in CategoryManager.shared.getExpenseCategories() {
            if lower.contains(cat.name.lowercased()) {
                let spent = categorySpending[cat.name] ?? 0.0
                return "You've spent \(currency.format(spent)) on \(cat.name) this month."
            }
        }
        
        // Query: "How much did I save this month?"
        if lower.contains("save") || lower.contains("savings") {
            let ratePercent = Int(summary.savingsRate * 100)
            return "This month, you have saved \(currency.format(summary.totalSavings)), which represents a savings rate of \(ratePercent)% of your total income (\(currency.format(summary.totalIncome)))."
        }
        
        // Query: "Where am I overspending?"
        if lower.contains("overspend") || lower.contains("exceeded") || lower.contains("limit") {
            let statuses = BudgetManager.shared.getBudgetStatuses()
            let overspent = statuses.filter { $0.percentage >= 1.0 }
            let warnings = statuses.filter { $0.percentage >= 0.75 && $0.percentage < 1.0 }
            
            if !overspent.isEmpty {
                let names = overspent.map { "\($0.budget.name ?? "Budget") (\(Int($0.percentage * 100))%)" }.joined(separator: ", ")
                return "You have exceeded the following budgets: \(names). Consider reducing expenses in these areas for the remainder of the month."
            } else if !warnings.isEmpty {
                let names = warnings.map { "\($0.budget.name ?? "Budget") (\(Int($0.percentage * 100))%)" }.joined(separator: ", ")
                return "None of your budgets are exceeded, but you are approaching limits on: \(names)."
            } else {
                return "Great news! None of your budgets are exceeded this month, and your spending is well on track."
            }
        }
        
        // Query: "Can I afford a $500 purchase based on my current budget?"
        let amountRegex = try? NSRegularExpression(pattern: #"([0-9]+)"#, options: [])
        if (lower.contains("afford") || lower.contains("purchase") || lower.contains("buy")),
           let match = amountRegex?.firstMatch(in: lower, options: [], range: NSRange(location: 0, length: (lower as NSString).length)) {
            let amtStr = (lower as NSString).substring(with: match.range)
            if let purchaseAmt = Double(amtStr) {
                let remainingBudget: Double
                let overall = BudgetManager.shared.getBudgetStatuses().first(where: { $0.budget.isOverall })
                if let o = overall {
                    remainingBudget = o.remainingAmount
                } else {
                    remainingBudget = max(summary.totalIncome - summary.totalExpenses, 0)
                }
                
                if remainingBudget >= purchaseAmt {
                    let leftAfter = remainingBudget - purchaseAmt
                    return "Yes, based on your current financial status, you have \(currency.format(remainingBudget)) remaining in discretionary funds. After a \(currency.format(purchaseAmt)) purchase, you would still have \(currency.format(leftAfter)) left."
                } else {
                    let deficit = purchaseAmt - remainingBudget
                    return "A \(currency.format(purchaseAmt)) purchase would exceed your remaining funds of \(currency.format(remainingBudget)) by \(currency.format(deficit)). Consider waiting or adjusting other budget categories."
                }
            }
        }
        
        // Query: "Create a budget for next month."
        if lower.contains("create") && lower.contains("budget") {
            return "Based on your spending patterns this month, recommended budget limits: Food (\(currency.format(max((categorySpending["Food"] ?? 300) * 1.1, 400)))), Transport (\(currency.format(max((categorySpending["Transport"] ?? 150) * 1.1, 200)))), and Bills (\(currency.format(max((categorySpending["Bills"] ?? 200) * 1.05, 250)))). You can tap 'Create Budget' in the Budgets tab to activate them."
        }
        
        // Default overview
        return "Summary for this month:\n• Income: \(currency.format(summary.totalIncome))\n• Expenses: \(currency.format(summary.totalExpenses))\n• Net Savings: \(currency.format(summary.totalSavings))\n• Total Balance: \(currency.format(summary.totalBalance))\n\nFeel free to ask questions like 'Where did I spend the most?' or type an expense like 'Spent $25 on lunch today'."
    }
}
