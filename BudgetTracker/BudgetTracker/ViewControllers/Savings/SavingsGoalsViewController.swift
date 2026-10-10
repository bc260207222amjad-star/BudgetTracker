//
//  SavingsGoalsViewController.swift
//  BudgetTracker
//
//  Created by ali on 10/10/2026.
//

import UIKit

public class SavingsGoalsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let emptyView = EmptyStateView(
        symbolName: "star.circle.fill",
        title: "No savings goals yet",
        subtitle: "Create a savings goal and track your progress toward dreams and safety nets.",
        buttonTitle: "+ New Goal"
    )
    
    private var goals: [SavingsGoalEntity] = []
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigation()
        setupUI()
        setupObservers()
        reloadGoals()
    }
    
    private func setupNavigation() {
        title = "Savings Goals"
        navigationController?.navigationBar.prefersLargeTitles = true
        
        let addBtn = UIBarButtonItem(image: UIImage(systemName: "plus"), style: .plain, target: self, action: #selector(addGoalTapped))
        navigationItem.rightBarButtonItem = addBtn
    }
    
    private func setupUI() {
        view.backgroundColor = ThemeManager.shared.colors.background
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(SavingsGoalCell.self, forCellReuseIdentifier: SavingsGoalCell.reuseIdentifier)
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        
        emptyView.translatesAutoresizingMaskIntoConstraints = false
        emptyView.isHidden = true
        emptyView.onActionTapped = { [weak self] in
            self?.addGoalTapped()
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
        NotificationCenter.default.addObserver(self, selector: #selector(reloadGoals), name: .savingsGoalsDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadGoals), name: .currencyDidChange, object: nil)
    }
    
    @objc public func reloadGoals() {
        goals = SavingsManager.shared.fetchGoals()
        emptyView.isHidden = !goals.isEmpty
        tableView.isHidden = goals.isEmpty
        tableView.reloadData()
    }
    
    // MARK: - TableView
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return goals.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: SavingsGoalCell.reuseIdentifier, for: indexPath) as? SavingsGoalCell else {
            return UITableViewCell()
        }
        cell.configure(with: goals[indexPath.row])
        return cell
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let goal = goals[indexPath.row]
        promptGoalOptions(for: goal)
    }
    
    private func promptGoalOptions(for goal: SavingsGoalEntity) {
        let sheet = UIAlertController(title: goal.name, message: "Choose an action:", preferredStyle: .actionSheet)
        
        sheet.addAction(UIAlertAction(title: "Add Contribution (+)", style: .default, handler: { [weak self] _ in
            self?.promptAddContribution(to: goal)
        }))
        
        sheet.addAction(UIAlertAction(title: "Edit Goal", style: .default, handler: { [weak self] _ in
            let editVC = AddSavingsGoalViewController()
            editVC.goalToEdit = goal
            let nav = UINavigationController(rootViewController: editVC)
            self?.present(nav, animated: true)
        }))
        
        sheet.addAction(UIAlertAction(title: "Delete Goal", style: .destructive, handler: { [weak self] _ in
            SavingsManager.shared.deleteGoal(goal)
            self?.reloadGoals()
        }))
        
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(sheet, animated: true)
    }
    
    private func promptAddContribution(to goal: SavingsGoalEntity) {
        let alert = UIAlertController(title: "Add Contribution", message: "Enter amount saved toward '\(goal.name ?? "Goal")':", preferredStyle: .alert)
        alert.addTextField { tf in
            tf.placeholder = "Amount (e.g. 100.00)"
            tf.keyboardType = .decimalPad
        }
        alert.addAction(UIAlertAction(title: "Add", style: .default, handler: { [weak self] _ in
            guard let text = alert.textFields?.first?.text?.replacingOccurrences(of: ",", with: "."),
                  let amount = Double(text), amount > 0 else { return }
            SavingsManager.shared.addContribution(to: goal, amount: amount)
            self?.reloadGoals()
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    @objc private func addGoalTapped() {
        let vc = AddSavingsGoalViewController()
        let nav = UINavigationController(rootViewController: vc)
        present(nav, animated: true)
    }
}

// MARK: - Add / Edit Savings Goal Modal

public class AddSavingsGoalViewController: UIViewController {
    
    public var goalToEdit: SavingsGoalEntity?
    
    private let nameTextField = UITextField()
    private let targetTextField = UITextField()
    private let currentTextField = UITextField()
    private let deadlinePicker = UIDatePicker()
    private let hasDeadlineSwitch = UISwitch()
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigation()
        setupUI()
        populateIfEditing()
    }
    
    private func setupNavigation() {
        title = goalToEdit != nil ? "Edit Goal" : "New Savings Goal"
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveTapped))
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
        
        nameTextField.placeholder = "Goal Name (e.g. iPhone 16, New Car)"
        nameTextField.font = .systemFont(ofSize: 16)
        nameTextField.borderStyle = .roundedRect
        stack.addArrangedSubview(nameTextField)
        
        targetTextField.placeholder = "Target Amount (e.g. 1500.00)"
        targetTextField.font = .systemFont(ofSize: 16)
        targetTextField.keyboardType = .decimalPad
        targetTextField.borderStyle = .roundedRect
        stack.addArrangedSubview(targetTextField)
        
        currentTextField.placeholder = "Current Saved Amount (e.g. 500.00)"
        currentTextField.font = .systemFont(ofSize: 16)
        currentTextField.keyboardType = .decimalPad
        currentTextField.borderStyle = .roundedRect
        stack.addArrangedSubview(currentTextField)
        
        let deadlineToggleRow = UIStackView()
        deadlineToggleRow.axis = .horizontal
        deadlineToggleRow.distribution = .equalSpacing
        deadlineToggleRow.alignment = .center
        
        let dlLabel = UILabel()
        dlLabel.text = "Set Target Deadline"
        dlLabel.font = .systemFont(ofSize: 15, weight: .medium)
        deadlineToggleRow.addArrangedSubview(dlLabel)
        
        hasDeadlineSwitch.isOn = false
        hasDeadlineSwitch.addTarget(self, action: #selector(toggleDeadline), for: .valueChanged)
        deadlineToggleRow.addArrangedSubview(hasDeadlineSwitch)
        stack.addArrangedSubview(deadlineToggleRow)
        
        deadlinePicker.datePickerMode = .date
        deadlinePicker.preferredDatePickerStyle = .compact
        deadlinePicker.isEnabled = false
        stack.addArrangedSubview(deadlinePicker)
        
        let saveButton = UIButton(type: .system)
        saveButton.setTitle("Save Goal", for: .normal)
        saveButton.backgroundColor = .systemBlue
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .bold)
        saveButton.layer.cornerRadius = 14
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(saveButton)
        
        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            card.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            card.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16),
            
            saveButton.topAnchor.constraint(equalTo: card.bottomAnchor, constant: 24),
            saveButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            saveButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            saveButton.heightAnchor.constraint(equalToConstant: 52)
        ])
    }
    
    @objc private func toggleDeadline() {
        deadlinePicker.isEnabled = hasDeadlineSwitch.isOn
    }
    
    private func populateIfEditing() {
        guard let item = goalToEdit else { return }
        nameTextField.text = item.name
        targetTextField.text = String(format: "%.2f", item.targetAmount)
        currentTextField.text = String(format: "%.2f", item.currentAmount)
        if let dl = item.deadline {
            hasDeadlineSwitch.isOn = true
            deadlinePicker.isEnabled = true
            deadlinePicker.date = dl
        }
    }
    
    @objc private func cancelTapped() {
        dismiss(animated: true)
    }
    
    @objc private func saveTapped() {
        let name = (nameTextField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            showAlert("Please enter a goal name.")
            return
        }
        
        let targetText = (targetTextField.text ?? "").replacingOccurrences(of: ",", with: ".")
        guard let target = Double(targetText), target > 0 else {
            showAlert("Please enter a valid target amount greater than 0.")
            return
        }
        
        let currentText = (currentTextField.text ?? "").replacingOccurrences(of: ",", with: ".")
        let current = Double(currentText) ?? 0.0
        let deadline = hasDeadlineSwitch.isOn ? deadlinePicker.date : nil
        
        if let editing = goalToEdit {
            SavingsManager.shared.updateGoal(goal: editing, name: name, targetAmount: target, currentAmount: current, deadline: deadline, icon: "star.fill")
        } else {
            SavingsManager.shared.createGoal(name: name, targetAmount: target, currentAmount: current, deadline: deadline, icon: "star.fill")
        }
        
        dismiss(animated: true)
    }
    
    private func showAlert(_ msg: String) {
        let alert = UIAlertController(title: "Invalid Input", message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
