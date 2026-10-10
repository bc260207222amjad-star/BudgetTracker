//
//  DebtTrackerView.swift
//  BudgetTracker
//
//  Created by ali on 10/10/2026.
//

import SwiftUI

public struct DebtTrackerView: View {
    @ObservedObject private var theme = ThemeManager.shared
    @ObservedObject private var currency = CurrencyManager.shared
    
    @State private var debts: [DebtEntity] = []
    @State private var selectedStrategy: DebtStrategy = .snowball
    @State private var showAddDebtSheet = false
    @State private var editingDebt: DebtEntity?
    @State private var debtForPayment: DebtEntity?
    @State private var paymentAmountString = ""
    @State private var debtToDelete: DebtEntity?
    @State private var showDeleteAlert = false
    
    public init() {}
    
    private var totalDebtRemaining: Double {
        debts.reduce(0.0) { $0 + $1.remainingAmount }
    }
    
    private var totalOriginalDebt: Double {
        debts.reduce(0.0) { $0 + $1.totalAmount }
    }
    
    private var totalMonthlyMinimum: Double {
        debts.reduce(0.0) { $0 + $1.minimumPayment }
    }
    
    private var overallProgress: Double {
        guard totalOriginalDebt > 0 else { return 0 }
        let paid = max(totalOriginalDebt - totalDebtRemaining, 0)
        return min(max(paid / totalOriginalDebt, 0), 1.0)
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 1. Debt Overview Hero Card
                    debtOverviewHeroCard
                        .padding(.horizontal, 16)
                    
                    // 2. Payoff Strategy Selector
                    strategySelectorSection
                        .padding(.horizontal, 16)
                    
                    // 3. Debts List
                    debtsListSection
                        .padding(.horizontal, 16)
                    
                    // 4. Educational Disclaimer Banner
                    disclaimerBanner
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)
                }
                .padding(.vertical, 12)
            }
            .background(theme.colors.backgroundColor.ignoresSafeArea())
            .navigationTitle("Debt Payoff")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showAddDebtSheet = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                    }
                }
            }
            .sheet(isPresented: $showAddDebtSheet) {
                AddDebtSheet(onDismiss: { loadData() })
            }
            .sheet(item: $editingDebt) { debt in
                AddDebtSheet(debtToEdit: debt, onDismiss: { loadData() })
            }
            .sheet(item: $debtForPayment) { debt in
                recordPaymentSheet(debt: debt)
            }
            .alert("Delete Debt", isPresented: $showDeleteAlert, presenting: debtToDelete) { d in
                Button("Delete", role: .destructive) {
                    DebtManager.shared.deleteDebt(d)
                    loadData()
                }
                Button("Cancel", role: .cancel) {}
            } message: { d in
                Text("Are you sure you want to delete '\(d.name ?? "Debt")'?")
            }
            .onAppear {
                loadData()
            }
            .refreshable {
                loadData()
            }
        }
    }
    
    // MARK: - Hero Card
    
    private var debtOverviewHeroCard: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 14) {
                Text("TOTAL REMAINING DEBT")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(theme.colors.secondaryTextColor)
                    .tracking(0.5)
                
                Text(currency.format(totalDebtRemaining))
                    .font(.system(size: 38, weight: .heavy, design: .rounded))
                    .foregroundColor(theme.colors.dangerColor)
                
                // Progress Bar
                CustomProgressBar(
                    progress: overallProgress,
                    color: theme.colors.successColor
                )
                
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Paid Off")
                            .font(.system(size: 11))
                            .foregroundColor(theme.colors.secondaryTextColor)
                        let paid = max(totalOriginalDebt - totalDebtRemaining, 0)
                        Text(currency.format(paid))
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(theme.colors.successColor)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .center, spacing: 2) {
                        Text("Progress")
                            .font(.system(size: 11))
                            .foregroundColor(theme.colors.secondaryTextColor)
                        Text("\(Int(overallProgress * 100))%")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(theme.colors.textColor)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Monthly Min")
                            .font(.system(size: 11))
                            .foregroundColor(theme.colors.secondaryTextColor)
                        Text(currency.format(totalMonthlyMinimum))
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(theme.colors.textColor)
                    }
                }
            }
        }
    }
    
    // MARK: - Strategy Selector
    
    private var strategySelectorSection: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 10) {
                Text("PAYOFF ACCELERATOR")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(theme.colors.secondaryTextColor)
                    .tracking(0.5)
                
                Picker("Strategy", selection: $selectedStrategy) {
                    ForEach(DebtStrategy.allCases, id: \.self) { s in
                        Text(s.rawValue).tag(s)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: selectedStrategy) { _ in
                    loadData()
                }
                
                Text(selectedStrategy.description)
                    .font(.system(size: 13))
                    .foregroundColor(theme.colors.secondaryTextColor)
                    .padding(.top, 2)
            }
        }
    }
    
    // MARK: - Debts List Section
    
    private var debtsListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Prioritized Debts")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(theme.colors.textColor)
                
                Spacer()
                
                Text("\(debts.count) items")
                    .font(.system(size: 13))
                    .foregroundColor(theme.colors.secondaryTextColor)
            }
            
            if debts.isEmpty {
                EmptyStateContainer(
                    iconName: "creditcard.and.123",
                    title: "Debt Free!",
                    subtitle: "No debts tracked. Add credit cards, student loans, or mortgages to plan your payoff journey.",
                    buttonTitle: "+ Add Debt",
                    action: { showAddDebtSheet = true }
                )
            } else {
                VStack(spacing: 12) {
                    ForEach(Array(debts.enumerated()), id: \.element.id) { index, debt in
                        debtCard(debt: debt, priorityRank: index + 1)
                    }
                }
            }
        }
    }
    
    private func debtCard(debt: DebtEntity, priorityRank: Int) -> some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Circle()
                        .fill(theme.colors.primaryColor.opacity(0.14))
                        .frame(width: 28, height: 28)
                        .overlay(
                            Text("#\(priorityRank)")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(theme.colors.primaryColor)
                        )
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(debt.name ?? "Debt Account")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(theme.colors.textColor)
                        
                        Text("\(debt.debtType ?? "Loan") • \(String(format: "%.1f%% APR", debt.interestRate))")
                            .font(.system(size: 12))
                            .foregroundColor(theme.colors.secondaryTextColor)
                    }
                    
                    Spacer()
                    
                    Menu {
                        Button(action: {
                            debtForPayment = debt
                            paymentAmountString = String(format: "%.0f", debt.minimumPayment)
                        }) {
                            Label("Make Payment", systemImage: "banknote")
                        }
                        
                        Button(action: { editingDebt = debt }) {
                            Label("Edit", systemImage: "pencil")
                        }
                        
                        Button(role: .destructive, action: {
                            debtToDelete = debt
                            showDeleteAlert = true
                        }) {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 16))
                            .foregroundColor(theme.colors.secondaryTextColor)
                            .padding(6)
                    }
                }
                
                CustomProgressBar(
                    progress: debt.progressPercentage,
                    color: theme.colors.primaryColor
                )
                
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Remaining")
                            .font(.system(size: 11))
                            .foregroundColor(theme.colors.secondaryTextColor)
                        Text(currency.format(debt.remainingAmount))
                            .font(.system(size: 15, weight: .bold, design: .monospaced))
                            .foregroundColor(theme.colors.dangerColor)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Min Payment")
                            .font(.system(size: 11))
                            .foregroundColor(theme.colors.secondaryTextColor)
                        Text(currency.format(debt.minimumPayment))
                            .font(.system(size: 14, weight: .semibold, design: .monospaced))
                            .foregroundColor(theme.colors.textColor)
                    }
                }
                
                Button(action: {
                    debtForPayment = debt
                    paymentAmountString = String(format: "%.0f", debt.minimumPayment)
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Log Payment")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(theme.colors.primaryColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(theme.colors.primaryColor.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
    }
    
    // MARK: - Disclaimer Banner
    
    private var disclaimerBanner: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "info.circle.fill")
                .foregroundColor(theme.colors.secondaryTextColor)
                .font(.system(size: 14))
                .padding(.top, 2)
            
            Text(DebtManager.disclaimerText)
                .font(.system(size: 12))
                .foregroundColor(theme.colors.secondaryTextColor)
                .lineSpacing(3)
        }
        .padding(12)
        .background(theme.colors.elevatedCardColor)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
    
    // MARK: - Payment Sheet
    
    private func recordPaymentSheet(debt: DebtEntity) -> some View {
        NavigationStack {
            VStack(spacing: 20) {
                CardContainer {
                    VStack(spacing: 12) {
                        Text("PAYMENT FOR \(debt.name?.uppercased() ?? "DEBT")")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(theme.colors.secondaryTextColor)
                            .tracking(1)
                        
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text(currency.currentCurrency.symbol)
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(theme.colors.successColor)
                            
                            TextField("0.00", text: $paymentAmountString)
                                .font(.system(size: 40, weight: .heavy, design: .rounded))
                                .foregroundColor(theme.colors.textColor)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: 180)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                
                Button(action: {
                    if let amt = Double(paymentAmountString), amt > 0 {
                        DebtManager.shared.recordPayment(debt: debt, paymentAmount: amt)
                        debtForPayment = nil
                        loadData()
                    }
                }) {
                    Text("Apply Payment")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(theme.colors.successColor)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(ScaleButtonStyle())
                
                Spacer()
            }
            .padding(16)
            .background(theme.colors.backgroundColor.ignoresSafeArea())
            .navigationTitle("Log Debt Payment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { debtForPayment = nil }
                }
            }
        }
    }
    
    private func loadData() {
        debts = DebtManager.shared.fetchDebts(strategy: selectedStrategy)
    }
}

