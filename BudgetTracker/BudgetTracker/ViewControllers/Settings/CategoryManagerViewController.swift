//
//  CategoryManagerViewController.swift
//  BudgetTracker
//
//  Created by ali on 10/10/2026.
//

import UIKit

public class CategoryManagerViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var expenseCategories: [CategoryItem] = []
    private var incomeCategories: [CategoryItem] = []
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigation()
        setupUI()
        reloadCategories()
    }
    
    private func setupNavigation() {
        title = "Categories"
        navigationItem.largeTitleDisplayMode = .never
        let addBtn = UIBarButtonItem(image: UIImage(systemName: "plus"), style: .plain, target: self, action: #selector(addCategoryTapped))
        navigationItem.rightBarButtonItem = addBtn
    }
    
    private func setupUI() {
        view.backgroundColor = ThemeManager.shared.colors.background
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = .clear
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func reloadCategories() {
        expenseCategories = CategoryManager.shared.getExpenseCategories()
        incomeCategories = CategoryManager.shared.getIncomeCategories()
        tableView.reloadData()
    }
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 0 ? "Expense Categories" : "Income Categories"
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? expenseCategories.count : incomeCategories.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: "CategoryCell")
        cell.backgroundColor = ThemeManager.shared.colors.card
        let item = indexPath.section == 0 ? expenseCategories[indexPath.row] : incomeCategories[indexPath.row]
        
        cell.textLabel?.text = item.name
        cell.textLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        
        cell.imageView?.image = UIImage(systemName: item.iconName)
        cell.imageView?.tintColor = item.color
        
        if item.isCustom {
            cell.detailTextLabel?.text = "Custom"
            cell.detailTextLabel?.font = .systemFont(ofSize: 12)
            cell.detailTextLabel?.textColor = .secondaryLabel
        } else {
            cell.detailTextLabel?.text = ""
        }
        
        return cell
    }
    
    public func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let item = indexPath.section == 0 ? expenseCategories[indexPath.row] : incomeCategories[indexPath.row]
        guard item.isCustom else { return nil }
        
        let delete = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completion in
            CategoryManager.shared.deleteCustomCategory(id: item.id)
            self?.reloadCategories()
            completion(true)
        }
        return UISwipeActionsConfiguration(actions: [delete])
    }
    
    @objc private func addCategoryTapped() {
        let alert = UIAlertController(title: "New Category", message: "Enter custom category name:", preferredStyle: .alert)
        alert.addTextField { tf in tf.placeholder = "Category Name (e.g. Subscriptions)" }
        
        alert.addAction(UIAlertAction(title: "Add as Expense", style: .default, handler: { [weak self] _ in
            guard let name = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty else { return }
            let item = CategoryItem(name: name, iconName: "tag.fill", colorHex: "#AF52DE", isIncome: false, isCustom: true)
            CategoryManager.shared.addCustomCategory(item)
            self?.reloadCategories()
        }))
        
        alert.addAction(UIAlertAction(title: "Add as Income", style: .default, handler: { [weak self] _ in
            guard let name = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty else { return }
            let item = CategoryItem(name: name, iconName: "dollarsign.circle.fill", colorHex: "#34C759", isIncome: true, isCustom: true)
            CategoryManager.shared.addCustomCategory(item)
            self?.reloadCategories()
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
}
