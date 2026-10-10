//
//  AddAccountView.swift
//  BudgetTracker
//
//  Created by ali on 10/10/2026.
//

import SwiftUI

public struct AddAccountView: View {
    public var accountToEdit: AccountEntity?
    public var onDismiss: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var theme = ThemeManager.shared
    @ObservedObject private var currency = CurrencyManager.shared
    
    @State private var name: String = ""
    @State private var selectedType: AccountType = .bank
    @State private var balanceString: String = ""
    @State private var isDefault: Bool = false
    @State private var validationError: String?
    
    public init(accountToEdit: AccountEntity? = nil, onDismiss: @escaping () -> Void = {}) {
        self.accountToEdit = accountToEdit
        self.onDismiss = onDismiss
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Balance Hero
                    CardContainer {
                        VStack(spacing: 12) {
                            Text("INITIAL BALANCE")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(theme.colors.secondaryTextColor)
                                .tracking(1)
                            
                            HStack(alignment: .firstTextBaseline, spacing: 6) {
                                Text(currency.currentCurrency.symbol)
                                    .font(.system(size: 34, weight: .bold, design: .rounded))
                                    .foregroundColor(theme.colors.primaryColor)
                                
                                TextField("0.00", text: $balanceString)
                                    .font(.system(size: 44, weight: .heavy, design: .rounded))
                                    .foregroundColor(theme.colors.textColor)
                                    .keyboardType(.numbersAndPunctuation)
                                    .multilineTextAlignment(.center)
                                    .frame(maxWidth: 220)
                            }
                            
                            if let err = validationError {
                                Text(err)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(theme.colors.dangerColor)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                    }
                    
                    // Account Info Card
                    CardContainer {
                        VStack(spacing: 14) {
                            HStack {
                                Image(systemName: "pencil")
                                    .foregroundColor(theme.colors.secondaryTextColor)
                                    .frame(width: 24)
                                
                                TextField("Account Name (e.g., Chase Checking)", text: $name)
                                    .font(.system(size: 15))
                            }
                            
                            Divider()
                            
                            HStack {
                                Image(systemName: "creditcard")
                                    .foregroundColor(theme.colors.secondaryTextColor)
                                    .frame(width: 24)
                                
                                Text("Account Type")
                                    .font(.system(size: 15))
                                    .foregroundColor(theme.colors.textColor)
                                
                                Spacer()
                                
                                Picker("Type", selection: $selectedType) {
                                    ForEach(AccountType.allCases, id: \.self) { type in
                                        Label(type.rawValue, systemImage: type.iconName).tag(type)
                                    }
                                }
                                .pickerStyle(.menu)
                            }
                            
                            Divider()
                            
                            Toggle(isOn: $isDefault) {
                                Label("Primary Default Account", systemImage: "star")
                                    .font(.system(size: 15))
                            }
                        }
                    }
                    
                    // Save Button
                    Button(action: { saveAccount() }) {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 16, weight: .bold))
                            Text(accountToEdit != nil ? "Update Account" : "Save Account")
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
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(theme.colors.backgroundColor.ignoresSafeArea())
            .navigationTitle(accountToEdit != nil ? "Edit Account" : "New Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveAccount()
                    }
                    .fontWeight(.bold)
                }
            }
            .onAppear {
                if let acc = accountToEdit {
                    name = acc.name ?? ""
                    selectedType = AccountType(rawValue: acc.type ?? "Bank") ?? .bank
                    balanceString = String(format: "%.2f", acc.balance)
                    isDefault = acc.isDefault
                }
            }
        }
    }
    
    private func saveAccount() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            validationError = "Please enter an account name"
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            return
        }
        
        let balance = Double(balanceString) ?? 0.0
        
        if let editing = accountToEdit {
            editing.name = trimmed
            editing.type = selectedType.rawValue
            editing.balance = balance
            editing.isDefault = isDefault
            CoreDataManager.shared.saveContext()
        } else {
            _ = AccountManager.shared.createAccount(
                name: trimmed,
                type: selectedType,
                initialBalance: balance,
                isDefault: isDefault
            )
        }
        
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        onDismiss()
        dismiss()
    }
}
