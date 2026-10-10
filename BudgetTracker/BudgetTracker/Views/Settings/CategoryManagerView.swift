//
//  CategoryManagerView.swift
//  BudgetTracker
//
//  Created by ali on 10/10/2026.
//

import SwiftUI

public struct CategoryManagerView: View {
    @ObservedObject private var theme = ThemeManager.shared
    
    @State private var selectedTab = 0 // 0: Expenses, 1: Income
    @State private var expenseCategories: [CategoryItem] = []
    @State private var incomeCategories: [CategoryItem] = []
    @State private var showAddCategory = false
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 12) {
            Picker("Type", selection: $selectedTab) {
                Text("Expenses").tag(0)
                Text("Income").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.top, 8)
            
            List {
                let currentList = selectedTab == 0 ? expenseCategories : incomeCategories
                ForEach(currentList, id: \.id) { cat in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(cat.color.opacity(0.16))
                            .frame(width: 40, height: 40)
                            .overlay(
                                Image(systemName: cat.iconName)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(cat.color)
                            )
                        
                        Text(cat.name)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(theme.colors.textColor)
                        
                        Spacer()
                        
                        if cat.isCustom {
                            Text("CUSTOM")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(theme.colors.primaryColor)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(theme.colors.primaryColor.opacity(0.12))
                                .clipShape(Capsule())
                        }
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        if cat.isCustom {
                            Button(role: .destructive) {
                                CategoryManager.shared.deleteCustomCategory(id: cat.id)
                                loadCategories()
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
        }
        .background(theme.colors.backgroundColor.ignoresSafeArea())
        .navigationTitle("Categories")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showAddCategory = true }) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .bold))
                }
            }
        }
        .sheet(isPresented: $showAddCategory) {
            AddCategorySheet(isIncome: selectedTab == 1, onDismiss: { loadCategories() })
        }
        .onAppear {
            loadCategories()
        }
    }
    
    private func loadCategories() {
        expenseCategories = CategoryManager.shared.getExpenseCategories()
        incomeCategories = CategoryManager.shared.getIncomeCategories()
    }
}

// MARK: - Add Category Sheet

public struct AddCategorySheet: View {
    public var isIncome: Bool
    public var onDismiss: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var theme = ThemeManager.shared
    
    @State private var name: String = ""
    @State private var selectedIcon: String = "cart.fill"
    @State private var selectedColorHex: String = "#007AFF"
    @State private var isIncomeType: Bool = false
    
    private let availableIcons = [
        "cart.fill", "fuelpump.fill", "cup.and.saucer.fill", "gamecontroller.fill",
        "film.fill", "cross.case.fill", "graduationcap.fill", "airplane",
        "pawprint.fill", "music.note", "wrench.and.screwdriver.fill", "gift.fill",
        "book.fill", "tshirt.fill", "shippingbox.fill", "star.fill"
    ]
    
    private let availableColors = [
        "#007AFF", "#34C759", "#FF9500", "#FF2D55", "#AF52DE",
        "#5856D6", "#FF3B30", "#5AC8FA", "#30B0C7", "#8E8E93"
    ]
    
    public init(isIncome: Bool = false, onDismiss: @escaping () -> Void = {}) {
        self.isIncome = isIncome
        self.onDismiss = onDismiss
        _isIncomeType = State(initialValue: isIncome)
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Preview Card
                    CardContainer {
                        HStack(spacing: 14) {
                            Circle()
                                .fill(Color(UIColor(hex: selectedColorHex) ?? .systemBlue).opacity(0.16))
                                .frame(width: 52, height: 52)
                                .overlay(
                                    Image(systemName: selectedIcon)
                                        .font(.system(size: 22, weight: .bold))
                                        .foregroundColor(Color(UIColor(hex: selectedColorHex) ?? .systemBlue))
                                )
                            
                            VStack(alignment: .leading, spacing: 3) {
                                Text(name.isEmpty ? "Category Name" : name)
                                    .font(.system(size: 17, weight: .bold))
                                    .foregroundColor(theme.colors.textColor)
                                
                                Text(isIncomeType ? "Income Category" : "Expense Category")
                                    .font(.system(size: 12))
                                    .foregroundColor(theme.colors.secondaryTextColor)
                            }
                            
                            Spacer()
                        }
                    }
                    
                    // Name input
                    CardContainer {
                        VStack(spacing: 12) {
                            TextField("Category Name", text: $name)
                                .font(.system(size: 15))
                            
                            Divider()
                            
                            Toggle("Income Category", isOn: $isIncomeType)
                                .font(.system(size: 15))
                        }
                    }
                    
                    // Icon Picker
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Select Icon")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(theme.colors.secondaryTextColor)
                            .textCase(.uppercase)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                            ForEach(availableIcons, id: \.self) { icon in
                                Button(action: {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    selectedIcon = icon
                                }) {
                                    Circle()
                                        .fill(selectedIcon == icon ? theme.colors.primaryColor : theme.colors.cardColor)
                                        .frame(height: 50)
                                        .overlay(
                                            Image(systemName: icon)
                                                .font(.system(size: 20))
                                                .foregroundColor(selectedIcon == icon ? .white : theme.colors.textColor)
                                        )
                                }
                            }
                        }
                    }
                    
                    // Color Picker
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Select Color")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(theme.colors.secondaryTextColor)
                            .textCase(.uppercase)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                            ForEach(availableColors, id: \.self) { hex in
                                Button(action: {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    selectedColorHex = hex
                                }) {
                                    Circle()
                                        .fill(Color(UIColor(hex: hex) ?? .systemBlue))
                                        .frame(height: 44)
                                        .overlay(
                                            selectedColorHex == hex ?
                                            Image(systemName: "checkmark")
                                                .foregroundColor(.white)
                                                .font(.system(size: 14, weight: .bold)) : nil
                                        )
                                }
                            }
                        }
                    }
                    
                    // Save Button
                    Button(action: { saveCategory() }) {
                        Text("Save Category")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(theme.colors.primaryColor)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding(16)
            }
            .background(theme.colors.backgroundColor.ignoresSafeArea())
            .navigationTitle("New Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
    
    private func saveCategory() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        let newCat = CategoryItem(
            name: trimmed,
            iconName: selectedIcon,
            colorHex: selectedColorHex,
            isIncome: isIncomeType,
            isCustom: true
        )
        CategoryManager.shared.addCustomCategory(newCat)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        onDismiss()
        dismiss()
    }
}
