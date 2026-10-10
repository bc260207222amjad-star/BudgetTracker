//
//  CurrencyModel.swift
//  BudgetTracker
//
//  Created by ali on 10/10/2026.
//

import Foundation

public struct CurrencyInfo: Codable, Equatable {
    public let code: String
    public let symbol: String
    public let name: String
    
    public static let supportedCurrencies: [CurrencyInfo] = [
        CurrencyInfo(code: "USD", symbol: "$", name: "US Dollar"),
        CurrencyInfo(code: "EUR", symbol: "€", name: "Euro"),
        CurrencyInfo(code: "GBP", symbol: "£", name: "British Pound"),
        CurrencyInfo(code: "PKR", symbol: "₨", name: "Pakistani Rupee"),
        CurrencyInfo(code: "AED", symbol: "AED ", name: "UAE Dirham"),
        CurrencyInfo(code: "SAR", symbol: "SAR ", name: "Saudi Riyal"),
        CurrencyInfo(code: "CAD", symbol: "CA$", name: "Canadian Dollar"),
        CurrencyInfo(code: "AUD", symbol: "AU$", name: "Australian Dollar"),
        CurrencyInfo(code: "JPY", symbol: "¥", name: "Japanese Yen"),
        CurrencyInfo(code: "INR", symbol: "₹", name: "Indian Rupee"),
        CurrencyInfo(code: "CHF", symbol: "CHF ", name: "Swiss Franc")
    ]
}

public class CurrencyManager {
    public static let shared = CurrencyManager()
    
    private let currencyKey = "BudgetTracker_SelectedCurrencyCode"
    
    private init() {}
    
    public var currentCurrency: CurrencyInfo {
        let code = UserDefaults.standard.string(forKey: currencyKey) ?? Locale.current.currency?.identifier ?? "USD"
        return CurrencyInfo.supportedCurrencies.first(where: { $0.code == code }) ?? CurrencyInfo(code: "USD", symbol: "$", name: "US Dollar")
    }
    
    public func setCurrency(code: String) {
        UserDefaults.standard.set(code, forKey: currencyKey)
        NotificationCenter.default.post(name: .currencyDidChange, object: nil)
    }
    
    public func format(_ amount: Double, showSymbol: Bool = true) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        
        let numberString = formatter.string(from: NSNumber(value: abs(amount))) ?? String(format: "%.2f", abs(amount))
        
        if showSymbol {
            let symbol = currentCurrency.symbol
            if amount < 0 {
                return "-\(symbol)\(numberString)"
            } else {
                return "\(symbol)\(numberString)"
            }
        } else {
            return amount < 0 ? "-\(numberString)" : numberString
        }
    }
    
    public func formatWithSign(_ amount: Double, isIncome: Bool) -> String {
        let symbol = currentCurrency.symbol
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        let numberString = formatter.string(from: NSNumber(value: abs(amount))) ?? String(format: "%.2f", abs(amount))
        
        if isIncome {
            return "+\(symbol)\(numberString)"
        } else {
            return "-\(symbol)\(numberString)"
        }
    }
}

extension Notification.Name {
    public static let currencyDidChange = Notification.Name("BudgetTracker_CurrencyDidChange")
}
