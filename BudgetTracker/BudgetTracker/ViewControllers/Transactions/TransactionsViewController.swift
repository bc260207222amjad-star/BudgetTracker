//
//  TransactionsViewController.swift
//  BudgetTracker
//
//  Created by ali on 10/10/2026.
//

import UIKit

public class TransactionsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchResultsUpdating {
    
    private let summaryBannerCard = CardView()
    private let incomeSummaryLabel = UILabel()
    private let expenseSummaryLabel = UILabel()
    private let netSummaryLabel = UILabel()
    
    private let segmentedControl = UISegmentedControl(items: ["All", "Income", "Expenses"])
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let searchController = UISearchController(searchResultsController: nil)
    private let emptyView = EmptyStateView(
        symbolName: "list.bullet.rectangle.portrait",
        title: "No transactions yet",
        subtitle: "Add your first expense or income to track your spending.",
        buttonTitle: "+ Add Expense"
    )
    
    private var groups: [TransactionGroup] = []
    private var currentFilterType: TransactionType? = nil
    private var selectedCategory: String? = nil
    private var selectedPaymentMethod: String? = nil
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigation()
        setupUI()
        setupObservers()
        reloadTransactions()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        applyTheme()
        reloadTransactions()
    }
    
    private func setupNavigation() {
        title = "Transactions"
        navigationController?.navigationBar.prefersLargeTitles = true
        
        let addBtn = UIBarButtonItem(image: UIImage(systemName: "plus"), style: .plain, target: self, action: #selector(addTapped))
        let calendarBtn = UIBarButtonItem(image: UIImage(systemName: "calendar"), style: .plain, target: self, action: #selector(calendarTapped))
        let filterBtn = UIBarButtonItem(image: UIImage(systemName: "line.3.horizontal.decrease.circle"), style: .plain, target: self, action: #selector(filterTapped))
        
        navigationItem.rightBarButtonItems = [addBtn, calendarBtn, filterBtn]
        
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search merchant, title, note, amount..."
        navigationItem.searchController = searchController
        definesPresentationContext = true
    }
    
    private func setupUI() {
        view.backgroundColor = ThemeManager.shared.colors.background
        
        // 1. Summary Banner Card
        summaryBannerCard.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(summaryBannerCard)
        
        let bannerRow = UIStackView()
        bannerRow.axis = .horizontal
        bannerRow.distribution = .fillEqually
        bannerRow.alignment = .center
        bannerRow.spacing = 8
        bannerRow.translatesAutoresizingMaskIntoConstraints = false
        summaryBannerCard.addSubview(bannerRow)
        
        bannerRow.addArrangedSubview(createBannerPill(title: "INCOME", label: incomeSummaryLabel, color: .systemGreen))
        bannerRow.addArrangedSubview(createBannerPill(title: "EXPENSES", label: expenseSummaryLabel, color: .systemRed))
        bannerRow.addArrangedSubview(createBannerPill(title: "NET", label: netSummaryLabel, color: .systemBlue))
        
        // 2. Segmented Filter
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(segmentedControl)
        
        // 3. TableView
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(TransactionCell.self, forCellReuseIdentifier: TransactionCell.reuseIdentifier)
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .singleLine
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        
        // 4. Empty View
        emptyView.translatesAutoresizingMaskIntoConstraints = false
        emptyView.isHidden = true
        emptyView.onActionTapped = { [weak self] in
            self?.addTapped()
        }
        view.addSubview(emptyView)
        
        NSLayoutConstraint.activate([
            summaryBannerCard.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 6),
            summaryBannerCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            summaryBannerCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            bannerRow.topAnchor.constraint(equalTo: summaryBannerCard.topAnchor, constant: 12),
            bannerRow.leadingAnchor.constraint(equalTo: summaryBannerCard.leadingAnchor, constant: 14),
            bannerRow.trailingAnchor.constraint(equalTo: summaryBannerCard.trailingAnchor, constant: -14),
            bannerRow.bottomAnchor.constraint(equalTo: summaryBannerCard.bottomAnchor, constant: -12),
            
            segmentedControl.topAnchor.constraint(equalTo: summaryBannerCard.bottomAnchor, constant: 12),
            segmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            segmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            tableView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            emptyView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 32),
            emptyView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -32)
        ])
    }
    
    private func createBannerPill(title: String, label: UILabel, color: UIColor) -> UIView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 3
        
        let tLabel = UILabel()
        tLabel.text = title
        tLabel.font = .systemFont(ofSize: 10, weight: .heavy)
        tLabel.textColor = .secondaryLabel
        stack.addArrangedSubview(tLabel)
        
        label.font = .monospacedDigitSystemFont(ofSize: 15, weight: .bold)
        label.textColor = color
        label.textAlignment = .center
        stack.addArrangedSubview(label)
        
        return stack
    }
    
    private func setupObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(reloadTransactions), name: .transactionsDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadTransactions), name: .currencyDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applyTheme), name: .themeDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadTransactions), name: .privacyDisplayDidChange, object: nil)
    }
    
    @objc private func applyTheme() {
        view.backgroundColor = ThemeManager.shared.colors.background
        summaryBannerCard.applyTheme()
        tableView.reloadData()
    }
    
    @objc private func segmentChanged() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        switch segmentedControl.selectedSegmentIndex {
        case 1: currentFilterType = .income
        case 2: currentFilterType = .expense
        default: currentFilterType = nil
        }
        reloadTransactions()
    }
    
    @objc public func reloadTransactions() {
        let query = searchController.searchBar.text
        let fetched = TransactionManager.shared.fetchTransactions(
            type: currentFilterType,
            category: selectedCategory,
            searchQuery: query,
            paymentMethod: selectedPaymentMethod
        )
        
        let currency = CurrencyManager.shared
        let totalInc = fetched.filter { $0.type == TransactionType.income.rawValue }.reduce(0) { $0 + $1.amount }
        let totalExp = fetched.filter { $0.type == TransactionType.expense.rawValue }.reduce(0) { $0 + $1.amount }
        let net = totalInc - totalExp
        
        if BiometricAuthManager.shared.hideBalance {
            incomeSummaryLabel.text = "••••"
            expenseSummaryLabel.text = "••••"
            netSummaryLabel.text = "••••"
        } else {
            incomeSummaryLabel.text = "+\(currency.format(totalInc))"
            expenseSummaryLabel.text = "-\(currency.format(totalExp))"
            netSummaryLabel.text = "\(net >= 0 ? "+" : "")\(currency.format(net))"
            netSummaryLabel.textColor = net >= 0 ? .systemBlue : .systemRed
        }
        
        groups = TransactionManager.shared.groupTransactionsByDate(fetched)
        emptyView.isHidden = !groups.isEmpty
        tableView.isHidden = groups.isEmpty
        tableView.reloadData()
    }
    
    // MARK: - UISearchResultsUpdating
    
    public func updateSearchResults(for searchController: UISearchController) {
        reloadTransactions()
    }
    
    // MARK: - TableView
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        return groups.count
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return groups[section].transactions.count
    }
    
    public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let g = groups[section]
        let currency = CurrencyManager.shared
        if BiometricAuthManager.shared.hideTransactionAmounts {
            return g.title
        } else {
            let exp = g.totalExpense
            let inc = g.totalIncome
            var parts: [String] = []
            if exp > 0 { parts.append("Spent -\(currency.format(exp))") }
            if inc > 0 { parts.append("Income +\(currency.format(inc))") }
            let badge = parts.isEmpty ? "" : " (\(parts.joined(separator: ", ")))"
            return "\(g.title)\(badge)"
        }
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: TransactionCell.reuseIdentifier, for: indexPath) as? TransactionCell else {
            return UITableViewCell()
        }
        let item = groups[indexPath.section].transactions[indexPath.row]
        cell.configure(with: item)
        return cell
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = groups[indexPath.section].transactions[indexPath.row]
        let detailVC = TransactionDetailViewController(transaction: item)
        navigationController?.pushViewController(detailVC, animated: true)
    }
    
    public func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let item = groups[indexPath.section].transactions[indexPath.row]
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completion in
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            let alert = UIAlertController(title: "Delete Transaction", message: "Are you sure you want to delete this transaction?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
                TransactionManager.shared.deleteTransaction(item)
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
    
    // MARK: - Actions
    
    @objc private func addTapped() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        let sheet = UIAlertController(title: "Add Transaction", message: "Choose transaction type:", preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "Add Expense", style: .default, handler: { [weak self] _ in
            let vc = AddExpenseViewController()
            let nav = UINavigationController(rootViewController: vc)
            self?.present(nav, animated: true)
        }))
        sheet.addAction(UIAlertAction(title: "Add Income", style: .default, handler: { [weak self] _ in
            let vc = AddIncomeViewController()
            let nav = UINavigationController(rootViewController: vc)
            self?.present(nav, animated: true)
        }))
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(sheet, animated: true)
    }
    
    @objc private func calendarTapped() {
        let calVC = CalendarViewController()
        navigationController?.pushViewController(calVC, animated: true)
    }
    
    @objc private func filterTapped() {
        let sheet = UIAlertController(title: "Filter by Category", message: "Select category to view:", preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "All Categories", style: .default, handler: { [weak self] _ in
            self?.selectedCategory = nil
            self?.reloadTransactions()
        }))
        for cat in CategoryManager.shared.allCategories() {
            sheet.addAction(UIAlertAction(title: cat.name, style: .default, handler: { [weak self] _ in
                self?.selectedCategory = cat.name
                self?.reloadTransactions()
            }))
        }
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(sheet, animated: true)
    }
}
