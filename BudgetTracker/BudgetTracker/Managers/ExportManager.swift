//
//  ExportManager.swift
//  BudgetTracker
//
//  Created by ali on 10/10/2026.
//

import UIKit
import PDFKit
import UniformTypeIdentifiers

public struct MonthlyReportSummary {
    public let monthName: String
    public let year: Int
    public let totalIncome: Double
    public let totalExpense: Double
    public let netSavings: Double
    public let savingsRate: Double
    public let topSpendingCategory: (name: String, amount: Double)?
    public let previousMonthComparisonText: String
}

public class ExportManager {
    public static let shared = ExportManager()
    
    private init() {}
    
    // MARK: - CSV Export
    
    public func generateCSV(transactions: [TransactionEntity]) -> URL? {
        var csvString = "Date,Type,Amount,Category,Merchant,Payment Method,Note\n"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        
        for item in transactions {
            let dateStr = item.date != nil ? dateFormatter.string(from: item.date!) : ""
            let typeStr = item.type ?? "expense"
            let amountStr = String(format: "%.2f", item.amount)
            let catStr = cleanCSVField(item.category ?? "")
            let merchantStr = cleanCSVField(item.merchant ?? "")
            let pmStr = cleanCSVField(item.paymentMethod ?? "")
            let noteStr = cleanCSVField(item.note ?? "")
            
            csvString += "\(dateStr),\(typeStr),\(amountStr),\(catStr),\(merchantStr),\(pmStr),\(noteStr)\n"
        }
        
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("BudgetTracker_Export_\(Int(Date().timeIntervalSince1970)).csv")
        do {
            try csvString.write(to: tempURL, atomically: true, encoding: .utf8)
            return tempURL
        } catch {
            print("Failed to write CSV: \(error)")
            return nil
        }
    }
    
    private func cleanCSVField(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") {
            let escaped = field.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return field
    }
    
    // MARK: - Monthly Report Calculation
    
