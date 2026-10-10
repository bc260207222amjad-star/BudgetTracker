//
//  BudgetsViewController.swift
//  BudgetTracker
//
//  Created by ali on 10/10/2026.
//

import UIKit

public class BudgetsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let emptyView = EmptyStateView(
        symbolName: "chart.bar.xaxis",
        title: "No budgets created",
        subtitle: "Create a budget to control your monthly spending and receive timely alerts.",
        buttonTitle: "+ Create Budget"
    )
    
    private var budgetStatuses: [BudgetStatus] = []
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigation()
        setupUI()
        setupObservers()
        reloadBudgets()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        applyTheme()
        reloadBudgets()
    }
    
    private func setupNavigation() {
        title = "Budgets"
        navigationController?.navigationBar.prefersLargeTitles = true
        
        let addBtn = UIBarButtonItem(image: UIImage(systemName: "plus"), style: .plain, target: self, action: #selector(createBudgetTapped))
        navigationItem.rightBarButtonItem = addBtn
    }
    
    private func setupUI() {
        view.backgroundColor = ThemeManager.shared.colors.background
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(BudgetCell.self, forCellReuseIdentifier: BudgetCell.reuseIdentifier)
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        
        emptyView.translatesAutoresizingMaskIntoConstraints = false
        emptyView.isHidden = true
        emptyView.onActionTapped = { [weak self] in
            self?.createBudgetTapped()
        }
        view.addSubview(emptyView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            emptyView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 32),
            emptyView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -32)
        ])
    }
    
    private func setupObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(reloadBudgets), name: .budgetsDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadBudgets), name: .transactionsDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadBudgets), name: .currencyDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applyTheme), name: .themeDidChange, object: nil)
    }
    
    @objc private func applyTheme() {
        view.backgroundColor = ThemeManager.shared.colors.background
        tableView.reloadData()
    }
    
    @objc public func reloadBudgets() {
        budgetStatuses = BudgetManager.shared.getBudgetStatuses()
        emptyView.isHidden = !budgetStatuses.isEmpty
        tableView.isHidden = budgetStatuses.isEmpty
        tableView.reloadData()
    }
    
    // MARK: - TableView
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return budgetStatuses.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: BudgetCell.reuseIdentifier, for: indexPath) as? BudgetCell else {
            return UITableViewCell()
        }
        let status = budgetStatuses[indexPath.row]
        cell.configure(with: status)
        return cell
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let status = budgetStatuses[indexPath.row]
        let editVC = AddBudgetViewController()
        editVC.budgetToEdit = status.budget
        let nav = UINavigationController(rootViewController: editVC)
        present(nav, animated: true)
    }
    
    public func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let status = budgetStatuses[indexPath.row]
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completion in
            let alert = UIAlertController(title: "Delete Budget", message: "Are you sure you want to delete '\(status.budget.name ?? "Budget")'?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
                BudgetManager.shared.deleteBudget(status.budget)
                completion(true)
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
                completion(false)
            }))
            self?.present(alert, animated: true)
        }
        deleteAction.image = UIImage(systemName: "trash")
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
    
    @objc private func createBudgetTapped() {
        let vc = AddBudgetViewController()
        let nav = UINavigationController(rootViewController: vc)
        present(nav, animated: true)
    }
}
