//
//  TransferView.swift
//  BudgetTracker
//
//  Created by ali on 10/10/2026.
//

import SwiftUI

public struct TransferView: View {
    public var onDismiss: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var theme = ThemeManager.shared
    @ObservedObject private var currency = CurrencyManager.shared
    
    @State private var accounts: [AccountEntity] = []
    @State private var fromAccount: AccountEntity?
    @State private var toAccount: AccountEntity?
    @State private var amountString: String = ""
    @State private var transferDate: Date = Date()
    @State private var note: String = ""
    @State private var validationError: String?
    
    public init(onDismiss: @escaping () -> Void = {}) {
        self.onDismiss = onDismiss
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 1. Amount Hero Card
                    amountHeroSection
                    
                    // 2. Transfer Accounts Card
                    accountsSelectionSection
                    
                    // 3. Details Card (Date & Note)
                    detailsCardSection
                    
                    // 4. Submit Transfer Button
                    submitButtonSection
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(theme.colors.backgroundColor.ignoresSafeArea())
            .navigationTitle("Transfer Money")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Transfer") {
                        performTransfer()
                    }
                    .fontWeight(.bold)
                }
            }
            .onAppear {
                loadAccounts()
            }
        }
    }
    
    // MARK: - Amount Hero Card
    
    private var amountHeroSection: some View {
        CardContainer {
            VStack(spacing: 12) {
                Text("TRANSFER AMOUNT")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(theme.colors.secondaryTextColor)
                    .tracking(1)
                
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(currency.currentCurrency.symbol)
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundColor(theme.colors.primaryColor)
                    
                    TextField("0.00", text: $amountString)
                        .font(.system(size: 44, weight: .heavy, design: .rounded))
                        .foregroundColor(theme.colors.textColor)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 220)
                }
                
                if let error = validationError {
                    Text(error)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(theme.colors.dangerColor)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
        }
    }
    
    // MARK: - Accounts Selection Section
    
    private var accountsSelectionSection: some View {
        CardContainer {
            VStack(spacing: 14) {
                // Source Account
                HStack {
                    Circle()
                        .fill(theme.colors.dangerColor.opacity(0.14))
                        .frame(width: 34, height: 34)
                        .overlay(
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(theme.colors.dangerColor)
                        )
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("From Account")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(theme.colors.secondaryTextColor)
                        
                        Picker("From", selection: $fromAccount) {
                            ForEach(accounts, id: \.id) { acc in
                                Text("\(acc.name ?? "Account") (\(currency.format(acc.balance)))").tag(acc as AccountEntity?)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    
                    Spacer()
                }
                
                Divider()
                
                // Destination Account
                HStack {
                    Circle()
                        .fill(theme.colors.successColor.opacity(0.14))
                        .frame(width: 34, height: 34)
                        .overlay(
                            Image(systemName: "arrow.down.left")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(theme.colors.successColor)
                        )
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("To Account")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(theme.colors.secondaryTextColor)
                        
                        Picker("To", selection: $toAccount) {
                            ForEach(accounts, id: \.id) { acc in
                                Text("\(acc.name ?? "Account") (\(currency.format(acc.balance)))").tag(acc as AccountEntity?)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    
                    Spacer()
                }
            }
        }
    }
    
    // MARK: - Details Card Section
    
    private var detailsCardSection: some View {
        CardContainer {
            VStack(spacing: 14) {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(theme.colors.secondaryTextColor)
                        .frame(width: 24)
                    
                    Text("Date")
                        .font(.system(size: 15))
                        .foregroundColor(theme.colors.textColor)
                    
                    Spacer()
                    
                    DatePicker("", selection: $transferDate, displayedComponents: [.date, .hourAndMinute])
                        .labelsHidden()
                }
                
                Divider()
                
                HStack {
                    Image(systemName: "note.text")
                        .foregroundColor(theme.colors.secondaryTextColor)
                        .frame(width: 24)
                    
                    TextField("Optional transfer note...", text: $note)
                        .font(.system(size: 15))
                }
            }
        }
    }
    
    // MARK: - Submit Button Section
    
    private var submitButtonSection: some View {
        Button(action: { performTransfer() }) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.system(size: 16, weight: .bold))
                Text("Confirm Transfer")
                    .font(.system(size: 16, weight: .bold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(theme.colors.primaryColor)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: theme.colors.primaryColor.opacity(0.35), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(ScaleButtonStyle())
        .padding(.top, 4)
    }
    
    // MARK: - Logic
    
    private func loadAccounts() {
        accounts = AccountManager.shared.fetchAccounts()
        if accounts.count >= 2 {
            fromAccount = accounts[0]
            toAccount = accounts[1]
        } else if let first = accounts.first {
            fromAccount = first
            toAccount = first
        }
    }
    
    private func performTransfer() {
        guard let amount = Double(amountString), amount > 0 else {
            validationError = "Please enter an amount greater than 0"
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            return
        }
        
        guard let from = fromAccount, let to = toAccount else {
            validationError = "Please select both source and target accounts"
            return
        }
        
        guard from.id != to.id else {
            validationError = "Source and destination accounts must be different"
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            return
        }
        
        AccountManager.shared.transferMoney(
            from: from,
            to: to,
            amount: amount,
            note: note.isEmpty ? nil : note,
            date: transferDate
        )
        
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        onDismiss()
        dismiss()
    }
}
