//
//  TransactionDetailView.swift
//  BudgetTracker
//
//  Created by ali on 10/10/2026.
//

import SwiftUI

public struct TransactionDetailView: View {
    @ObservedObject public var transaction: TransactionEntity
    public var onDismiss: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var theme = ThemeManager.shared
    @ObservedObject private var currency = CurrencyManager.shared
    @ObservedObject private var auth = BiometricAuthManager.shared
    
    @State private var showEditSheet = false
    @State private var showDeleteAlert = false
    @State private var showFullReceipt = false
    @State private var accountName: String? = nil
    @State private var receiptImage: UIImage? = nil
    
    public init(transaction: TransactionEntity, onDismiss: @escaping () -> Void = {}) {
        self.transaction = transaction
        self.onDismiss = onDismiss
    }
    
    private var isIncome: Bool {
        transaction.type == "income"
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 1. Hero Amount Card
                    heroAmountCard
                    
                    // 2. Metadata Details Card
                    metadataDetailsCard
                    
                    // 3. Receipt Preview Card (if any)
                    if let path = transaction.receiptImagePath, !path.isEmpty {
                        receiptPreviewCard(path: path)
                    }
                    
                    // 4. Action Buttons
                    actionButtonsSection
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(theme.colors.backgroundColor.ignoresSafeArea())
            .navigationTitle("Transaction Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showEditSheet = true }) {
                        Text("Edit")
                            .fontWeight(.semibold)
                    }
                }
            }
            .sheet(isPresented: $showEditSheet) {
                if isIncome {
                    AddIncomeView(transactionToEdit: transaction, onDismiss: {
                        loadDetails()
                        onDismiss()
                    })
                } else {
                    AddExpenseView(transactionToEdit: transaction, onDismiss: {
                        loadDetails()
                        onDismiss()
                    })
                }
            }
            .sheet(isPresented: $showFullReceipt) {
                if let img = receiptImage {
                    NavigationStack {
                        ZStack {
                            Color.black.ignoresSafeArea()
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFit()
                                .padding()
                        }
                        .navigationTitle("Receipt")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Close") {
                                    showFullReceipt = false
                                }
                                .foregroundColor(.white)
                            }
                        }
                    }
                }
            }
            .alert("Delete Transaction", isPresented: $showDeleteAlert) {
                Button("Delete", role: .destructive) {
                    TransactionManager.shared.deleteTransaction(transaction)
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    onDismiss()
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to delete '\(transaction.title ?? "this transaction")'? This action cannot be undone.")
            }
            .onAppear {
                loadDetails()
            }
        }
    }
    
    // MARK: - Hero Amount Card
    
    private var heroAmountCard: some View {
        CardContainer {
            VStack(spacing: 12) {
                // Category Icon
                let cat = CategoryManager.shared.category(named: transaction.category ?? "Other")
                Circle()
                    .fill(cat.color.opacity(0.16))
                    .frame(width: 58, height: 58)
                    .overlay(
                        Image(systemName: cat.iconName)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(cat.color)
                    )
                
                // Amount Display
                let sign = isIncome ? "+" : "-"
                let amountColor = isIncome ? theme.colors.successColor : theme.colors.dangerColor
                
                if auth.hideTransactionAmounts {
                    Text("••••••")
                        .font(.system(size: 38, weight: .heavy, design: .rounded))
                        .foregroundColor(theme.colors.textColor)
                } else {
                    Text("\(sign)\(currency.format(transaction.amount))")
                        .font(.system(size: 38, weight: .heavy, design: .rounded))
                        .foregroundColor(amountColor)
                }
                
                // Title
                Text(transaction.title ?? (isIncome ? "Income" : "Expense"))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(theme.colors.textColor)
                    .multilineTextAlignment(.center)
                
                // Badge
                HStack(spacing: 6) {
                    Text(isIncome ? "INCOME" : "EXPENSE")
                        .font(.system(size: 11, weight: .bold))
                    
                    if transaction.isRecurring {
                        Text("• RECURRING")
                            .font(.system(size: 11, weight: .bold))
                    }
                }
                .foregroundColor(amountColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(amountColor.opacity(0.12))
                .clipShape(Capsule())
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
    }
    
    // MARK: - Metadata Details Card
    
    private var metadataDetailsCard: some View {
        CardContainer {
            VStack(spacing: 14) {
                detailRow(icon: "folder.fill", title: "Category", value: transaction.category ?? "Uncategorized")
                
                if let merchant = transaction.merchant, !merchant.isEmpty {
                    Divider()
                    detailRow(icon: "building.2.fill", title: "Merchant", value: merchant)
                }
                
                Divider()
                detailRow(icon: "calendar", title: "Date & Time", value: formattedDateTime(transaction.date ?? Date()))
                
                if let method = transaction.paymentMethod, !method.isEmpty {
                    Divider()
                    detailRow(icon: "creditcard.fill", title: "Payment Method", value: method)
                }
                
                if let acc = accountName {
                    Divider()
                    detailRow(icon: "banknote.fill", title: "Account", value: acc)
                }
                
                if transaction.isRecurring, let rule = transaction.recurringRule {
                    Divider()
                    detailRow(icon: "repeat", title: "Frequency", value: rule)
                }
                
                if let note = transaction.note, !note.isEmpty {
                    Divider()
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            Image(systemName: "note.text")
                                .foregroundColor(theme.colors.secondaryTextColor)
                                .font(.system(size: 14))
                            
                            Text("Note")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(theme.colors.secondaryTextColor)
                        }
                        
                        Text(note)
                            .font(.system(size: 14))
                            .foregroundColor(theme.colors.textColor)
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(theme.colors.elevatedCardColor)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                }
            }
        }
    }
    
    private func detailRow(icon: String, title: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(theme.colors.secondaryTextColor)
                .font(.system(size: 14))
                .frame(width: 22)
            
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(theme.colors.secondaryTextColor)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(theme.colors.textColor)
        }
    }
    
    // MARK: - Receipt Preview Card
    
    private func receiptPreviewCard(path: String) -> some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "doc.viewfinder.fill")
                        .foregroundColor(theme.colors.primaryColor)
                    
                    Text("Receipt Attachment")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(theme.colors.textColor)
                    
                    Spacer()
                    
                    Text("Tap to expand")
                        .font(.system(size: 12))
                        .foregroundColor(theme.colors.secondaryTextColor)
                }
                
                if let img = receiptImage {
                    Button(action: { showFullReceipt = true }) {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 180)
                            .frame(maxWidth: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(theme.colors.separatorColor.opacity(0.4), lineWidth: 0.75)
                            )
                    }
                } else {
                    ProgressView()
                        .frame(height: 100)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }
    
    // MARK: - Action Buttons Section
    
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            Button(action: { showEditSheet = true }) {
                HStack {
                    Image(systemName: "pencil")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Edit Transaction")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundColor(theme.colors.textColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(theme.colors.elevatedCardColor)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(theme.colors.separatorColor.opacity(0.4), lineWidth: 0.75)
                )
            }
            .buttonStyle(ScaleButtonStyle())
            
            Button(role: .destructive, action: { showDeleteAlert = true }) {
                HStack {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Delete Transaction")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundColor(theme.colors.dangerColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(theme.colors.dangerColor.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(.top, 4)
    }
    
    // MARK: - Helpers
    
    private func loadDetails() {
        if let accId = transaction.accountId {
            let accounts = AccountManager.shared.getAllAccounts()
            accountName = accounts.first(where: { $0.id == accId })?.name
        }
        
        if let path = transaction.receiptImagePath, !path.isEmpty {
            DispatchQueue.global(qos: .userInitiated).async {
                let img = ReceiptScannerManager.shared.loadThumbnail(from: path, maxDimension: 600)
                DispatchQueue.main.async {
                    self.receiptImage = img
                }
            }
        }
    }
    
    private func formattedDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