    public func getMonthlyReport(for monthDate: Date = Date()) -> MonthlyReportSummary {
        let calendar = Calendar.current
        let comps = calendar.dateComponents([.year, .month], from: monthDate)
        let monthNameFormatter = DateFormatter()
        monthNameFormatter.dateFormat = "MMMM"
        let monthName = monthNameFormatter.string(from: monthDate)
        let year = comps.year ?? 2026
        
        guard let startOfMonth = calendar.date(from: comps),
              let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1, hour: 23, minute: 59, second: 59), to: startOfMonth) else {
            return MonthlyReportSummary(monthName: monthName, year: year, totalIncome: 0, totalExpense: 0, netSavings: 0, savingsRate: 0, topSpendingCategory: nil, previousMonthComparisonText: "No prior month data")
        }
        
        let currentMonthTransactions = TransactionManager.shared.fetchTransactions(startDate: startOfMonth, endDate: endOfMonth)
        var income: Double = 0
        var expense: Double = 0
        var categoryMap: [String: Double] = [:]
        
        for item in currentMonthTransactions {
            if item.type == TransactionType.income.rawValue {
                income += item.amount
            } else if item.type == TransactionType.expense.rawValue {
                expense += item.amount
                let cat = item.category ?? "Other"
                categoryMap[cat, default: 0] += item.amount
            }
        }
        
        let savings = max(income - expense, 0)
        let savingsRate = income > 0 ? (savings / income) : 0
        
        let topCategory = categoryMap.max { $0.value < $1.value }.map { ($0.key, $0.value) }
        
        // Prior month calculation
        guard let prevMonthStart = calendar.date(byAdding: .month, value: -1, to: startOfMonth),
              let prevMonthEnd = calendar.date(byAdding: DateComponents(month: 1, day: -1, hour: 23, minute: 59, second: 59), to: prevMonthStart) else {
            return MonthlyReportSummary(monthName: monthName, year: year, totalIncome: income, totalExpense: expense, netSavings: savings, savingsRate: savingsRate, topSpendingCategory: topCategory, previousMonthComparisonText: "No prior month data")
        }
        
        let prevMonthTransactions = TransactionManager.shared.fetchTransactions(startDate: prevMonthStart, endDate: prevMonthEnd)
        let prevExpense = prevMonthTransactions.filter { $0.type == TransactionType.expense.rawValue }.reduce(0) { $0 + $1.amount }
        
        let prevMonthName = monthNameFormatter.string(from: prevMonthStart)
        let comparisonText: String
        if prevExpense > 0 {
            let diff = ((expense - prevExpense) / prevExpense) * 100
            if diff < 0 {
                comparisonText = String(format: "Your spending decreased by %.1f%% compared with %@.", abs(diff), prevMonthName)
            } else if diff > 0 {
                comparisonText = String(format: "Your spending increased by %.1f%% compared with %@.", diff, prevMonthName)
            } else {
                comparisonText = "Your spending was equal to \(prevMonthName)."
            }
        } else {
            comparisonText = "No previous month expenses to compare."
        }
        
        return MonthlyReportSummary(
            monthName: monthName,
            year: year,
            totalIncome: income,
            totalExpense: expense,
            netSavings: savings,
            savingsRate: savingsRate,
            topSpendingCategory: topCategory,
            previousMonthComparisonText: comparisonText
        )
    }
    
    // MARK: - PDF Report Generation
    
    public func generatePDFReport(for monthDate: Date = Date()) -> URL? {
        let report = getMonthlyReport(for: monthDate)
        let currency = CurrencyManager.shared
        
        let pageWidth: CGFloat = 612
        let pageHeight: CGFloat = 792
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("Report_\(report.monthName)_\(report.year).pdf")
        
        do {
            try renderer.writePDF(to: tempURL) { context in
                context.beginPage()
                
                var currentY: CGFloat = 40
                
                // Header Banner
                let headerRect = CGRect(x: 36, y: currentY, width: pageWidth - 72, height: 60)
                let headerBackground = UIBezierPath(roundedRect: headerRect, cornerRadius: 10)
                UIColor.systemBlue.setFill()
                headerBackground.fill()
                
                let titleAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: 22),
                    .foregroundColor: UIColor.white
                ]
                let titleText = "\(report.monthName) \(report.year) Financial Report"
                (titleText as NSString).draw(at: CGPoint(x: 52, y: currentY + 16), withAttributes: titleAttributes)
                
                currentY += 80
                
                // Key Metrics Box
                let metricsRect = CGRect(x: 36, y: currentY, width: pageWidth - 72, height: 110)
                let metricsPath = UIBezierPath(roundedRect: metricsRect, cornerRadius: 8)
                UIColor.secondarySystemBackground.setFill()
                metricsPath.fill()
                
                let labelFont = UIFont.systemFont(ofSize: 13, weight: .regular)
                let valueFont = UIFont.boldSystemFont(ofSize: 20)
                
                let colWidth = (pageWidth - 72) / 3
                
                // Income
                let incomeLabelAttr: [NSAttributedString.Key: Any] = [.font: labelFont, .foregroundColor: UIColor.secondaryLabel]
                ("TOTAL INCOME" as NSString).draw(at: CGPoint(x: 52, y: currentY + 18), withAttributes: incomeLabelAttr)
                let incomeValAttr: [NSAttributedString.Key: Any] = [.font: valueFont, .foregroundColor: UIColor.systemGreen]
                (currency.format(report.totalIncome) as NSString).draw(at: CGPoint(x: 52, y: currentY + 40), withAttributes: incomeValAttr)
                
                // Expenses
                ("TOTAL EXPENSES" as NSString).draw(at: CGPoint(x: 52 + colWidth, y: currentY + 18), withAttributes: incomeLabelAttr)
                let expValAttr: [NSAttributedString.Key: Any] = [.font: valueFont, .foregroundColor: UIColor.systemRed]
                (currency.format(report.totalExpense) as NSString).draw(at: CGPoint(x: 52 + colWidth, y: currentY + 40), withAttributes: expValAttr)
                
                // Savings
                ("NET SAVINGS" as NSString).draw(at: CGPoint(x: 52 + colWidth * 2, y: currentY + 18), withAttributes: incomeLabelAttr)
                let savValAttr: [NSAttributedString.Key: Any] = [.font: valueFont, .foregroundColor: UIColor.systemBlue]
                (currency.format(report.netSavings) as NSString).draw(at: CGPoint(x: 52 + colWidth * 2, y: currentY + 40), withAttributes: savValAttr)
                
                // Savings Rate
                let rateText = String(format: "Savings Rate: %.1f%%", report.savingsRate * 100)
                let rateAttr: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 13, weight: .semibold), .foregroundColor: UIColor.label]
                (rateText as NSString).draw(at: CGPoint(x: 52, y: currentY + 76), withAttributes: rateAttr)
                
                currentY += 130
                
                // Comparison text
                let compAttr: [NSAttributedString.Key: Any] = [
                    .font: UIFont.italicSystemFont(ofSize: 14),
                    .foregroundColor: UIColor.secondaryLabel
                ]
                (report.previousMonthComparisonText as NSString).draw(at: CGPoint(x: 36, y: currentY), withAttributes: compAttr)
                
                currentY += 40
                
                // Top Categories Section
                let sectionTitleAttr: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: 16),
                    .foregroundColor: UIColor.label
                ]
                ("Spending by Category" as NSString).draw(at: CGPoint(x: 36, y: currentY), withAttributes: sectionTitleAttr)
                
                currentY += 26
                
                let spending = TransactionManager.shared.getCategorySpending(monthDate: monthDate)
                let sortedSpending = spending.sorted { $0.value > $1.value }
                
                let rowFont = UIFont.systemFont(ofSize: 13)
                for (cat, amount) in sortedSpending.prefix(8) {
                    let catAttr: [NSAttributedString.Key: Any] = [.font: rowFont, .foregroundColor: UIColor.label]
                    (cat as NSString).draw(at: CGPoint(x: 46, y: currentY), withAttributes: catAttr)
                    
                    let amtStr = currency.format(amount)
                    let amtAttr: [NSAttributedString.Key: Any] = [.font: UIFont.boldSystemFont(ofSize: 13), .foregroundColor: UIColor.systemRed]
                    let size = (amtStr as NSString).size(withAttributes: amtAttr)
                    (amtStr as NSString).draw(at: CGPoint(x: pageWidth - 46 - size.width, y: currentY), withAttributes: amtAttr)
                    
                    currentY += 22
                }
                
                currentY += 20
                
                // Recent Transactions Table
                ("Recent Transactions This Month" as NSString).draw(at: CGPoint(x: 36, y: currentY), withAttributes: sectionTitleAttr)
                currentY += 26
                
                let calendar = Calendar.current
                let comps = calendar.dateComponents([.year, .month], from: monthDate)
                let startOfMonth = calendar.date(from: comps)!
                let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!
                let recent = TransactionManager.shared.fetchTransactions(startDate: startOfMonth, endDate: endOfMonth, limit: 10)
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "MMM d"
                
                for tx in recent {
                    let dStr = tx.date != nil ? dateFormatter.string(from: tx.date!) : ""
                    let titleStr = "\(dStr) - \(tx.title ?? "Transaction") (\(tx.category ?? "General"))"
                    (titleStr as NSString).draw(at: CGPoint(x: 46, y: currentY), withAttributes: [.font: rowFont, .foregroundColor: UIColor.label])
                    
                    let isInc = tx.type == TransactionType.income.rawValue
                    let sign = isInc ? "+" : "-"
                    let color: UIColor = isInc ? .systemGreen : .label
                    let valStr = "\(sign)\(currency.format(tx.amount))"
                    let valAttr: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 13, weight: .medium), .foregroundColor: color]
                    let valSize = (valStr as NSString).size(withAttributes: valAttr)
                    (valStr as NSString).draw(at: CGPoint(x: pageWidth - 46 - valSize.width, y: currentY), withAttributes: valAttr)
                    
                    currentY += 22
                }
                
                // Footer
                let footerText = "Generated securely by BudgetTracker • Privacy-First Offline Architecture"
                let footerAttr: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 10),
                    .foregroundColor: UIColor.tertiaryLabel
                ]
                let footerSize = (footerText as NSString).size(withAttributes: footerAttr)
                (footerText as NSString).draw(at: CGPoint(x: (pageWidth - footerSize.width) / 2, y: pageHeight - 36), withAttributes: footerAttr)
            }
            return tempURL
        } catch {
            print("Failed to generate PDF: \(error)")
            return nil
        }
    }
}
