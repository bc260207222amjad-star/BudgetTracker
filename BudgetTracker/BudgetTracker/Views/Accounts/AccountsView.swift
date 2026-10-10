//
//  AccountsView.swift
//  BudgetTracker
//
//  Created by ali on 10/10/2026.
//

import SwiftUI

public struct AccountsView: View {
    @ObservedObject private var theme = ThemeManager.shared
    @ObservedObject private var currency = CurrencyManager.shared
    @ObservedObject private var auth = BiometricAuthManager.shared
    
    @State private var accounts: [AccountEntity] = []
    @State private var showAddAccount = false
    @State private var showTransferSheet = false
    @State private var editingAccount: AccountEntity?
    @State private var accountToDelete: AccountEntity?
    @State private var showDeleteAlert = false
    
    public init() {}
    
    private var totalBalance: Double {
        accounts.reduce(0.0) { $0 + $1.balance }
    }
    
    private var totalAssets: Double {
        accounts.filter { $0.balance > 0 }.reduce(0.0) { $0 + $1.balance }
    }
    
    private var totalLiabilities: Double {
        abs(accounts.filter { $0.balance < 0 }.reduce(0.0) { $0 + $1.balance })
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 1. Total Liquidity Hero Card
                    totalLiquidityHeroCard
                        .padding(.horizontal, 16)
                    
                    // 2. Action Buttons (Transfer & Add Account)
                    HStack(spacing: 12) {
                        Button(action: { showTransferSheet = true }) {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.left.arrow.right")
                                    .font(.system(size: 15, weight: .bold))
                                Text("Transfer Money")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(theme.colors.primaryColor)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .buttonStyle(ScaleButtonStyle())
                        
                        Button(action: { showAddAccount = true }) {
                            HStack(spacing: 8) {
                                Image(systemName: "plus")
                                    .font(.system(size: 15, weight: .bold))
                                Text("Add Account")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundColor(theme.colors.textColor)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(theme.colors.elevatedCardColor)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(theme.colors.separatorColor.opacity(0.4), lineWidth: 0.75)
                            )
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                    .padding(.horizontal, 16)
                    
                    // 3. Accounts List Card
                    accountsListSection
                        .padding(.horizontal, 16)
                }
                .padding(.vertical, 12)
            }
            .background(theme.colors.backgroundColor.ignoresSafeArea())
            .navigationTitle("Accounts & Wallets")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showAddAccount = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                    }
                }
            }
            .sheet(isPresented: $showAddAccount) {
                AddAccountView(onDismiss: { loadData() })
            }
            .sheet(isPresented: $showTransferSheet) {
                TransferView(onDismiss: { loadData() })
            }
            .sheet(item: $editingAccount) { acc in
                AddAccountView(accountToEdit: acc, onDismiss: { loadData() })
            }
            .alert("Delete Account", isPresented: $showDeleteAlert, presenting: accountToDelete) { acc in
                Button("Delete", role: .destructive) {
                    AccountManager.shared.deleteAccount(acc)
                    loadData()
                }
                Button("Cancel", role: .cancel) {}
            } message: { acc in
                Text("Are you sure you want to delete '\(acc.name ?? "Account")'?")
            }
            .onAppear {
                loadData()
            }
            .refreshable {
                loadData()
            }
        }
    }
    
    // MARK: - Total Liquidity Hero Card
    
    private var totalLiquidityHeroCard: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("TOTAL NET LIQUIDITY")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(theme.colors.secondaryTextColor)
                        .tracking(0.5)
                    
                    Spacer()
                    
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        auth.hideBalance.toggle()
                    }) {
                        Image(systemName: auth.hideBalance ? "eye.slash.fill" : "eye.fill")
                            .foregroundColor(theme.colors.secondaryTextColor)
                            .font(.system(size: 16))
                    }
                }
                
                if auth.hideBalance {
                    Text("••••••••")
                        .font(.system(size: 36, weight: .heavy, design: .rounded))
                        .foregroundColor(theme.colors.textColor)
                } else {
                    Text(currency.format(totalBalance))
                        .font(.system(size: 38, weight: .heavy, design: .rounded))
                        .foregroundColor(totalBalance >= 0 ? theme.colors.textColor : theme.colors.dangerColor)
                }
                
                Divider()
                    .background(theme.colors.separatorColor.opacity(0.4))
                
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Assets")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(theme.colors.secondaryTextColor)
                        Text(auth.hideBalance ? "••••" : currency.format(totalAssets))
                            .font(.system(size: 15, weight: .bold, design: .monospaced))
                            .foregroundColor(theme.colors.successColor)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Debts / Credit")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(theme.colors.secondaryTextColor)
                        Text(auth.hideBalance ? "••••" : "-\(currency.format(totalLiabilities))")
                            .font(.system(size: 15, weight: .bold, design: .monospaced))
                            .foregroundColor(totalLiabilities > 0 ? theme.colors.dangerColor : theme.colors.secondaryTextColor)
                    }
                }
            }
        }
    }
    
    // MARK: - Accounts List Section
    
    private var accountsListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("All Accounts")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(theme.colors.textColor)
            
            if accounts.isEmpty {
                EmptyStateContainer(
                    iconName: "building.columns",
                    title: "No Accounts",
                    subtitle: "Create accounts like Checking, Savings, or Credit Cards to track where your money lives.",
                    buttonTitle: "+ Add Account",
                    action: { showAddAccount = true }
                )
            } else {
                VStack(spacing: 10) {
                    ForEach(accounts, id: \.id) { acc in
                        accountRow(acc)
                    }
                }
            }
        }
    }
    
    private func accountRow(_ acc: AccountEntity) -> some View {
        let type = AccountType(rawValue: acc.type ?? "Bank") ?? .bank
        let isNegative = acc.balance < 0
        
        return CardContainer {
            HStack(spacing: 12) {
                Circle()
                    .fill((isNegative ? theme.colors.dangerColor : theme.colors.primaryColor).opacity(0.14))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: type.iconName)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(isNegative ? theme.colors.dangerColor : theme.colors.primaryColor)
                    )
                
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(acc.name ?? "Account")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(theme.colors.textColor)
                        
                        if acc.isDefault {
                            Text("DEFAULT")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(theme.colors.primaryColor)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(theme.colors.primaryColor.opacity(0.12))
                                .clipShape(Capsule())
                        }
                    }
                    
                    Text(acc.type ?? "Bank")
                        .font(.system(size: 12))
                        .foregroundColor(theme.colors.secondaryTextColor)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    if auth.hideBalance {
                        Text("••••••")
                            .font(.system(size: 15, weight: .bold, design: .monospaced))
                            .foregroundColor(theme.colors.textColor)
                    } else {
                        Text(currency.format(acc.balance))
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .foregroundColor(isNegative ? theme.colors.dangerColor : theme.colors.textColor)
                    }
                }
                
                Menu {
                    Button(action: { editingAccount = acc }) {
                        Label("Edit Account", systemImage: "pencil")
                    }
                    
                    Button(role: .destructive, action: {
                        accountToDelete = acc
                        showDeleteAlert = true
                    }) {
                        Label("Delete Account", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16))
                        .foregroundColor(theme.colors.secondaryTextColor)
                        .padding(6)
                }
            }
        }
    }
    
    private func loadData() {
        AccountManager.shared.ensureDefaultAccountsExist()
        accounts = AccountManager.shared.fetchAccounts()
    }
}
