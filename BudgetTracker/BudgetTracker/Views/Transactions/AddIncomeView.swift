//
//  AddIncomeView.swift
//  BudgetTracker
//
//  Created by ali on 10/10/2026.
//

import SwiftUI

public struct AddIncomeView: View {
    public var transactionToEdit: TransactionEntity?
    public var onDismiss: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var theme = ThemeManager.shared
    @ObservedObject private var currency = CurrencyManager.shared
    
    @State private var amountString: String = ""
    @State private var selectedSource: String = "Salary"
    @State private var title: String = ""
    @State private var transactionDate: Date = Date()
    @State private var selectedAccountId: UUID?
    @State private var note: String = ""
    @State private var isRecurring: Bool = false
    @State private var recurringFrequency: String = "Monthly"
    
    @State private var accounts: [AccountEntity] = []
    @State private var validationError: String?
    
    private let incomeSources: [(name: String, icon: String)] = [
        ("Salary", "briefcase.fill"),
        ("Freelance", "laptopcomputer"),
        ("Business", "building.2.fill"),
        ("Investment", "chart.line.uptrend.xyaxis"),
        ("Gift", "gift.fill"),
        ("Other", "ellipsis.circle.fill")
    ]
    
    private let frequencies = ["Weekly", "Bi-weekly", "Monthly", "Quarterly", "Yearly"]
    private let quickPresets: [Double] = [100, 500, 1000, 2500, 5000]
    
