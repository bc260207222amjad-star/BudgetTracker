//
//  AccountsViewController.swift
//  BudgetTracker
//
//  Created by ali on 10/10/2026.
//

import UIKit

public class AccountsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var accounts: [AccountEntity] = []
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigation()
        setupUI()
        setupObservers()
        reloadAccounts()
    }
    
    private func setupNavigation() {
        title = "Accounts"
        navigationController?.navigationBar.prefersLargeTitles = true
        
        let transferBtn = UIBarButtonItem(title: "Transfer", style: .plain, target: self, action: #selector(transferTapped))
        let addBtn = UIBarButtonItem(image: UIImage(systemName: "plus"), style: .plain, target: self, action: #selector(addAccountTapped))
        navigationItem.rightBarButtonItems = [addBtn, transferBtn]
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
        NotificationCenter.default.addObserver(self, selector: #selector(reloadAccounts), name: .accountsDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadAccounts), name: .currencyDidChange, object: nil)
    }
    
    @objc public func reloadAccounts() {
        AccountManager.shared.ensureDefaultAccountsExist()
        accounts = AccountManager.shared.fetchAccounts()
        tableView.reloadData()
    }
    
    // MARK: - TableView
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return accounts.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: "AccountCell")
        cell.backgroundColor = ThemeManager.shared.colors.card
        
        let acc = accounts[indexPath.row]
        cell.textLabel?.text = acc.name
        cell.textLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        
        let accType = AccountType(rawValue: acc.type ?? "Bank") ?? .bank
        cell.imageView?.image = UIImage(systemName: accType.iconName)
        cell.imageView?.tintColor = .systemBlue
        
        let isHidden = BiometricAuthManager.shared.hideBalance
        cell.detailTextLabel?.text = isHidden ? "••••••" : CurrencyManager.shared.format(acc.balance)
        cell.detailTextLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        cell.detailTextLabel?.textColor = acc.balance >= 0 ? ThemeManager.shared.colors.text : .systemRed
        
        return cell
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let acc = accounts[indexPath.row]
        
        let sheet = UIAlertController(title: acc.name, message: "Type: \(acc.type ?? "Custom")\nBalance: \(CurrencyManager.shared.format(acc.balance))", preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "Transfer From This Account", style: .default, handler: { [weak self] _ in
            self?.openTransfer(from: acc)
        }))
        sheet.addAction(UIAlertAction(title: "Delete Account", style: .destructive, handler: { [weak self] _ in
            AccountManager.shared.deleteAccount(acc)
            self?.reloadAccounts()
        }))
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(sheet, animated: true)
    }
    
    @objc private func addAccountTapped() {
        let alert = UIAlertController(title: "New Account", message: "Enter account details:", preferredStyle: .alert)
        alert.addTextField { tf in tf.placeholder = "Account Name (e.g. PayPal, Apple Pay)" }
        alert.addTextField { tf in
            tf.placeholder = "Initial Balance (e.g. 100.00)"
            tf.keyboardType = .decimalPad
        }
        
        alert.addAction(UIAlertAction(title: "Create", style: .default, handler: { [weak self] _ in
            guard let name = alert.textFields?[0].text?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty else { return }
            let balanceText = (alert.textFields?[1].text ?? "0").replacingOccurrences(of: ",", with: ".")
            let bal = Double(balanceText) ?? 0.0
            AccountManager.shared.createAccount(name: name, type: .custom, initialBalance: bal)
            self?.reloadAccounts()
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    @objc private func transferTapped() {
        openTransfer(from: accounts.first)
    }
    
    private func openTransfer(from source: AccountEntity?) {
        guard accounts.count >= 2 else {
            let alert = UIAlertController(title: "Transfers", message: "You need at least 2 accounts to make a transfer.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        let transferVC = TransferViewController()
        transferVC.sourceAccount = source
        let nav = UINavigationController(rootViewController: transferVC)
        present(nav, animated: true)
    }
}

// MARK: - Transfer Modal

public class TransferViewController: UIViewController {
    public var sourceAccount: AccountEntity?
    private var targetAccount: AccountEntity?
    
    private let fromButton = UIButton(type: .system)
    private let toButton = UIButton(type: .system)
    private let amountTextField = UITextField()
    private let noteTextField = UITextField()
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigation()
        setupUI()
    }
    
    private func setupNavigation() {
        title = "Transfer Funds"
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Transfer", style: .done, target: self, action: #selector(transferTapped))
    }
    
    private func setupUI() {
        view.backgroundColor = ThemeManager.shared.colors.background
        
        let card = CardView()
        card.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(card)
        
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)
        
        let accounts = AccountManager.shared.fetchAccounts()
        if sourceAccount == nil { sourceAccount = accounts.first }
        if targetAccount == nil { targetAccount = accounts.last }
        
        // From row
        let fromRow = UIStackView()
        fromRow.axis = .horizontal
        fromRow.distribution = .equalSpacing
        fromRow.alignment = .center
        let fromLabel = UILabel()
        fromLabel.text = "From Account"
        fromLabel.font = .systemFont(ofSize: 15, weight: .medium)
        fromRow.addArrangedSubview(fromLabel)
        
        setupFromMenu(accounts: accounts)
        fromRow.addArrangedSubview(fromButton)
        stack.addArrangedSubview(fromRow)
        
        // To row
        let toRow = UIStackView()
        toRow.axis = .horizontal
        toRow.distribution = .equalSpacing
        toRow.alignment = .center
        let toLabel = UILabel()
        toLabel.text = "To Account"
        toLabel.font = .systemFont(ofSize: 15, weight: .medium)
        toRow.addArrangedSubview(toLabel)
        
        setupToMenu(accounts: accounts)
        toRow.addArrangedSubview(toButton)
        stack.addArrangedSubview(toRow)
        
        // Amount
        amountTextField.placeholder = "Amount to Transfer"
        amountTextField.font = .systemFont(ofSize: 22, weight: .bold)
        amountTextField.keyboardType = .decimalPad
        amountTextField.borderStyle = .roundedRect
        stack.addArrangedSubview(amountTextField)
        
        // Note
        noteTextField.placeholder = "Transfer Note (Optional)"
        noteTextField.borderStyle = .roundedRect
        stack.addArrangedSubview(noteTextField)
        
        let executeBtn = UIButton(type: .system)
        executeBtn.setTitle("Complete Transfer", for: .normal)
        executeBtn.backgroundColor = .systemBlue
        executeBtn.setTitleColor(.white, for: .normal)
        executeBtn.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        executeBtn.layer.cornerRadius = 14
        executeBtn.addTarget(self, action: #selector(transferTapped), for: .touchUpInside)
        executeBtn.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(executeBtn)
        
        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            card.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            card.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16),
            
            executeBtn.topAnchor.constraint(equalTo: card.bottomAnchor, constant: 24),
            executeBtn.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            executeBtn.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            executeBtn.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func setupFromMenu(accounts: [AccountEntity]) {
        let actions = accounts.map { acc in
            UIAction(title: acc.name ?? "Account", state: acc.id == sourceAccount?.id ? .on : .off) { [weak self] _ in
                self?.sourceAccount = acc
                self?.fromButton.setTitle(acc.name, for: .normal)
            }
        }
        fromButton.menu = UIMenu(children: actions)
        fromButton.showsMenuAsPrimaryAction = true
        fromButton.setTitle(sourceAccount?.name ?? "Select", for: .normal)
        fromButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
    }
    
    private func setupToMenu(accounts: [AccountEntity]) {
        let actions = accounts.map { acc in
            UIAction(title: acc.name ?? "Account", state: acc.id == targetAccount?.id ? .on : .off) { [weak self] _ in
                self?.targetAccount = acc
                self?.toButton.setTitle(acc.name, for: .normal)
            }
        }
        toButton.menu = UIMenu(children: actions)
        toButton.showsMenuAsPrimaryAction = true
        toButton.setTitle(targetAccount?.name ?? "Select", for: .normal)
        toButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
    }
    
    @objc private func cancelTapped() {
        dismiss(animated: true)
    }
    
    @objc private func transferTapped() {
        guard let source = sourceAccount, let target = targetAccount else { return }
        if source.id == target.id {
            showAlert("Source and destination accounts must be different.")
            return
        }
        
        let amtText = (amountTextField.text ?? "").replacingOccurrences(of: ",", with: ".")
        guard let amount = Double(amtText), amount > 0 else {
            showAlert("Please enter a valid transfer amount greater than 0.")
            return
        }
        
        AccountManager.shared.transferMoney(
            from: source,
            to: target,
            amount: amount,
            note: noteTextField.text
        )
        
        dismiss(animated: true)
    }
    
    private func showAlert(_ message: String) {
        let alert = UIAlertController(title: "Transfer Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
