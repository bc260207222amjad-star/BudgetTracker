//
//  AddExpenseView.swift
//  BudgetTracker
//
//  Created by ali on 10/10/2026.
//

import SwiftUI
import PhotosUI

public struct AddExpenseView: View {
    public var transactionToEdit: TransactionEntity?
    public var onDismiss: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var theme = ThemeManager.shared
    @ObservedObject private var currency = CurrencyManager.shared
    
    @State private var amountString: String = ""
    @State private var selectedCategory: String = "Food"
    @State private var title: String = ""
    @State private var merchant: String = ""
    @State private var transactionDate: Date = Date()
    @State private var paymentMethod: String = "Cash"
    @State private var selectedAccountId: UUID?
    @State private var note: String = ""
    
    // Receipt Photo
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var receiptImage: UIImage?
    @State private var receiptImagePath: String?
    @State private var showCameraScanner = false
    @State private var validationError: String?
    
    @State private var accounts: [AccountEntity] = []
    
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
                    
                    // 2. Category Selector Chips
                    categorySection
                    
                    // 3. Details Form Card
                    detailsCardSection
                    
                    // 4. Receipt Attachment Card
                    receiptCardSection
                    
                    // 5. Save Button
                    saveButtonSection
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(theme.colors.backgroundColor.ignoresSafeArea())
            .navigationTitle(transactionToEdit != nil ? "Edit Expense" : "New Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveExpense()
                    }
                    .fontWeight(.bold)
                }
            }
            .alert("Invalid Input", isPresented: .init(get: { validationError != nil }, set: { _ in validationError = nil })) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(validationError ?? "")
            }
            .onAppear {
                setupInitialData()
            }
            .onChange(of: selectedPhotoItem) { newItem in
                handlePhotoSelection(newItem)
            }
        }
    }
    
    // MARK: - Amount Hero Section
    
    private var amountHeroSection: some View {
        CardContainer {
            VStack(spacing: 14) {
                Text("AMOUNT")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(theme.colors.secondaryTextColor)
                    .tracking(0.5)
                
                HStack(alignment: .center, spacing: 4) {
                    Text(currency.currentCurrency.symbol)
                        .font(.system(size: 34, weight: .heavy, design: .rounded))
                        .foregroundColor(theme.colors.dangerColor)
                    
                    TextField("0.00", text: $amountString)
                        .font(.system(size: 42, weight: .heavy, design: .rounded))
                        .foregroundColor(theme.colors.dangerColor)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 240)
                }
                
                // Quick Presets
                HStack(spacing: 8) {
                    ForEach([5.0, 10.0, 25.0, 50.0, 100.0], id: \.self) { preset in
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            let cur = Double(amountString) ?? 0.0
                            amountString = String(format: "%.2f", cur + preset)
                        }) {
                            Text("+\(Int(preset))")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(theme.colors.dangerColor)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(theme.colors.dangerColor.opacity(0.12))
                                .clipShape(Capsule())
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
        }
    }
    
    // MARK: - Category Section
    
    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("CATEGORY")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(theme.colors.secondaryTextColor)
                .padding(.horizontal, 4)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(CategoryManager.shared.expenseCategories, id: \.name) { cat in
                        let isSelected = selectedCategory.lowercased() == cat.name.lowercased()
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            selectedCategory = cat.name
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: cat.iconName)
                                    .font(.system(size: 14, weight: .semibold))
                                Text(cat.name)
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundColor(isSelected ? .white : theme.colors.textColor)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(isSelected ? cat.color : theme.colors.cardColor)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(isSelected ? Color.clear : theme.colors.separatorColor.opacity(0.4), lineWidth: 1)
                            )
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
    
    // MARK: - Details Form Card
    
    private var detailsCardSection: some View {
        CardContainer {
            VStack(spacing: 16) {
                // Title Field
                HStack(spacing: 12) {
                    Image(systemName: "pencil.line")
                        .foregroundColor(.blue)
                        .frame(width: 20)
                    
                    TextField("Title (e.g. Lunch with team)", text: $title)
                        .font(.system(size: 15))
                }
                .padding(12)
                .background(theme.colors.elevatedCardColor)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                
                // Merchant Field
                HStack(spacing: 12) {
                    Image(systemName: "storefront.fill")
                        .foregroundColor(.orange)
                        .frame(width: 20)
                    
                    TextField("Merchant / Store (e.g. Starbucks)", text: $merchant)
                        .font(.system(size: 15))
                }
                .padding(12)
                .background(theme.colors.elevatedCardColor)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                
                // Date & Time Picker
                HStack {
                    Label("Date & Time", systemImage: "calendar")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(theme.colors.textColor)
                    
                    Spacer()
                    
                    DatePicker("", selection: $transactionDate, displayedComponents: [.date, .hourAndMinute])
                        .labelsHidden()
                }
                
                Divider()
                    .background(theme.colors.separatorColor.opacity(0.4))
                
                // Payment Method Menu
                HStack {
                    Label("Payment Method", systemImage: "creditcard")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(theme.colors.textColor)
                    
                    Spacer()
                    
                    Picker("Payment Method", selection: $paymentMethod) {
                        ForEach(["Cash", "Debit Card", "Credit Card", "Bank", "Digital Wallet", "Other"], id: \.self) { method in
                            Text(method).tag(method)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Divider()
                    .background(theme.colors.separatorColor.opacity(0.4))
                
                // Account Menu
                HStack {
                    Label("Account", systemImage: "building.columns")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(theme.colors.textColor)
                    
                    Spacer()
                    
                    Picker("Account", selection: $selectedAccountId) {
                        ForEach(accounts, id: \.id) { acc in
                            Text(acc.name ?? "Account").tag(acc.id as UUID?)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Divider()
                    .background(theme.colors.separatorColor.opacity(0.4))
                
                // Note Field
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "note.text")
                        .foregroundColor(.gray)
                        .frame(width: 20)
                        .padding(.top, 2)
                    
                    TextField("Note (optional)", text: $note, axis: .vertical)
                        .lineLimit(2...4)
                        .font(.system(size: 15))
                }
                .padding(12)
                .background(theme.colors.elevatedCardColor)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
    }
    
    // MARK: - Receipt Attachment Section
    
    private var receiptCardSection: some View {
        CardContainer {
            VStack(spacing: 12) {
                HStack {
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        HStack(spacing: 8) {
                            Image(systemName: "camera.fill")
                            Text(receiptImage != nil ? "Change Receipt Photo" : "Attach Receipt (Photo / OCR)")
                        }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.blue)
                    }
                    
                    Spacer()
                    
                    if receiptImage != nil {
                        Button(action: {
                            receiptImage = nil
                            receiptImagePath = nil
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                    }
                }
                
                if let img = receiptImage {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 160)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
        }
    }
    
    // MARK: - Save Button
    
    private var saveButtonSection: some View {
        Button(action: {
            saveExpense()
        }) {
            Text(transactionToEdit != nil ? "Update Expense" : "Save Expense")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(theme.colors.dangerColor)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: theme.colors.dangerColor.opacity(0.35), radius: 8, x: 0, y: 4)
        }
        .padding(.top, 4)
    }
    
    // MARK: - Helpers
    
    private func setupInitialData() {
        AccountManager.shared.ensureDefaultAccountsExist()
        accounts = AccountManager.shared.fetchAccounts()
        
        if let edit = transactionToEdit {
            amountString = String(format: "%.2f", edit.amount)
            title = edit.title ?? ""
            merchant = edit.merchant ?? ""
            selectedCategory = edit.category ?? "Food"
            transactionDate = edit.date ?? Date()
            paymentMethod = edit.paymentMethod ?? "Cash"
            selectedAccountId = edit.accountId
            note = edit.note ?? ""
            receiptImagePath = edit.receiptImagePath
            if let path = edit.receiptImagePath {
                receiptImage = ReceiptScannerManager.shared.loadThumbnail(from: path, maxDimension: 600)
            }
        } else {
            selectedAccountId = accounts.first?.id
        }
    }
    
    private func handlePhotoSelection(_ item: PhotosPickerItem?) {
        guard let item = item else { return }
        item.loadTransferable(type: Data.self) { result in
            switch result {
            case .success(let data):
                if let d = data, let img = UIImage(data: d) {
                    DispatchQueue.main.async {
                        self.receiptImage = img
                        // Save receipt image to disk
                        if let path = ReceiptScannerManager.shared.saveReceiptImage(img) {
                            self.receiptImagePath = path
                        }
                        // Perform on-device OCR extraction
                        ReceiptScannerManager.shared.scanReceiptImage(img) { ocr in
                            if let total = ocr.amount, self.amountString.isEmpty {
                                self.amountString = String(format: "%.2f", total)
                            }
                            if let m = ocr.merchant, self.merchant.isEmpty {
                                self.merchant = m
                            }
                            if let d = ocr.date {
                                self.transactionDate = d
                            }
                        }
                    }
                }
            case .failure:
                break
            }
        }
    }
    
    private func saveExpense() {
        guard let amount = Double(amountString.replacingOccurrences(of: ",", with: ".")), amount > 0 else {
            validationError = "Please enter a valid expense amount greater than 0."
            return
        }
        
        let finalTitle = title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? selectedCategory : title
        
        if let edit = transactionToEdit {
            TransactionManager.shared.updateTransaction(
                transaction: edit,
                title: finalTitle,
                amount: amount,
                type: .expense,
                category: selectedCategory,
                merchant: merchant.isEmpty ? nil : merchant,
                note: note.isEmpty ? nil : note,
                date: transactionDate,
                paymentMethod: paymentMethod,
                receiptImagePath: receiptImagePath,
                accountId: selectedAccountId
            )
        } else {
            TransactionManager.shared.createTransaction(
                title: finalTitle,
                amount: amount,
                type: .expense,
                category: selectedCategory,
                merchant: merchant.isEmpty ? nil : merchant,
                note: note.isEmpty ? nil : note,
                date: transactionDate,
                paymentMethod: paymentMethod,
                receiptImagePath: receiptImagePath,
                accountId: selectedAccountId
            )
        }
        
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        onDismiss()
        dismiss()
    }
}