// MARK: - Add Debt Sheet

public struct AddDebtSheet: View {
    public var debtToEdit: DebtEntity?
    public var onDismiss: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var theme = ThemeManager.shared
    @ObservedObject private var currency = CurrencyManager.shared
    
    @State private var name: String = ""
    @State private var totalAmountString: String = ""
    @State private var remainingAmountString: String = ""
    @State private var interestRateString: String = "19.9"
    @State private var minPaymentString: String = ""
    @State private var selectedType: DebtType = .creditCard
    @State private var dueDate: Date = Date()
    @State private var validationError: String?
    
    public init(debtToEdit: DebtEntity? = nil, onDismiss: @escaping () -> Void = {}) {
        self.debtToEdit = debtToEdit
        self.onDismiss = onDismiss
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    CardContainer {
                        VStack(spacing: 14) {
                            HStack {
                                Image(systemName: "pencil")
                                    .foregroundColor(theme.colors.secondaryTextColor)
                                    .frame(width: 24)
                                TextField("Debt Name (e.g. Chase Sapphire)", text: $name)
                                    .font(.system(size: 15))
                            }
                            
                            Divider()
                            
                            HStack {
                                Image(systemName: "tag.fill")
                                    .foregroundColor(theme.colors.secondaryTextColor)
                                    .frame(width: 24)
                                Text("Type")
                                    .font(.system(size: 15))
                                Spacer()
                                Picker("Type", selection: $selectedType) {
                                    ForEach(DebtType.allCases, id: \.self) { type in
                                        Text(type.rawValue).tag(type)
                                    }
                                }
                                .pickerStyle(.menu)
                            }
                        }
                    }
                    
                    CardContainer {
                        VStack(spacing: 14) {
                            HStack {
                                Text("Remaining Balance")
                                    .font(.system(size: 15))
                                Spacer()
                                TextField("0.00", text: $remainingAmountString)
                                    .font(.system(size: 15, weight: .bold))
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .frame(maxWidth: 120)
                            }
                            
                            Divider()
                            
                            HStack {
                                Text("Total Original Balance")
                                    .font(.system(size: 15))
                                Spacer()
                                TextField("0.00", text: $totalAmountString)
                                    .font(.system(size: 15, weight: .bold))
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .frame(maxWidth: 120)
                            }
                            
                            Divider()
                            
                            HStack {
                                Text("Interest Rate (% APR)")
                                    .font(.system(size: 15))
                                Spacer()
                                TextField("19.9", text: $interestRateString)
                                    .font(.system(size: 15, weight: .bold))
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .frame(maxWidth: 80)
                            }
                            
                            Divider()
                            
                            HStack {
                                Text("Minimum Monthly Payment")
                                    .font(.system(size: 15))
                                Spacer()
                                TextField("0.00", text: $minPaymentString)
                                    .font(.system(size: 15, weight: .bold))
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .frame(maxWidth: 120)
                            }
                        }
                    }
                    
                    if let err = validationError {
                        Text(err)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(theme.colors.dangerColor)
                    }
                    
                    Button(action: { saveDebt() }) {
                        Text(debtToEdit != nil ? "Update Debt" : "Save Debt")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(theme.colors.primaryColor)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .padding(.top, 4)
                }
                .padding(16)
            }
            .background(theme.colors.backgroundColor.ignoresSafeArea())
            .navigationTitle(debtToEdit != nil ? "Edit Debt" : "Add Debt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveDebt() }.fontWeight(.bold)
                }
            }
            .onAppear {
                if let d = debtToEdit {
                    name = d.name ?? ""
                    selectedType = DebtType(rawValue: d.debtType ?? "Credit Card") ?? .creditCard
                    remainingAmountString = String(format: "%.2f", d.remainingAmount)
                    totalAmountString = String(format: "%.2f", d.totalAmount)
                    interestRateString = String(format: "%.1f", d.interestRate)
                    minPaymentString = String(format: "%.2f", d.minimumPayment)
                }
            }
        }
    }
    
    private func saveDebt() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            validationError = "Please enter a name for this debt"
            return
        }
        guard let rem = Double(remainingAmountString), rem > 0 else {
            validationError = "Please enter a valid remaining balance"
            return
        }
        let total = Double(totalAmountString) ?? rem
        let apr = Double(interestRateString) ?? 0.0
        let minPay = Double(minPaymentString) ?? (rem * 0.03)
        
        if let editing = debtToEdit {
            DebtManager.shared.updateDebt(
                debt: editing,
                name: trimmed,
                totalAmount: total,
                remainingAmount: rem,
                interestRate: apr,
                minimumPayment: minPay,
                dueDate: dueDate,
                debtType: selectedType
            )
        } else {
            DebtManager.shared.createDebt(
                name: trimmed,
                totalAmount: total,
                remainingAmount: rem,
                interestRate: apr,
                minimumPayment: minPay,
                dueDate: dueDate,
                debtType: selectedType
            )
        }
        
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        onDismiss()
        dismiss()
    }
}
