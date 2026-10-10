//
//  AddBudgetView.swift
//  BudgetTracker
//
//  Created by ali on 10/10/2026.
//

import SwiftUI

public struct AddBudgetView: View {
    public var budgetToEdit: BudgetEntity?
    public var onDismiss: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var theme = ThemeManager.shared
    @ObservedObject private var currency = CurrencyManager.shared
    
    @State private var name: String = ""
    @State private var isOverallBudget: Bool = false
    @State private var selectedCategory: String = "Food"
    @State private var limitString: String = ""
    @State private var selectedMonth: Date = Date()
    @State private var alert50: Bool = true
    @State private var alert75: Bool = true
    @State private var alert90: Bool = true
    @State private var validationError: String?
    
    private let presetLimits: [Double] = [200, 500, 1000, 2000, 3500]
    
    public init(budgetToEdit: BudgetEntity? = nil, onDismiss: @escaping () -> Void = {}) {
        self.budgetToEdit = budgetToEdit
        self.onDismiss = onDismiss
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 1. Limit Hero Card
                    limitHeroSection
                    
                    // 2. Budget Type & Category
                    typeAndCategorySection
                    
                    // 3. Month & Threshold Alerts
                    settingsSection
                    
                    // 4. Save Button
                    saveButtonSection
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(theme.colors.backgroundColor.ignoresSafeArea())
            .navigationTitle(budgetToEdit != nil ? "Edit Budget" : "New Budget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveBudget()
                    }
                    .fontWeight(.bold)
                }
            }
            .onAppear {
                loadInitialData()
            }
        }
    }
    
    // MARK: - Limit Hero Card
    
    private var limitHeroSection: some View {
        CardContainer {
            VStack(spacing: 14) {
                Text("BUDGET LIMIT")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(theme.colors.secondaryTextColor)
                    .tracking(1)
                
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(currency.currentCurrency.symbol)
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundColor(theme.colors.primaryColor)
                    
                    TextField("0.00", text: $limitString)
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
                
                // Presets
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(presetLimits, id: \.self) { preset in
                            Button(action: {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                limitString = String(format: "%.0f", preset)
                                validationError = nil
                            }) {
                                Text("\(currency.currentCurrency.symbol)\(Int(preset))")
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
    
    // MARK: - Type & Category Section
    
    private var typeAndCategorySection: some View {
        CardContainer {
            VStack(spacing: 14) {
                // Name
                HStack {
                    Image(systemName: "pencil")
                        .foregroundColor(theme.colors.secondaryTextColor)
                        .frame(width: 24)
                    
                    TextField("Budget Name (e.g. Food & Dining)", text: $name)
                        .font(.system(size: 15))
                }
                
                Divider()
                
                // Budget Scope
                HStack {
                    Image(systemName: "scope")
                        .foregroundColor(theme.colors.secondaryTextColor)
                        .frame(width: 24)
                    
                    Text("Budget Scope")
                        .font(.system(size: 15))
                        .foregroundColor(theme.colors.textColor)
                    
                    Spacer()
                    
                    Picker("Scope", selection: $isOverallBudget) {
                        Text("Category").tag(false)
                        Text("Overall Monthly").tag(true)
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 180)
                }
                
                if !isOverallBudget {
                    Divider()
                    
                    HStack {
                        Image(systemName: "folder.fill")
                            .foregroundColor(theme.colors.secondaryTextColor)
                            .frame(width: 24)
                        
                        Text("Category")
                            .font(.system(size: 15))
                            .foregroundColor(theme.colors.textColor)
                        
                        Spacer()
                        
                        Picker("Category", selection: $selectedCategory) {
                            ForEach(CategoryManager.shared.expenseCategories, id: \.name) { cat in
                                Text(cat.name).tag(cat.name)
                            }
                        }
                        .pickerStyle(.menu)
                        .onChange(of: selectedCategory) { newCat in
                            if name.isEmpty || name.contains("Budget") {
                                name = "\(newCat) Budget"
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Settings Section
    
    private var settingsSection: some View {
        CardContainer {
            VStack(spacing: 14) {
                // Month
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(theme.colors.secondaryTextColor)
                        .frame(width: 24)
                    
                    Text("Target Month")
                        .font(.system(size: 15))
                        .foregroundColor(theme.colors.textColor)
                    
                    Spacer()
                    
                    DatePicker("", selection: $selectedMonth, displayedComponents: [.date])
                        .labelsHidden()
                }
                
                Divider()
                
                // Threshold Alerts
                VStack(alignment: .leading, spacing: 10) {
                    Text("SMART THRESHOLD ALERTS")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(theme.colors.secondaryTextColor)
                        .tracking(0.5)
                    
                    Toggle(isOn: $alert50) {
                        Label("Alert at 50% spent", systemImage: "bell")
                            .font(.system(size: 14))
                    }
                    
                    Toggle(isOn: $alert75) {
                        Label("Alert at 75% spent", systemImage: "bell.badge")
                            .font(.system(size: 14))
                    }
                    
                    Toggle(isOn: $alert90) {
                        Label("Alert at 90% spent (Critical)", systemImage: "exclamationmark.triangle")
                            .font(.system(size: 14))
                    }
                }
            }
        }
    }
    
    // MARK: - Save Button Section
    
    private var saveButtonSection: some View {
        Button(action: {
            saveBudget()
        }) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 18, weight: .bold))
                
                Text(budgetToEdit != nil ? "Update Budget" : "Save Budget")
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
        .padding(.top, 6)
    }
    
    // MARK: - Logic
    
    private func loadInitialData() {
        if let editing = budgetToEdit {
            name = editing.name ?? ""
            limitString = String(format: "%.0f", editing.limit)
            isOverallBudget = editing.category == nil
            selectedCategory = editing.category ?? "Food"
            selectedMonth = editing.month ?? Date()
            alert50 = editing.alert50Enabled
            alert75 = editing.alert75Enabled
            alert90 = editing.alert90Enabled
        } else {
            name = "\(selectedCategory) Budget"
        }
    }
    
    private func saveBudget() {
        guard let limit = Double(limitString), limit > 0 else {
            validationError = "Please enter a valid budget limit greater than 0"
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            return
        }
        
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalName = trimmedName.isEmpty ? (isOverallBudget ? "Overall Monthly Budget" : "\(selectedCategory) Budget") : trimmedName
        let categoryValue: String? = isOverallBudget ? nil : selectedCategory
        
        if let editing = budgetToEdit {
            editing.name = finalName
            editing.limit = limit
            editing.category = categoryValue
            editing.month = selectedMonth
            editing.alert50Enabled = alert50
            editing.alert75Enabled = alert75
            editing.alert90Enabled = alert90
            CoreDataManager.shared.saveContext()
        } else {
            _ = BudgetManager.shared.createBudget(
                name: finalName,
                category: categoryValue,
                limit: limit,
                month: selectedMonth,
                alert50: alert50,
                alert75: alert75,
                alert90: alert90
            )
        }
        
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        onDismiss()
        dismiss()
    }
}
