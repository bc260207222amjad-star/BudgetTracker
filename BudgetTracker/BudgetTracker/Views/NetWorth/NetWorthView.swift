//
//  NetWorthView.swift
//  BudgetTracker
//
//  Created by ali on 10/10/2026.
//

import SwiftUI

public struct NetWorthView: View {
    @ObservedObject private var theme = ThemeManager.shared
    @ObservedObject private var currency = CurrencyManager.shared
    @ObservedObject private var auth = BiometricAuthManager.shared
    
    @State private var accounts: [AccountEntity] = []
    @State private var debts: [DebtEntity] = []
    
    public init() {}
    
    private var totalAssets: Double {
        accounts.filter { $0.balance > 0 }.reduce(0.0) { $0 + $1.balance }
    }
    
    private var totalLiabilities: Double {
        let accountDebt = abs(accounts.filter { $0.balance < 0 }.reduce(0.0) { $0 + $1.balance })
        let trackedDebt = debts.reduce(0.0) { $0 + $1.remainingAmount }
        return accountDebt + trackedDebt
    }
    
    private var netWorth: Double {
        totalAssets - totalLiabilities
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 1. Hero Net Worth Card
                    heroNetWorthCard
                        .padding(.horizontal, 16)
                    
                    // 2. Assets Section
                    assetsSection
                        .padding(.horizontal, 16)
                    
                    // 3. Liabilities Section
                    liabilitiesSection
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)
                }
                .padding(.vertical, 12)
            }
            .background(theme.colors.backgroundColor.ignoresSafeArea())
            .navigationTitle("Net Worth")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                loadData()
            }
            .refreshable {
                loadData()
            }
        }
    }
    
    // MARK: - Hero Net Worth Card
    
    private var heroNetWorthCard: some View {
        CardContainer {
            VStack(spacing: 16) {
                Text("TOTAL NET WORTH")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(theme.colors.secondaryTextColor)
                    .tracking(0.5)
                
                if auth.hideBalance {
                    Text("••••••••")
                        .font(.system(size: 40, weight: .heavy, design: .rounded))
                        .foregroundColor(theme.colors.textColor)
                } else {
                    Text(currency.format(netWorth))
                        .font(.system(size: 40, weight: .heavy, design: .rounded))
                        .foregroundColor(netWorth >= 0 ? theme.colors.textColor : theme.colors.dangerColor)
                }
                
                // Asset vs Debt Proportion Bar
                let totalPool = totalAssets + totalLiabilities
                let assetRatio = totalPool > 0 ? (totalAssets / totalPool) : 1.0
                
                GeometryReader { geo in
                    HStack(spacing: 3) {
                        Capsule()
                            .fill(theme.colors.successColor)
                            .frame(width: geo.size.width * CGFloat(assetRatio))
                        
                        Capsule()
                            .fill(theme.colors.dangerColor)
                            .frame(width: max(geo.size.width * CGFloat(1.0 - assetRatio) - 3, 0))
                    }
                }
                .frame(height: 8)
                
                Divider()
                    .background(theme.colors.separatorColor.opacity(0.4))
                
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 4) {
                            Circle().fill(theme.colors.successColor).frame(width: 8, height: 8)
                            Text("Total Assets")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(theme.colors.secondaryTextColor)
                        }
                        Text(auth.hideBalance ? "••••••" : currency.format(totalAssets))
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .foregroundColor(theme.colors.successColor)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 3) {
                        HStack(spacing: 4) {
                            Circle().fill(theme.colors.dangerColor).frame(width: 8, height: 8)
                            Text("Total Liabilities")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(theme.colors.secondaryTextColor)
                        }
                        Text(auth.hideBalance ? "••••••" : "-\(currency.format(totalLiabilities))")
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .foregroundColor(theme.colors.dangerColor)
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    // MARK: - Assets Section
    
    private var assetsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Assets (What You Own)")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(theme.colors.textColor)
            
            let posAccounts = accounts.filter { $0.balance > 0 }
            if posAccounts.isEmpty {
                CardContainer {
                    Text("No positive asset accounts found.")
                        .font(.system(size: 13))
                        .foregroundColor(theme.colors.secondaryTextColor)
                }
            } else {
                CardContainer {
                    VStack(spacing: 12) {
                        ForEach(posAccounts, id: \.id) { acc in
                            let type = AccountType(rawValue: acc.type ?? "Bank") ?? .bank
                            HStack {
                                Image(systemName: type.iconName)
                                    .foregroundColor(theme.colors.successColor)
                                    .font(.system(size: 16))
                                    .frame(width: 24)
                                
                                Text(acc.name ?? "Account")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(theme.colors.textColor)
                                
                                Spacer()
                                
                                Text(currency.format(acc.balance))
                                    .font(.system(size: 15, weight: .bold, design: .monospaced))
                                    .foregroundColor(theme.colors.successColor)
                            }
                            
                            if acc.id != posAccounts.last?.id {
                                Divider()
                                    .background(theme.colors.separatorColor.opacity(0.3))
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Liabilities Section
    
    private var liabilitiesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Liabilities (What You Owe)")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(theme.colors.textColor)
            
            let negAccounts = accounts.filter { $0.balance < 0 }
            if negAccounts.isEmpty && debts.isEmpty {
                CardContainer {
                    Text("No liabilities or debts tracked. Excellent!")
                        .font(.system(size: 13))
                        .foregroundColor(theme.colors.secondaryTextColor)
                }
            } else {
                CardContainer {
                    VStack(spacing: 12) {
                        ForEach(negAccounts, id: \.id) { acc in
                            HStack {
                                Image(systemName: "creditcard.fill")
                                    .foregroundColor(theme.colors.dangerColor)
                                    .font(.system(size: 16))
                                    .frame(width: 24)
                                
                                Text(acc.name ?? "Credit Account")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(theme.colors.textColor)
                                
                                Spacer()
                                
                                Text("-\(currency.format(abs(acc.balance)))")
                                    .font(.system(size: 15, weight: .bold, design: .monospaced))
                                    .foregroundColor(theme.colors.dangerColor)
                            }
                            
                            Divider()
                                .background(theme.colors.separatorColor.opacity(0.3))
                        }
                        
                        ForEach(debts, id: \.id) { debt in
                            HStack {
                                Image(systemName: "doc.text.fill")
                                    .foregroundColor(theme.colors.dangerColor)
                                    .font(.system(size: 16))
                                    .frame(width: 24)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(debt.name ?? "Loan")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(theme.colors.textColor)
                                    Text(String(format: "%.1f%% APR", debt.interestRate))
                                        .font(.system(size: 11))
                                        .foregroundColor(theme.colors.secondaryTextColor)
                                }
                                
                                Spacer()
                                
                                Text("-\(currency.format(debt.remainingAmount))")
                                    .font(.system(size: 15, weight: .bold, design: .monospaced))
                                    .foregroundColor(theme.colors.dangerColor)
                            }
                            
                            if debt.id != debts.last?.id {
                                Divider()
                                    .background(theme.colors.separatorColor.opacity(0.3))
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func loadData() {
        accounts = AccountManager.shared.fetchAccounts()
        debts = DebtManager.shared.fetchDebts()
    }
}
