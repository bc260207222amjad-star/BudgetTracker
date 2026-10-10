//
//  DashboardViewController.swift
//  BudgetTracker
//
//  Created by ali on 10/10/2026.
//

import UIKit
import CoreData

public class DashboardViewController: UIViewController {
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let refreshControl = UIRefreshControl()
    
    // Header
    private let greetingLabel = UILabel()
    private let monthLabel = UILabel()
    
    // Hero Balance Card
    private let heroBalanceCard = HeroBalanceCard()
    
    // Quick Actions
    private let quickActionsStack = UIStackView()
    
    // Upcoming Expenses
    private let upcomingCard = CardView()
    private let upcomingStack = UIStackView()
    
    // Budget Overview
    private let budgetCard = CardView()
    private let budgetStack = UIStackView()
    
    // Recent Transactions
    private let recentTransactionsCard = CardView()
    private let recentTransactionsStack = UIStackView()
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigation()
        setupUI()
        setupObservers()
        reloadData()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        applyTheme()
        reloadData()
    }
    
    private func setupNavigation() {
        title = "Dashboard"
        navigationController?.navigationBar.prefersLargeTitles = false
        
        let sampleBtn = UIBarButtonItem(image: UIImage(systemName: "wand.and.stars"), style: .plain, target: self, action: #selector(loadSampleDataTapped))
        navigationItem.rightBarButtonItem = sampleBtn
    }
    
    private func setupObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(reloadData), name: .transactionsDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadData), name: .budgetsDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadData), name: .currencyDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applyTheme), name: .themeDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadData), name: .privacyDisplayDidChange, object: nil)
    }
    
    private func setupUI() {
        view.backgroundColor = ThemeManager.shared.colors.background
        
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        scrollView.refreshControl = refreshControl
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
        
        // 1. Header Greeting
        let headerRow = UIStackView()
        headerRow.axis = .horizontal
        headerRow.alignment = .center
        headerRow.distribution = .equalSpacing
        headerRow.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(headerRow)
        
        let titleStack = UIStackView()
        titleStack.axis = .vertical
        titleStack.spacing = 3
        
        greetingLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleStack.addArrangedSubview(greetingLabel)
        
        monthLabel.font = .systemFont(ofSize: 14, weight: .medium)
        monthLabel.textColor = .secondaryLabel
        titleStack.addArrangedSubview(monthLabel)
        headerRow.addArrangedSubview(titleStack)
        
        // 2. Hero Balance Card
        heroBalanceCard.translatesAutoresizingMaskIntoConstraints = false
        heroBalanceCard.onToggleVisibility = { [weak self] in
            BiometricAuthManager.shared.hideBalance.toggle()
            self?.reloadData()
        }
        contentView.addSubview(heroBalanceCard)
        
        // 3. Quick Action Circular Buttons
        quickActionsStack.axis = .horizontal
        quickActionsStack.distribution = .equalSpacing
        quickActionsStack.alignment = .center
        quickActionsStack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(quickActionsStack)
        
        let expenseBtn = ActionIconButton(title: "+ Expense", iconName: "plus", gradientColors: [.systemRed])
        expenseBtn.onTap = { [weak self] in self?.addExpenseTapped() }
        quickActionsStack.addArrangedSubview(expenseBtn)
        
        let incomeBtn = ActionIconButton(title: "+ Income", iconName: "arrow.down", gradientColors: [.systemGreen])
        incomeBtn.onTap = { [weak self] in self?.addIncomeTapped() }
        quickActionsStack.addArrangedSubview(incomeBtn)
        
        let scanBtn = ActionIconButton(title: "Scan Receipt", iconName: "doc.viewfinder.fill", gradientColors: [.systemOrange])
        scanBtn.onTap = { [weak self] in self?.scanReceiptTapped() }
        quickActionsStack.addArrangedSubview(scanBtn)
        
        let aiBtn = ActionIconButton(title: "AI Assistant", iconName: "sparkles", gradientColors: [.systemPurple])
        aiBtn.onTap = { [weak self] in self?.aiAssistantTapped() }
        quickActionsStack.addArrangedSubview(aiBtn)
        
        // 4. Upcoming Expenses
        setupSection(title: "Upcoming Expenses", card: upcomingCard, stack: upcomingStack, below: quickActionsStack)
        
        // 5. Budget Overview
        setupSection(title: "Budget Overview", card: budgetCard, stack: budgetStack, below: upcomingCard)
        
        // 6. Recent Transactions
        let recentHeader = UIStackView()
        recentHeader.axis = .horizontal
        recentHeader.alignment = .center
        recentHeader.distribution = .equalSpacing
        recentHeader.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(recentHeader)
        
        let recentTitle = UILabel()
        recentTitle.text = "Recent Transactions"
        recentTitle.font = .systemFont(ofSize: 18, weight: .bold)
        recentHeader.addArrangedSubview(recentTitle)
        
        let seeAllBtn = UIButton(type: .system)
        seeAllBtn.setTitle("See All", for: .normal)
        seeAllBtn.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        seeAllBtn.addTarget(self, action: #selector(seeAllTapped), for: .touchUpInside)
        recentHeader.addArrangedSubview(seeAllBtn)
        
        recentTransactionsCard.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(recentTransactionsCard)
        
        recentTransactionsStack.axis = .vertical
        recentTransactionsStack.spacing = 0
        recentTransactionsStack.translatesAutoresizingMaskIntoConstraints = false
        recentTransactionsCard.addSubview(recentTransactionsStack)
        
        NSLayoutConstraint.activate([
            headerRow.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            headerRow.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            headerRow.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            heroBalanceCard.topAnchor.constraint(equalTo: headerRow.bottomAnchor, constant: 16),
            heroBalanceCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            heroBalanceCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            quickActionsStack.topAnchor.constraint(equalTo: heroBalanceCard.bottomAnchor, constant: 20),
            quickActionsStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            quickActionsStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            recentHeader.topAnchor.constraint(equalTo: budgetCard.bottomAnchor, constant: 24),
            recentHeader.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            recentHeader.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            recentTransactionsCard.topAnchor.constraint(equalTo: recentHeader.bottomAnchor, constant: 12),
            recentTransactionsCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            recentTransactionsCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            recentTransactionsCard.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -32),
            
            recentTransactionsStack.topAnchor.constraint(equalTo: recentTransactionsCard.topAnchor, constant: 6),
            recentTransactionsStack.leadingAnchor.constraint(equalTo: recentTransactionsCard.leadingAnchor),
            recentTransactionsStack.trailingAnchor.constraint(equalTo: recentTransactionsCard.trailingAnchor),
            recentTransactionsStack.bottomAnchor.constraint(equalTo: recentTransactionsCard.bottomAnchor, constant: -6)
        ])
    }
    
    private func setupSection(title: String, card: CardView, stack: UIStackView, below previousView: UIView) {
        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 18, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(label)
        
        card.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(card)
        
        stack.axis = .vertical
        stack.spacing = 14
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)
        
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: previousView.bottomAnchor, constant: 24),
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            card.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 12),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
        ])
    }
    
    @objc private func applyTheme() {
        let colors = ThemeManager.shared.colors
        view.backgroundColor = colors.background
        greetingLabel.textColor = colors.text
        heroBalanceCard.applyTheme()
        upcomingCard.applyTheme()
        budgetCard.applyTheme()
        recentTransactionsCard.applyTheme()
    }
    
    @objc public func reloadData() {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 {
            greetingLabel.text = "Good morning ☀️"
        } else if hour < 17 {
            greetingLabel.text = "Good afternoon 👋"
        } else {
            greetingLabel.text = "Good evening 🌙"
        }
        
        let monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "MMMM yyyy"
        monthLabel.text = monthFormatter.string(from: Date()).uppercased()
        
        let summary = TransactionManager.shared.getFinancialSummary()
        let isHidden = BiometricAuthManager.shared.hideBalance
        heroBalanceCard.configure(summary: summary, isHidden: isHidden)
        
        loadUpcomingExpenses()
        loadBudgetOverview()
        loadRecentTransactions()
        
        refreshControl.endRefreshing()
    }
    
    private func loadUpcomingExpenses() {
        upcomingStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        let now = Date()
        let request = NSFetchRequest<RecurringTransactionEntity>(entityName: "RecurringTransactionEntity")
        request.predicate = NSPredicate(format: "isEnabled == YES AND nextDate >= %@", now as NSDate)
        request.sortDescriptors = [NSSortDescriptor(key: "nextDate", ascending: true)]
        request.fetchLimit = 3
        
        let upcomingList = (try? CoreDataManager.shared.viewContext.fetch(request)) ?? []
        
        if upcomingList.isEmpty {
            let empty = UILabel()
            empty.text = "No upcoming recurring expenses due this month."
            empty.font = .systemFont(ofSize: 14)
            empty.textColor = .secondaryLabel
            upcomingStack.addArrangedSubview(empty)
        } else {
            for item in upcomingList {
                let cell = UpcomingExpenseCell()
                cell.configure(title: item.title ?? "Expense", dueDate: item.nextDate ?? now, amount: item.amount)
                upcomingStack.addArrangedSubview(cell)
            }
        }
    }
    
    private func loadBudgetOverview() {
        budgetStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let statuses = BudgetManager.shared.getBudgetStatuses()
        
        if statuses.isEmpty {
            let empty = UILabel()
            empty.text = "No budgets created yet. Tap Budgets to set spending targets."
            empty.font = .systemFont(ofSize: 14)
            empty.textColor = .secondaryLabel
            budgetStack.addArrangedSubview(empty)
        } else {
            let currency = CurrencyManager.shared
            for status in statuses.prefix(3) {
                let cell = BudgetCell()
                cell.configure(with: status)
                budgetStack.addArrangedSubview(cell)
            }
        }
    }
    
    private func loadRecentTransactions() {
        recentTransactionsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let recent = TransactionManager.shared.fetchTransactions(limit: 6)
        
        if recent.isEmpty {
            let empty = UILabel()
            empty.text = "No transactions yet. Tap '+ Expense' above to log your first spend."
            empty.font = .systemFont(ofSize: 14)
            empty.textColor = .secondaryLabel
            empty.textAlignment = .center
            empty.translatesAutoresizingMaskIntoConstraints = false
            empty.heightAnchor.constraint(equalToConstant: 44).isActive = true
            recentTransactionsStack.addArrangedSubview(empty)
        } else {
            for item in recent {
                let cell = TransactionCell()
                cell.configure(with: item)
                recentTransactionsStack.addArrangedSubview(cell)
            }
        }
    }
    
    // MARK: - Actions
    
    @objc private func handleRefresh() {
        TransactionManager.shared.processPendingRecurringTransactions()
        reloadData()
    }
    
    @objc private func addExpenseTapped() {
        let vc = AddExpenseViewController()
        let nav = UINavigationController(rootViewController: vc)
        if let sheet = nav.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
        }
        present(nav, animated: true)
    }
    
    @objc private func addIncomeTapped() {
        let vc = AddIncomeViewController()
        let nav = UINavigationController(rootViewController: vc)
        if let sheet = nav.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
        }
        present(nav, animated: true)
    }
    
    @objc private func scanReceiptTapped() {
        let vc = AddExpenseViewController()
        vc.shouldOpenReceiptScannerOnAppear = true
        let nav = UINavigationController(rootViewController: vc)
        present(nav, animated: true)
    }
    
    @objc private func aiAssistantTapped() {
        let vc = AIAssistantViewController()
        let nav = UINavigationController(rootViewController: vc)
        present(nav, animated: true)
    }
    
    @objc private func seeAllTapped() {
        tabBarController?.selectedIndex = 1
    }
    
    @objc private func loadSampleDataTapped() {
        let alert = UIAlertController(title: "Sample Data", message: "Populate realistic sample income, expenses, budgets, savings goals, and debts for testing?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Load Sample Data", style: .default, handler: { [weak self] _ in
            SampleDataLoader.shared.loadRealisticSampleData()
            self?.reloadData()
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
}