    public init(transactionToEdit: TransactionEntity? = nil, onDismiss: @escaping () -> Void = {}) {
        self.transactionToEdit = transactionToEdit
        self.onDismiss = onDismiss
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 1. Amount Hero Card
                    amountHeroSection
                    
                    // 2. Source Selector Chips
                    sourceSection
                    
                    // 3. Details Form Card
                    detailsCardSection
                    
                    // 4. Recurring Schedule Card
                    recurringCardSection
                    
                    // 5. Save Button
                    saveButtonSection
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(theme.colors.backgroundColor.ignoresSafeArea())
            .navigationTitle(transactionToEdit != nil ? "Edit Income" : "New Income")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveIncome()
                    }
                    .fontWeight(.bold)
                }
            }
            .onAppear {
                loadInitialData()
            }
        }
    }
    
    // MARK: - Amount Hero Card
    
    private var amountHeroSection: some View {
        CardContainer {
            VStack(spacing: 14) {
                Text("INCOME AMOUNT")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(theme.colors.secondaryTextColor)
                    .tracking(1)
                
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(currency.currentCurrency.symbol)
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundColor(theme.colors.successColor)
                    
                    TextField("0.00", text: $amountString)
                        .font(.system(size: 44, weight: .heavy, design: .rounded))
                        .foregroundColor(theme.colors.successColor)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 220)
                }
                
                if let error = validationError {
                    Text(error)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(theme.colors.dangerColor)
                }
                
                // Quick Presets
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(quickPresets, id: \.self) { preset in
                            Button(action: {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                let current = Double(amountString) ?? 0
                                let updated = current + preset
                                amountString = String(format: "%.0f", updated)
                                validationError = nil
                            }) {
                                Text("+\(currency.currentCurrency.symbol)\(Int(preset))")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(theme.colors.textColor)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(theme.colors.elevatedCardColor)
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule()
                                            .stroke(theme.colors.separatorColor.opacity(0.4), lineWidth: 0.5)
                                    )
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
        }
    }
    
    // MARK: - Income Source Section
    
    private var sourceSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Income Source")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(theme.colors.secondaryTextColor)
                .textCase(.uppercase)
                .tracking(0.5)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(incomeSources, id: \.name) { source in
                    let isSelected = selectedSource == source.name
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        selectedSource = source.name
                        if title.isEmpty {
                            title = "\(source.name) Deposit"
                        }
                    }) {
                        VStack(spacing: 8) {
                            Circle()
                                .fill(isSelected ? theme.colors.successColor : theme.colors.elevatedCardColor)
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Image(systemName: source.icon)
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(isSelected ? .white : theme.colors.textColor)
                                )
                            
                            Text(source.name)
                                .font(.system(size: 12, weight: isSelected ? .bold : .medium))
                                .foregroundColor(isSelected ? theme.colors.successColor : theme.colors.textColor)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(theme.colors.cardColor)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(isSelected ? theme.colors.successColor : theme.colors.separatorColor.opacity(0.3), lineWidth: isSelected ? 2 : 0.75)
                        )
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
        }
    }
    
    // MARK: - Details Card Section
    
    private var detailsCardSection: some View {
        CardContainer {
            VStack(spacing: 14) {
                // Title / Description
                HStack {
                    Image(systemName: "pencil")
                        .foregroundColor(theme.colors.secondaryTextColor)
                        .frame(width: 24)
                    
                    TextField("Title (e.g., Monthly Paycheck)", text: $title)
                        .font(.system(size: 15))
                }
                
                Divider()
                
                // Account selector
                HStack {
                    Image(systemName: "creditcard")
                        .foregroundColor(theme.colors.secondaryTextColor)
                        .frame(width: 24)
                    
                    Text("Deposit To")
                        .font(.system(size: 15))
                        .foregroundColor(theme.colors.textColor)
                    
                    Spacer()
                    
                    Picker("Account", selection: $selectedAccountId) {
                        Text("No Account").tag(UUID?.none)
                        ForEach(accounts, id: \.id) { acc in
                            Text("\(acc.name ?? "Account") (\(currency.format(acc.balance)))").tag(acc.id as UUID?)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Divider()
                
                // Date & Time
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(theme.colors.secondaryTextColor)
                        .frame(width: 24)
                    
                    Text("Date & Time")
                        .font(.system(size: 15))
                        .foregroundColor(theme.colors.textColor)
                    
                    Spacer()
                    
                    DatePicker("", selection: $transactionDate, displayedComponents: [.date, .hourAndMinute])
                        .labelsHidden()
                }
                
                Divider()
                
                // Note
                HStack(alignment: .top) {
                    Image(systemName: "note.text")
                        .foregroundColor(theme.colors.secondaryTextColor)
                        .frame(width: 24)
                        .padding(.top, 2)
                    
                    TextField("Add optional notes...", text: $note, axis: .vertical)
                        .font(.system(size: 15))
                        .lineLimit(2...4)
                }
            }
        }
    }
    
    // MARK: - Recurring Schedule Card
    
    private var recurringCardSection: some View {
        CardContainer {
            VStack(spacing: 12) {
                Toggle(isOn: $isRecurring) {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(Color.blue.opacity(0.12))
                            .frame(width: 36, height: 36)
                            .overlay(
                                Image(systemName: "repeat")
                                    .foregroundColor(.blue)
                                    .font(.system(size: 16, weight: .bold))
                            )
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Recurring Income")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(theme.colors.textColor)
                            
                            Text("Automatically log future occurrences")
                                .font(.system(size: 12))
                                .foregroundColor(theme.colors.secondaryTextColor)
                        }
                    }
                }
                
                if isRecurring {
                    Divider()
                    
                    HStack {
                        Text("Repeat Frequency")
                            .font(.system(size: 14))
                            .foregroundColor(theme.colors.secondaryTextColor)
                        
                        Spacer()
                        
                        Picker("Frequency", selection: $recurringFrequency) {
                            ForEach(frequencies, id: \.self) { freq in
                                Text(freq).tag(freq)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }
            }
        }
    }
    
    // MARK: - Save Button Section
    
    private var saveButtonSection: some View {
        Button(action: {
            saveIncome()
        }) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 18, weight: .bold))
                
                Text(transactionToEdit != nil ? "Update Income" : "Save Income")
                    .font(.system(size: 16, weight: .bold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(theme.colors.successColor)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: theme.colors.successColor.opacity(0.35), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(ScaleButtonStyle())
        .padding(.top, 6)
    }
    
    // MARK: - Logic
    
    private func loadInitialData() {
        accounts = AccountManager.shared.getAllAccounts()
        if selectedAccountId == nil, let first = accounts.first {
            selectedAccountId = first.id
        }
        
        if let editing = transactionToEdit {
            amountString = String(format: "%.2f", editing.amount)
            selectedSource = editing.category ?? "Salary"
            title = editing.title ?? ""
            transactionDate = editing.date ?? Date()
            selectedAccountId = editing.accountId
            note = editing.note ?? ""
            isRecurring = editing.isRecurring
            recurringFrequency = editing.recurringRule ?? "Monthly"
        }
    }
    
    private func saveIncome() {
        guard let amount = Double(amountString), amount > 0 else {
            validationError = "Please enter a valid income amount greater than 0"
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            return
        }
        
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalTitle = trimmedTitle.isEmpty ? "\(selectedSource) Income" : trimmedTitle
        
        if let editing = transactionToEdit {
            editing.amount = amount
            editing.category = selectedSource
            editing.title = finalTitle
            editing.date = transactionDate
            editing.note = note.isEmpty ? nil : note
            editing.accountId = selectedAccountId
            editing.isRecurring = isRecurring
            editing.recurringRule = isRecurring ? recurringFrequency : nil
            CoreDataManager.shared.saveContext()
        } else {
            _ = TransactionManager.shared.createTransaction(
                title: finalTitle,
                amount: amount,
                type: .income,
                category: selectedSource,
                merchant: nil,
                note: note.isEmpty ? nil : note,
                date: transactionDate,
                paymentMethod: "Direct Deposit",
                receiptImagePath: nil,
                isRecurring: isRecurring,
                recurringRule: isRecurring ? recurringFrequency : nil,
                accountId: selectedAccountId
            )
            
            // If recurring, also schedule in RecurringTransactionEntity
            if isRecurring {
                _ = TransactionManager.shared.createRecurringTransaction(
                    title: finalTitle,
                    amount: amount,
                    type: .income,
                    category: selectedSource,
                    frequency: recurringFrequency,
                    startDate: transactionDate,
                    accountId: selectedAccountId
                )
            }
        }
        
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        onDismiss()
        dismiss()
    }
}
