//
//  NetWorthViewController.swift
//  BudgetTracker
//
//  Created by ali on 10/10/2026.
//

import UIKit

public class NetWorthViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    private let netWorthCard = CardView()
    private let netWorthAmountLabel = UILabel()
    private let assetsTotalLabel = UILabel()
    private let liabilitiesTotalLabel = UILabel()
    
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    
    private var assetAccounts: [AccountEntity] = []
    private var liabilityAccounts: [AccountEntity] = []
    private var totalAssets: Double = 0
    private var totalLiabilities: Double = 0
    private var netWorth: Double = 0
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigation()
        setupUI()
        reloadNetWorth()
    }
    
    private func setupNavigation() {
        title = "Net Worth"
        navigationController?.navigationBar.prefersLargeTitles = true
    }
    
    private func setupUI() {
        view.backgroundColor = ThemeManager.shared.colors.background
        
        netWorthCard.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(netWorthCard)
        
        let cardStack = UIStackView()
        cardStack.axis = .vertical
        cardStack.spacing = 10
        cardStack.translatesAutoresizingMaskIntoConstraints = false
        netWorthCard.addSubview(cardStack)
        
        let titleLabel = UILabel()
        titleLabel.text = "TOTAL NET WORTH"
        titleLabel.font = .systemFont(ofSize: 13, weight: .bold)
        titleLabel.textColor = .secondaryLabel
        titleLabel.textAlignment = .center
        cardStack.addArrangedSubview(titleLabel)
        
        netWorthAmountLabel.font = .systemFont(ofSize: 36, weight: .heavy)
        netWorthAmountLabel.textAlignment = .center
        cardStack.addArrangedSubview(netWorthAmountLabel)
        
        let subRow = UIStackView()
        subRow.axis = .horizontal
        subRow.distribution = .fillEqually
        subRow.spacing = 10
        
        let assetStack = UIStackView()
        assetStack.axis = .vertical
        assetStack.spacing = 2
        let aTitle = UILabel()
        aTitle.text = "Assets (+)"
        aTitle.font = .systemFont(ofSize: 12)
        aTitle.textColor = .secondaryLabel
        assetStack.addArrangedSubview(aTitle)
        assetsTotalLabel.font = .systemFont(ofSize: 17, weight: .bold)
        assetsTotalLabel.textColor = .systemGreen
        assetStack.addArrangedSubview(assetsTotalLabel)
        subRow.addArrangedSubview(assetStack)
        
        let liabStack = UIStackView()
        liabStack.axis = .vertical
        liabStack.spacing = 2
        let lTitle = UILabel()
        lTitle.text = "Liabilities (-)"
        lTitle.font = .systemFont(ofSize: 12)
        lTitle.textColor = .secondaryLabel
        liabStack.addArrangedSubview(lTitle)
        liabilitiesTotalLabel.font = .systemFont(ofSize: 17, weight: .bold)
        liabilitiesTotalLabel.textColor = .systemRed
        liabStack.addArrangedSubview(liabilitiesTotalLabel)
        subRow.addArrangedSubview(liabStack)
        
        cardStack.addArrangedSubview(subRow)
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = .clear
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            netWorthCard.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            netWorthCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            netWorthCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            cardStack.topAnchor.constraint(equalTo: netWorthCard.topAnchor, constant: 18),
            cardStack.leadingAnchor.constraint(equalTo: netWorthCard.leadingAnchor, constant: 18),
            cardStack.trailingAnchor.constraint(equalTo: netWorthCard.trailingAnchor, constant: -18),
            cardStack.bottomAnchor.constraint(equalTo: netWorthCard.bottomAnchor, constant: -18),
            
            tableView.topAnchor.constraint(equalTo: netWorthCard.bottomAnchor, constant: 10),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func reloadNetWorth() {
        let accounts = AccountManager.shared.fetchAccounts()
        assetAccounts = accounts.filter { $0.balance >= 0 }
        liabilityAccounts = accounts.filter { $0.balance < 0 }
        
        totalAssets = assetAccounts.reduce(0) { $0 + $1.balance }
        let totalDebt = DebtManager.shared.totalRemainingDebt()
        let accountDebt = liabilityAccounts.reduce(0) { $0 + abs($1.balance) }
        totalLiabilities = totalDebt + accountDebt
        
        netWorth = totalAssets - totalLiabilities
        
        let currency = CurrencyManager.shared
        netWorthAmountLabel.text = currency.format(netWorth)
        netWorthAmountLabel.textColor = netWorth >= 0 ? .systemBlue : .systemRed
        assetsTotalLabel.text = currency.format(totalAssets)
        liabilitiesTotalLabel.text = currency.format(totalLiabilities)
        
        tableView.reloadData()
    }
    
    // MARK: - TableView
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 0 ? "Assets" : "Liabilities"
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return assetAccounts.count
        } else {
            return liabilityAccounts.count + (DebtManager.shared.fetchDebts().isEmpty ? 0 : 1)
        }
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: "NetWorthCell")
        cell.backgroundColor = ThemeManager.shared.colors.card
        let currency = CurrencyManager.shared
        
        if indexPath.section == 0 {
            let item = assetAccounts[indexPath.row]
            cell.textLabel?.text = item.name
            cell.imageView?.image = UIImage(systemName: "plus.circle.fill")
            cell.imageView?.tintColor = .systemGreen
            cell.detailTextLabel?.text = currency.format(item.balance)
            cell.detailTextLabel?.textColor = .systemGreen
        } else {
            if indexPath.row < liabilityAccounts.count {
                let item = liabilityAccounts[indexPath.row]
                cell.textLabel?.text = item.name
                cell.imageView?.image = UIImage(systemName: "minus.circle.fill")
                cell.imageView?.tintColor = .systemRed
                cell.detailTextLabel?.text = currency.format(abs(item.balance))
                cell.detailTextLabel?.textColor = .systemRed
            } else {
                cell.textLabel?.text = "Recorded Loans & Debt"
                cell.imageView?.image = UIImage(systemName: "creditcard.fill")
                cell.imageView?.tintColor = .systemRed
                let debtTotal = DebtManager.shared.totalRemainingDebt()
                cell.detailTextLabel?.text = currency.format(debtTotal)
                cell.detailTextLabel?.textColor = .systemRed
            }
        }
        return cell
    }
}
