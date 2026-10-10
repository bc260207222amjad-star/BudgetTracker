//
//  DebtTrackerViewController.swift
//  BudgetTracker
//
//  Created by ali on 10/10/2026.
//

import UIKit

public class DebtTrackerViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    private let strategySegmented = UISegmentedControl(items: ["Debt Snowball", "Debt Avalanche"])
    private let summaryCard = CardView()
    private let totalDebtLabel = UILabel()
    private let totalMinPaymentLabel = UILabel()
    private let strategyDescriptionLabel = UILabel()
    
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let disclaimerLabel = UILabel()
    
    private var debts: [DebtEntity] = []
    private var currentStrategy: DebtStrategy = .snowball
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigation()
        setupUI()
        setupObservers()
        reloadDebts()
    }
    
    private func setupNavigation() {
        title = "Debt Payoff Tracker"
        navigationController?.navigationBar.prefersLargeTitles = true
        
        let addBtn = UIBarButtonItem(image: UIImage(systemName: "plus"), style: .plain, target: self, action: #selector(addDebtTapped))
        navigationItem.rightBarButtonItem = addBtn
    }
    
    private func setupUI() {
        view.backgroundColor = ThemeManager.shared.colors.background
        
        strategySegmented.selectedSegmentIndex = 0
        strategySegmented.addTarget(self, action: #selector(strategyChanged), for: .valueChanged)
        strategySegmented.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(strategySegmented)
        
        summaryCard.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(summaryCard)
        
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        summaryCard.addSubview(stack)
        
        let metricsRow = UIStackView()
        metricsRow.axis = .horizontal
        metricsRow.distribution = .fillEqually
        metricsRow.spacing = 10
        
        let debtCol = UIStackView()
        debtCol.axis = .vertical
        debtCol.spacing = 2
        let dTitle = UILabel()
        dTitle.text = "Total Remaining Debt"
        dTitle.font = .systemFont(ofSize: 12, weight: .regular)
        dTitle.textColor = .secondaryLabel
        debtCol.addArrangedSubview(dTitle)
        totalDebtLabel.font = .systemFont(ofSize: 20, weight: .bold)
        totalDebtLabel.textColor = .systemRed
        debtCol.addArrangedSubview(totalDebtLabel)
        metricsRow.addArrangedSubview(debtCol)
        
        let minCol = UIStackView()
        minCol.axis = .vertical
        minCol.spacing = 2
        let mTitle = UILabel()
        mTitle.text = "Total Min Payment"
        mTitle.font = .systemFont(ofSize: 12, weight: .regular)
        mTitle.textColor = .secondaryLabel
        minCol.addArrangedSubview(mTitle)
        totalMinPaymentLabel.font = .systemFont(ofSize: 20, weight: .bold)
        totalMinPaymentLabel.textColor = .label
        minCol.addArrangedSubview(totalMinPaymentLabel)
        metricsRow.addArrangedSubview(minCol)
        
        stack.addArrangedSubview(metricsRow)
        
        strategyDescriptionLabel.text = DebtStrategy.snowball.description
        strategyDescriptionLabel.font = .systemFont(ofSize: 12, weight: .regular)
        strategyDescriptionLabel.textColor = .secondaryLabel
        strategyDescriptionLabel.numberOfLines = 0
        stack.addArrangedSubview(strategyDescriptionLabel)
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = .clear
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        
        disclaimerLabel.text = DebtManager.disclaimerText
        disclaimerLabel.font = .systemFont(ofSize: 11, weight: .regular)
        disclaimerLabel.textColor = .tertiaryLabel
        disclaimerLabel.textAlignment = .center
        disclaimerLabel.numberOfLines = 0
        disclaimerLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(disclaimerLabel)
        
        NSLayoutConstraint.activate([
            strategySegmented.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            strategySegmented.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            strategySegmented.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            summaryCard.topAnchor.constraint(equalTo: strategySegmented.bottomAnchor, constant: 12),
            summaryCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            summaryCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            stack.topAnchor.constraint(equalTo: summaryCard.topAnchor, constant: 14),
            stack.leadingAnchor.constraint(equalTo: summaryCard.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: summaryCard.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: summaryCard.bottomAnchor, constant: -14),
            
            tableView.topAnchor.constraint(equalTo: summaryCard.bottomAnchor, constant: 10),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: disclaimerLabel.topAnchor, constant: -6),
            
            disclaimerLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            disclaimerLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            disclaimerLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8)
        ])
    }
    
    private func setupObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(reloadDebts), name: .debtsDidChange, object: nil)
    }
    
    @objc private func strategyChanged() {
        currentStrategy = (strategySegmented.selectedSegmentIndex == 0) ? .snowball : .avalanche
        strategyDescriptionLabel.text = currentStrategy.description
        reloadDebts()
    }
    
    @objc public func reloadDebts() {
        debts = DebtManager.shared.fetchDebts(strategy: currentStrategy)
        
        let currency = CurrencyManager.shared
        let totalDebt = DebtManager.shared.totalRemainingDebt()
        let totalMin = DebtManager.shared.totalMinimumMonthlyPayment()
        
        totalDebtLabel.text = currency.format(totalDebt)
        totalMinPaymentLabel.text = currency.format(totalMin)
        
        tableView.reloadData()
    }
    
    // MARK: - TableView
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return debts.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "DebtCell")
        cell.backgroundColor = ThemeManager.shared.colors.card
        let debt = debts[indexPath.row]
        let currency = CurrencyManager.shared
        
        let priorityBadge = "#\(indexPath.row + 1)"
        cell.textLabel?.text = "\(priorityBadge) - \(debt.name ?? "Debt") (\(debt.interestRate)%)"
        cell.textLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        
        let paidPct = Int(debt.progressPercentage * 100)
        cell.detailTextLabel?.text = "Remaining: \(currency.format(debt.remainingAmount)) / \(currency.format(debt.totalAmount)) (\(paidPct)% paid) • Min: \(currency.format(debt.minimumPayment))"
        cell.detailTextLabel?.textColor = .secondaryLabel
        
        let progressView = UIProgressView(progressViewStyle: .default)
        progressView.progress = Float(debt.progressPercentage)
        progressView.progressTintColor = .systemGreen
        progressView.frame = CGRect(x: 0, y: 0, width: 80, height: 4)
        cell.accessoryView = progressView
        
        return cell
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let debt = debts[indexPath.row]
        
        let sheet = UIAlertController(title: debt.name, message: "Record payment toward this debt:", preferredStyle: .alert)
        sheet.addTextField { tf in
            tf.placeholder = "Payment Amount"
            tf.keyboardType = .decimalPad
        }
        sheet.addAction(UIAlertAction(title: "Record Payment", style: .default, handler: { [weak self] _ in
            guard let text = sheet.textFields?.first?.text?.replacingOccurrences(of: ",", with: "."),
                  let amt = Double(text), amt > 0 else { return }
            DebtManager.shared.recordPayment(debt: debt, paymentAmount: amt)
            self?.reloadDebts()
        }))
        sheet.addAction(UIAlertAction(title: "Delete Debt", style: .destructive, handler: { [weak self] _ in
            DebtManager.shared.deleteDebt(debt)
            self?.reloadDebts()
        }))
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(sheet, animated: true)
    }
    
    @objc private func addDebtTapped() {
        let alert = UIAlertController(title: "Add Debt", message: "Enter debt information for payoff planning:", preferredStyle: .alert)
        alert.addTextField { tf in tf.placeholder = "Debt Name (e.g. Visa Credit Card)" }
        alert.addTextField { tf in tf.placeholder = "Total Amount (e.g. 2000)"; tf.keyboardType = .decimalPad }
        alert.addTextField { tf in tf.placeholder = "Remaining Balance (e.g. 1500)"; tf.keyboardType = .decimalPad }
        alert.addTextField { tf in tf.placeholder = "Interest Rate % (e.g. 19.5)"; tf.keyboardType = .decimalPad }
        alert.addTextField { tf in tf.placeholder = "Minimum Payment (e.g. 50)"; tf.keyboardType = .decimalPad }
        
        alert.addAction(UIAlertAction(title: "Add", style: .default, handler: { [weak self] _ in
            guard let name = alert.textFields?[0].text?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty,
                  let total = Double(alert.textFields?[1].text?.replacingOccurrences(of: ",", with: ".") ?? "0"),
                  let remaining = Double(alert.textFields?[2].text?.replacingOccurrences(of: ",", with: ".") ?? "0") else { return }
            
            let interest = Double(alert.textFields?[3].text?.replacingOccurrences(of: ",", with: ".") ?? "0") ?? 0.0
            let minPay = Double(alert.textFields?[4].text?.replacingOccurrences(of: ",", with: ".") ?? "0") ?? 0.0
            
            DebtManager.shared.createDebt(
                name: name,
                totalAmount: total,
                remainingAmount: remaining,
                interestRate: interest,
                minimumPayment: minPay
            )
            self?.reloadDebts()
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
}
