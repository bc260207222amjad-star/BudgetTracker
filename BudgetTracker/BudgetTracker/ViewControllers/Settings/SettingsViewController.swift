//
//  SettingsViewController.swift
//  BudgetTracker
//
//  Created by ali on 10/10/2026.
//

import UIKit

public class SettingsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigation()
        setupUI()
        setupObservers()
    }
    
    private func setupNavigation() {
        title = "Settings"
        navigationController?.navigationBar.prefersLargeTitles = true
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
    
    private func setupObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(applyTheme), name: .themeDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadSettings), name: .securitySettingsDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadSettings), name: .currencyDidChange, object: nil)
    }
    
    @objc private func applyTheme() {
        view.backgroundColor = ThemeManager.shared.colors.background
        tableView.reloadData()
    }
    
    @objc private func reloadSettings() {
        tableView.reloadData()
    }
    
    // MARK: - TableView Data Source & Delegate
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        return 7
    }
    
    public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "Security & Privacy"
        case 1: return "Appearance & Currency"
        case 2: return "Notifications"
        case 3: return "Financial Management"
        case 4: return "Data & Reports"
        case 5: return "About"
        case 6: return "Danger Zone"
        default: return nil
        }
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 2 // Biometrics toggle, Lock timeout
        case 1: return 4 // Theme, Hide balance, Hide amounts, Currency
        case 2: return 3 // Budget alerts, Bill reminders, Savings reminders
        case 3: return 4 // Accounts, Debt Tracker, Net Worth, Categories
        case 4: return 3 // Export CSV, Export PDF, Load Sample Data
        case 5: return 4 // Onboarding, Privacy Policy, Terms, Version
        case 6: return 2 // Delete Transactions, Reset App Data
        default: return 0
        }
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: "SettingsCell")
        cell.backgroundColor = ThemeManager.shared.colors.card
        cell.accessoryType = .none
        cell.accessoryView = nil
        cell.textLabel?.textColor = ThemeManager.shared.colors.text
        cell.detailTextLabel?.textColor = ThemeManager.shared.colors.secondaryText
        
        switch (indexPath.section, indexPath.row) {
        // Section 0: Security & Privacy
        case (0, 0):
            cell.textLabel?.text = "\(BiometricAuthManager.shared.biometryTitle) Lock"
            cell.imageView?.image = UIImage(systemName: BiometricAuthManager.shared.biometryIconName)
            cell.imageView?.tintColor = .systemBlue
            let toggle = UISwitch()
            toggle.isOn = BiometricAuthManager.shared.isBiometricsEnabled
            toggle.addTarget(self, action: #selector(biometricsToggleChanged(_:)), for: .valueChanged)
            cell.accessoryView = toggle
            
        case (0, 1):
            cell.textLabel?.text = "Lock Timeout"
            cell.imageView?.image = UIImage(systemName: "timer")
            cell.imageView?.tintColor = .systemBlue
            cell.detailTextLabel?.text = BiometricAuthManager.shared.lockTimeout.title
            cell.accessoryType = .disclosureIndicator
            
        // Section 1: Appearance & Currency
        case (1, 0):
            cell.textLabel?.text = "Theme"
            cell.imageView?.image = UIImage(systemName: "paintpalette.fill")
            cell.imageView?.tintColor = .systemPurple
            cell.detailTextLabel?.text = ThemeManager.shared.currentTheme.rawValue
            cell.accessoryType = .disclosureIndicator
            
        case (1, 1):
            cell.textLabel?.text = "Hide Balance"
            cell.imageView?.image = UIImage(systemName: "eye.slash.fill")
            cell.imageView?.tintColor = .systemOrange
            let toggle = UISwitch()
            toggle.isOn = BiometricAuthManager.shared.hideBalance
            toggle.addTarget(self, action: #selector(hideBalanceToggleChanged(_:)), for: .valueChanged)
            cell.accessoryView = toggle
            
        case (1, 2):
            cell.textLabel?.text = "Hide Transaction Amounts"
            cell.imageView?.image = UIImage(systemName: "number.square.fill")
            cell.imageView?.tintColor = .systemOrange
            let toggle = UISwitch()
            toggle.isOn = BiometricAuthManager.shared.hideTransactionAmounts
            toggle.addTarget(self, action: #selector(hideAmountsToggleChanged(_:)), for: .valueChanged)
            cell.accessoryView = toggle
            
        case (1, 3):
            cell.textLabel?.text = "Currency"
            cell.imageView?.image = UIImage(systemName: "dollarsign.circle.fill")
            cell.imageView?.tintColor = .systemGreen
            let curr = CurrencyManager.shared.currentCurrency
            cell.detailTextLabel?.text = "\(curr.name) (\(curr.symbol.trimmingCharacters(in: .whitespaces)))"
            cell.accessoryType = .disclosureIndicator
            
        // Section 2: Notifications
        case (2, 0):
            cell.textLabel?.text = "Budget Alerts"
            cell.imageView?.image = UIImage(systemName: "bell.badge.fill")
            cell.imageView?.tintColor = .systemRed
            let toggle = UISwitch()
            toggle.isOn = NotificationManager.shared.budgetAlertsEnabled
            toggle.addAction(UIAction { _ in NotificationManager.shared.budgetAlertsEnabled = toggle.isOn }, for: .valueChanged)
            cell.accessoryView = toggle
            
        case (2, 1):
            cell.textLabel?.text = "Bill Reminders"
            cell.imageView?.image = UIImage(systemName: "calendar.badge.exclamationmark")
            cell.imageView?.tintColor = .systemOrange
            let toggle = UISwitch()
            toggle.isOn = NotificationManager.shared.billRemindersEnabled
            toggle.addAction(UIAction { _ in NotificationManager.shared.billRemindersEnabled = toggle.isOn }, for: .valueChanged)
            cell.accessoryView = toggle
            
        case (2, 2):
            cell.textLabel?.text = "Savings Milestones"
            cell.imageView?.image = UIImage(systemName: "star.fill")
            cell.imageView?.tintColor = .systemYellow
            let toggle = UISwitch()
            toggle.isOn = NotificationManager.shared.savingsRemindersEnabled
            toggle.addAction(UIAction { _ in NotificationManager.shared.savingsRemindersEnabled = toggle.isOn }, for: .valueChanged)
            cell.accessoryView = toggle
            
        // Section 3: Financial Management
        case (3, 0):
            cell.textLabel?.text = "Manage Accounts"
            cell.imageView?.image = UIImage(systemName: "building.columns.fill")
            cell.imageView?.tintColor = .systemTeal
            cell.accessoryType = .disclosureIndicator
            
        case (3, 1):
            cell.textLabel?.text = "Debt Payoff Tracker"
            cell.imageView?.image = UIImage(systemName: "creditcard.and.123")
            cell.imageView?.tintColor = .systemIndigo
            cell.accessoryType = .disclosureIndicator
            
        case (3, 2):
            cell.textLabel?.text = "Net Worth"
            cell.imageView?.image = UIImage(systemName: "chart.line.uptrend.xyaxis.circle.fill")
            cell.imageView?.tintColor = .systemGreen
            cell.accessoryType = .disclosureIndicator
            
        case (3, 3):
            cell.textLabel?.text = "Manage Categories"
            cell.imageView?.image = UIImage(systemName: "square.grid.2x2.fill")
            cell.imageView?.tintColor = .systemBlue
            cell.accessoryType = .disclosureIndicator
            
        // Section 4: Data & Reports
        case (4, 0):
            cell.textLabel?.text = "Export Transactions (CSV)"
            cell.imageView?.image = UIImage(systemName: "tablecells.fill")
            cell.imageView?.tintColor = .systemBlue
            cell.accessoryType = .disclosureIndicator
            
        case (4, 1):
            cell.textLabel?.text = "Export Monthly Report (PDF)"
            cell.imageView?.image = UIImage(systemName: "doc.richtext.fill")
            cell.imageView?.tintColor = .systemRed
            cell.accessoryType = .disclosureIndicator
            
        case (4, 2):
            cell.textLabel?.text = "Load Sample Data"
            cell.imageView?.image = UIImage(systemName: "wand.and.stars")
            cell.imageView?.tintColor = .systemPurple
            cell.detailTextLabel?.text = "Development"
            cell.accessoryType = .disclosureIndicator
            
        // Section 5: About
        case (5, 0):
            cell.textLabel?.text = "Replay Onboarding Walkthrough"
            cell.imageView?.image = UIImage(systemName: "sparkles.tv.fill")
            cell.imageView?.tintColor = .systemBlue
            cell.accessoryType = .disclosureIndicator
            
        case (5, 1):
            cell.textLabel?.text = "Privacy Architecture"
            cell.imageView?.image = UIImage(systemName: "lock.shield.fill")
            cell.imageView?.tintColor = .systemGreen
            cell.accessoryType = .disclosureIndicator
            
        case (5, 2):
            cell.textLabel?.text = "Terms of Use"
            cell.imageView?.image = UIImage(systemName: "doc.text.fill")
            cell.imageView?.tintColor = .secondaryLabel
            cell.accessoryType = .disclosureIndicator
            
        case (5, 3):
            cell.textLabel?.text = "App Version"
            cell.imageView?.image = UIImage(systemName: "info.circle.fill")
            cell.imageView?.tintColor = .secondaryLabel
            cell.detailTextLabel?.text = "1.0 (Build 1)"
            
        // Section 6: Danger Zone
        case (6, 0):
            cell.textLabel?.text = "Delete All Transactions"
            cell.textLabel?.textColor = .systemRed
            cell.imageView?.image = UIImage(systemName: "trash.fill")
            cell.imageView?.tintColor = .systemRed
            
        case (6, 1):
            cell.textLabel?.text = "Reset All App Data"
            cell.textLabel?.textColor = .systemRed
            cell.imageView?.image = UIImage(systemName: "exclamationmark.triangle.fill")
            cell.imageView?.tintColor = .systemRed
            
        default:
            break
        }
        
        return cell
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch (indexPath.section, indexPath.row) {
        case (0, 1):
            showLockTimeoutPicker()
        case (1, 0):
            showThemePicker()
        case (1, 3):
            showCurrencyPicker()
        case (3, 0):
            navigationController?.pushViewController(AccountsViewController(), animated: true)
        case (3, 1):
            navigationController?.pushViewController(DebtTrackerViewController(), animated: true)
        case (3, 2):
            navigationController?.pushViewController(NetWorthViewController(), animated: true)
        case (3, 3):
            navigationController?.pushViewController(CategoryManagerViewController(), animated: true)
        case (4, 0):
            exportCSV()
        case (4, 1):
            exportPDF()
        case (4, 2):
            loadSampleDataPrompt()
        case (5, 0):
            let onboarding = OnboardingViewController()
            present(onboarding, animated: true)
        case (5, 1):
            showPrivacyInfo()
        case (5, 2):
            showTermsInfo()
        case (6, 0):
            confirmDeleteAllTransactions()
        case (6, 1):
            confirmResetAllData()
        default:
            break
        }
    }
    
    // MARK: - Actions & Pickers
    
    @objc private func biometricsToggleChanged(_ sender: UISwitch) {
        if sender.isOn {
            BiometricAuthManager.shared.authenticate(reason: "Enable biometric lock") { [weak self] success in
                BiometricAuthManager.shared.isBiometricsEnabled = success
                sender.isOn = success
                self?.tableView.reloadData()
            }
        } else {
            BiometricAuthManager.shared.isBiometricsEnabled = false
            tableView.reloadData()
        }
    }
    
    @objc private func hideBalanceToggleChanged(_ sender: UISwitch) {
        BiometricAuthManager.shared.hideBalance = sender.isOn
    }
    
    @objc private func hideAmountsToggleChanged(_ sender: UISwitch) {
        BiometricAuthManager.shared.hideTransactionAmounts = sender.isOn
    }
    
    private func showLockTimeoutPicker() {
        let sheet = UIAlertController(title: "Lock Timeout", message: "Choose when to lock the app after entering background:", preferredStyle: .actionSheet)
        for timeout in LockTimeout.allCases {
            sheet.addAction(UIAlertAction(title: timeout.title, style: .default, handler: { [weak self] _ in
                BiometricAuthManager.shared.lockTimeout = timeout
                self?.tableView.reloadData()
            }))
        }
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(sheet, animated: true)
    }
    
    private func showThemePicker() {
        let sheet = UIAlertController(title: "Choose Theme", message: "Select application appearance:", preferredStyle: .actionSheet)
        for theme in AppThemeType.allCases {
            sheet.addAction(UIAlertAction(title: theme.rawValue, style: .default, handler: { [weak self] _ in
                ThemeManager.shared.setTheme(theme)
                self?.tableView.reloadData()
            }))
        }
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(sheet, animated: true)
    }
    
    private func showCurrencyPicker() {
        let sheet = UIAlertController(title: "Select Currency", message: "Choose default currency for your records:", preferredStyle: .actionSheet)
        for c in CurrencyInfo.supportedCurrencies {
            sheet.addAction(UIAlertAction(title: "\(c.name) (\(c.code) - \(c.symbol.trimmingCharacters(in: .whitespaces)))", style: .default, handler: { [weak self] _ in
                CurrencyManager.shared.setCurrency(code: c.code)
                self?.tableView.reloadData()
            }))
        }
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(sheet, animated: true)
    }
    
    private func exportCSV() {
        let all = TransactionManager.shared.fetchTransactions()
        if let url = ExportManager.shared.generateCSV(transactions: all) {
            let act = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            present(act, animated: true)
        }
    }
    
    private func exportPDF() {
        if let url = ExportManager.shared.generatePDFReport() {
            let act = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            present(act, animated: true)
        }
    }
    
    private func loadSampleDataPrompt() {
        let alert = UIAlertController(title: "Load Sample Data", message: "This will populate realistic transactions, budgets, accounts, savings goals, and debts for testing.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Load", style: .default, handler: { [weak self] _ in
            SampleDataLoader.shared.loadRealisticSampleData()
            let conf = UIAlertController(title: "Success", message: "Sample data loaded successfully!", preferredStyle: .alert)
            conf.addAction(UIAlertAction(title: "OK", style: .default))
            self?.present(conf, animated: true)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    private func showPrivacyInfo() {
        let alert = UIAlertController(
            title: "Privacy-First Architecture",
            message: "• 100% Local Storage: All financial data, transactions, and notes remain strictly on your iPhone.\n• No Tracking: No remote telemetry or marketing analytics.\n• Biometric Shield: App lock with Face ID / Touch ID protects your sensitive finances.\n• Screen Blur: Content is blurred in the iOS App Switcher.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Got it", style: .default))
        present(alert, animated: true)
    }
    
    private func showTermsInfo() {
        let alert = UIAlertController(
            title: "Terms & Disclaimers",
            message: "BudgetTracker is an informational personal budgeting utility. It does not provide professional tax, legal, or financial advisory services. All calculations and AI outputs are intended for planning convenience.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func confirmDeleteAllTransactions() {
        let alert = UIAlertController(title: "Delete All Transactions?", message: "This will permanently remove all income and expense records. This action cannot be undone.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Delete All", style: .destructive, handler: { _ in
            let all = TransactionManager.shared.fetchTransactions()
            for tx in all {
                TransactionManager.shared.deleteTransaction(tx)
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    private func confirmResetAllData() {
        let alert = UIAlertController(title: "Reset All App Data?", message: "This will erase all transactions, accounts, budgets, savings goals, and debts back to initial factory state.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Erase Everything", style: .destructive, handler: { [weak self] _ in
            CoreDataManager.shared.deleteAllData()
            AccountManager.shared.ensureDefaultAccountsExist()
            self?.tableView.reloadData()
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
}
