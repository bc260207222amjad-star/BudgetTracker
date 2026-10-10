//
//  CategoryModel.swift
//  BudgetTracker
//
//  Created by ali on 10/10/2026.
//

import UIKit

public struct CategoryItem: Codable, Hashable {
    public let id: String
    public let name: String
    public let iconName: String
    public let colorHex: String
    public let isIncome: Bool
    public let isCustom: Bool
    
    public init(id: String = UUID().uuidString, name: String, iconName: String, colorHex: String, isIncome: Bool = false, isCustom: Bool = false) {
        self.id = id
        self.name = name
        self.iconName = iconName
        self.colorHex = colorHex
        self.isIncome = isIncome
        self.isCustom = isCustom
    }
    
    public var color: UIColor {
        return UIColor(hex: colorHex) ?? .systemBlue
    }
}

public class CategoryManager {
    public static let shared = CategoryManager()
    
    private let customCategoriesKey = "BudgetTracker_CustomCategories"
    
    public static let defaultExpenseCategories: [CategoryItem] = [
        CategoryItem(name: "Food", iconName: "fork.knife", colorHex: "#FF9500"),
        CategoryItem(name: "Transport", iconName: "car.fill", colorHex: "#007AFF"),
        CategoryItem(name: "Shopping", iconName: "bag.fill", colorHex: "#AF52DE"),
        CategoryItem(name: "Bills", iconName: "doc.text.fill", colorHex: "#FF3B30"),
        CategoryItem(name: "Entertainment", iconName: "tv.fill", colorHex: "#5856D6"),
        CategoryItem(name: "Health", iconName: "cross.case.fill", colorHex: "#34C759"),
        CategoryItem(name: "Education", iconName: "book.fill", colorHex: "#5AC8FA"),
        CategoryItem(name: "Rent", iconName: "house.fill", colorHex: "#FF2D55"),
        CategoryItem(name: "Travel", iconName: "airplane", colorHex: "#30B0C7"),
        CategoryItem(name: "Other", iconName: "ellipsis.circle.fill", colorHex: "#8E8E93")
    ]
    
    public static let defaultIncomeCategories: [CategoryItem] = [
        CategoryItem(name: "Salary", iconName: "dollarsign.circle.fill", colorHex: "#34C759", isIncome: true),
        CategoryItem(name: "Freelance", iconName: "laptopcomputer", colorHex: "#007AFF", isIncome: true),
        CategoryItem(name: "Business", iconName: "briefcase.fill", colorHex: "#5856D6", isIncome: true),
        CategoryItem(name: "Investment", iconName: "chart.line.uptrend.xyaxis", colorHex: "#32D74B", isIncome: true),
        CategoryItem(name: "Gift", iconName: "gift.fill", colorHex: "#FF2D55", isIncome: true),
        CategoryItem(name: "Other", iconName: "ellipsis.circle.fill", colorHex: "#8E8E93", isIncome: true)
    ]
    
    private init() {}
    
    public func getExpenseCategories() -> [CategoryItem] {
        let custom = loadCustomCategories().filter { !$0.isIncome }
        return Self.defaultExpenseCategories + custom
    }
    
    public func getIncomeCategories() -> [CategoryItem] {
        let custom = loadCustomCategories().filter { $0.isIncome }
        return Self.defaultIncomeCategories + custom
    }
    
    public func allCategories() -> [CategoryItem] {
        return getExpenseCategories() + getIncomeCategories()
    }
    
    public func category(named name: String) -> CategoryItem {
        if let found = allCategories().first(where: { $0.name.lowercased() == name.lowercased() }) {
            return found
        }
        return CategoryItem(name: name, iconName: "tag.fill", colorHex: "#8E8E93")
    }
    
    public func addCustomCategory(_ category: CategoryItem) {
        var current = loadCustomCategories()
        current.append(category)
        saveCustomCategories(current)
        NotificationCenter.default.post(name: .categoriesDidChange, object: nil)
    }
    
    public func deleteCustomCategory(id: String) {
        var current = loadCustomCategories()
        current.removeAll(where: { $0.id == id })
        saveCustomCategories(current)
        NotificationCenter.default.post(name: .categoriesDidChange, object: nil)
    }
    
    private func loadCustomCategories() -> [CategoryItem] {
        guard let data = UserDefaults.standard.data(forKey: customCategoriesKey),
              let list = try? JSONDecoder().decode([CategoryItem].self, from: data) else {
            return []
        }
        return list
    }
    
    private func saveCustomCategories(_ list: [CategoryItem]) {
        if let data = try? JSONEncoder().encode(list) {
            UserDefaults.standard.set(data, forKey: customCategoriesKey)
        }
    }
}

extension Notification.Name {
    public static let categoriesDidChange = Notification.Name("BudgetTracker_CategoriesDidChange")
}
