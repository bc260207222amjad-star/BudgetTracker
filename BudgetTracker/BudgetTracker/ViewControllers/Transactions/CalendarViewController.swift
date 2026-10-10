//
//  CalendarViewController.swift
//  BudgetTracker
//
//  Created by ali on 10/10/2026.
//

import UIKit

public class CalendarViewController: UIViewController, UICalendarViewDelegate, UICalendarSelectionSingleDateDelegate, UITableViewDataSource, UITableViewDelegate {
    
    private let calendarView = UICalendarView()
    private let summaryCard = CardView()
    private let dateLabel = UILabel()
    private let incomeLabel = UILabel()
    private let expenseLabel = UILabel()
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let emptyLabel = UILabel()
    
    private var selectedDate: Date = Date()
    private var dayTransactions: [TransactionEntity] = []
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigation()
        setupUI()
        setupCalendar()
        loadTransactions(for: selectedDate)
    }
    
    private func setupNavigation() {
        title = "Calendar"
        navigationItem.largeTitleDisplayMode = .never
    }
    
    private func setupUI() {
        view.backgroundColor = ThemeManager.shared.colors.background
        
        calendarView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(calendarView)
        
        summaryCard.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(summaryCard)
        
        let summaryStack = UIStackView()
        summaryStack.axis = .vertical
        summaryStack.spacing = 8
        summaryStack.translatesAutoresizingMaskIntoConstraints = false
        summaryCard.addSubview(summaryStack)
        
        dateLabel.font = .systemFont(ofSize: 16, weight: .bold)
        summaryStack.addArrangedSubview(dateLabel)
        
        let totalsRow = UIStackView()
        totalsRow.axis = .horizontal
        totalsRow.distribution = .fillEqually
        totalsRow.spacing = 10
        
        incomeLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        incomeLabel.textColor = .systemGreen
        totalsRow.addArrangedSubview(incomeLabel)
        
        expenseLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        expenseLabel.textColor = .systemRed
        totalsRow.addArrangedSubview(expenseLabel)
        
        summaryStack.addArrangedSubview(totalsRow)
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(TransactionCell.self, forCellReuseIdentifier: TransactionCell.reuseIdentifier)
        tableView.backgroundColor = .clear
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        
        emptyLabel.text = "No transactions recorded for this date."
        emptyLabel.font = .systemFont(ofSize: 14)
        emptyLabel.textColor = .secondaryLabel
        emptyLabel.textAlignment = .center
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(emptyLabel)
        
        NSLayoutConstraint.activate([
            calendarView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            calendarView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            calendarView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            
            summaryCard.topAnchor.constraint(equalTo: calendarView.bottomAnchor, constant: 10),
            summaryCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            summaryCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            summaryStack.topAnchor.constraint(equalTo: summaryCard.topAnchor, constant: 12),
            summaryStack.leadingAnchor.constraint(equalTo: summaryCard.leadingAnchor, constant: 14),
            summaryStack.trailingAnchor.constraint(equalTo: summaryCard.trailingAnchor, constant: -14),
            summaryStack.bottomAnchor.constraint(equalTo: summaryCard.bottomAnchor, constant: -12),
            
            tableView.topAnchor.constraint(equalTo: summaryCard.bottomAnchor, constant: 10),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            emptyLabel.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: tableView.centerYAnchor)
        ])
    }
    
    private func setupCalendar() {
        calendarView.delegate = self
        let selection = UICalendarSelectionSingleDate(delegate: self)
        selection.selectedDate = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        calendarView.selectionBehavior = selection
    }
    
    // MARK: - UICalendarSelectionSingleDateDelegate
    
    public func dateSelection(_ selection: UICalendarSelectionSingleDate, didSelectDate dateComponents: DateComponents?) {
        guard let comps = dateComponents, let date = Calendar.current.date(from: comps) else { return }
        selectedDate = date
        loadTransactions(for: date)
    }
    
    // MARK: - UICalendarViewDelegate
    
    public func calendarView(_ calendarView: UICalendarView, decorationFor dateComponents: DateComponents) -> UICalendarView.Decoration? {
        guard let date = Calendar.current.date(from: dateComponents) else { return nil }
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: DateComponents(day: 1, second: -1), to: startOfDay)!
        
        let txs = TransactionManager.shared.fetchTransactions(startDate: startOfDay, endDate: endOfDay)
        if !txs.isEmpty {
            let hasIncome = txs.contains { $0.type == TransactionType.income.rawValue }
            let color: UIColor = hasIncome ? .systemGreen : .systemRed
            return .default(color: color, size: .small)
        }
        return nil
    }
    
    private func loadTransactions(for date: Date) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: DateComponents(day: 1, second: -1), to: startOfDay)!
        
        dayTransactions = TransactionManager.shared.fetchTransactions(startDate: startOfDay, endDate: endOfDay)
        
        let df = DateFormatter()
        df.dateStyle = .medium
        dateLabel.text = df.string(from: date)
        
        let currency = CurrencyManager.shared
        let totalIncome = dayTransactions.filter { $0.type == TransactionType.income.rawValue }.reduce(0) { $0 + $1.amount }
        let totalExpense = dayTransactions.filter { $0.type == TransactionType.expense.rawValue }.reduce(0) { $0 + $1.amount }
        
        incomeLabel.text = "Income: +\(currency.format(totalIncome))"
        expenseLabel.text = "Expenses: -\(currency.format(totalExpense))"
        
        emptyLabel.isHidden = !dayTransactions.isEmpty
        tableView.isHidden = dayTransactions.isEmpty
        tableView.reloadData()
    }
    
    // MARK: - TableView
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dayTransactions.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: TransactionCell.reuseIdentifier, for: indexPath) as? TransactionCell else {
            return UITableViewCell()
        }
        cell.configure(with: dayTransactions[indexPath.row])
        return cell
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = dayTransactions[indexPath.row]
        let detailVC = TransactionDetailViewController(transaction: item)
        navigationController?.pushViewController(detailVC, animated: true)
    }
}
