//
//  AddBudgetViewController.swift
//  BudgetTracker
//
//  Created by ali on 10/10/2026.
//

import UIKit

public class AddBudgetViewController: UIViewController {
    
    public var budgetToEdit: BudgetEntity?
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    private let nameTextField = UITextField()
    private let limitTextField = UITextField()
    private let typeSegmented = UISegmentedControl(items: ["Category Budget", "Overall Monthly"])
    
    private let categoryButton = UIButton(type: .system)
    private var selectedCategory: String = "Food"
    
    private let alert50Switch = UISwitch()
    private let alert75Switch = UISwitch()
    private let alert90Switch = UISwitch()
    
    private let saveButton = UIButton(type: .system)
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigation()
        setupUI()
        populateIfEditing()
    }
    
    private func setupNavigation() {
        title = budgetToEdit != nil ? "Edit Budget" : "Create Budget"
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveTapped))
    }
    
    private func setupUI() {
        view.backgroundColor = ThemeManager.shared.colors.background
        
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
        
        let card = CardView()
        card.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(card)
        
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)
        
        // Type segmented
        typeSegmented.selectedSegmentIndex = 0
        typeSegmented.addTarget(self, action: #selector(typeChanged), for: .valueChanged)
        stack.addArrangedSubview(typeSegmented)
        
        // Name
        nameTextField.placeholder = "Budget Name (e.g. Dining Out, Monthly Cap)"
        nameTextField.font = .systemFont(ofSize: 16)
        nameTextField.borderStyle = .roundedRect
        stack.addArrangedSubview(nameTextField)
        
        // Limit
        limitTextField.placeholder = "Monthly Limit (e.g. 500.00)"
        limitTextField.font = .systemFont(ofSize: 16)
        limitTextField.keyboardType = .decimalPad
        limitTextField.borderStyle = .roundedRect
        stack.addArrangedSubview(limitTextField)
        
        // Category picker row
        let catRow = UIStackView()
        catRow.axis = .horizontal
        catRow.distribution = .equalSpacing
        catRow.alignment = .center
        
        let catLabel = UILabel()
        catLabel.text = "Category"
        catLabel.font = .systemFont(ofSize: 15, weight: .medium)
        catRow.addArrangedSubview(catLabel)
        
        setupCategoryMenu()
        catRow.addArrangedSubview(categoryButton)
        stack.addArrangedSubview(catRow)
        
        // Alerts Section
        let alertsCard = CardView()
        alertsCard.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(alertsCard)
        
        let alertStack = UIStackView()
        alertStack.axis = .vertical
        alertStack.spacing = 14
        alertStack.translatesAutoresizingMaskIntoConstraints = false
        alertsCard.addSubview(alertStack)
        
        let alertHeader = UILabel()
        alertHeader.text = "Threshold Alerts"
        alertHeader.font = .systemFont(ofSize: 15, weight: .bold)
        alertStack.addArrangedSubview(alertHeader)
        
        alert50Switch.isOn = true
        alertStack.addArrangedSubview(createSwitchRow(title: "Notify at 50% of budget", toggle: alert50Switch))
        
        alert75Switch.isOn = true
        alertStack.addArrangedSubview(createSwitchRow(title: "Notify at 75% of budget", toggle: alert75Switch))
        
        alert90Switch.isOn = true
        alertStack.addArrangedSubview(createSwitchRow(title: "Notify at 90% of budget", toggle: alert90Switch))
        
        // Save Button
        saveButton.setTitle("Save Budget", for: .normal)
        saveButton.backgroundColor = .systemBlue
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .bold)
        saveButton.layer.cornerRadius = 14
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(saveButton)
        
        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16),
            
            alertsCard.topAnchor.constraint(equalTo: card.bottomAnchor, constant: 16),
            alertsCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            alertsCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            alertStack.topAnchor.constraint(equalTo: alertsCard.topAnchor, constant: 16),
            alertStack.leadingAnchor.constraint(equalTo: alertsCard.leadingAnchor, constant: 16),
            alertStack.trailingAnchor.constraint(equalTo: alertsCard.trailingAnchor, constant: -16),
            alertStack.bottomAnchor.constraint(equalTo: alertsCard.bottomAnchor, constant: -16),
            
            saveButton.topAnchor.constraint(equalTo: alertsCard.bottomAnchor, constant: 24),
            saveButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            saveButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            saveButton.heightAnchor.constraint(equalToConstant: 52),
            saveButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -30)
        ])
    }
    
    private func createSwitchRow(title: String, toggle: UISwitch) -> UIView {
        let row = UIStackView()
        row.axis = .horizontal
        row.distribution = .equalSpacing
        row.alignment = .center
        
        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 14)
        row.addArrangedSubview(label)
        
        row.addArrangedSubview(toggle)
        return row
    }
    
    private func setupCategoryMenu() {
        let cats = CategoryManager.shared.getExpenseCategories()
        let actions = cats.map { cat in
            UIAction(title: cat.name, state: cat.name == selectedCategory ? .on : .off) { [weak self] _ in
                self?.selectedCategory = cat.name
                self?.categoryButton.setTitle(cat.name, for: .normal)
            }
        }
        categoryButton.menu = UIMenu(children: actions)
        categoryButton.showsMenuAsPrimaryAction = true
        categoryButton.setTitle(selectedCategory, for: .normal)
        categoryButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
    }
    
    @objc private func typeChanged() {
        let isOverall = (typeSegmented.selectedSegmentIndex == 1)
        categoryButton.isEnabled = !isOverall
        if isOverall && (nameTextField.text?.isEmpty == true) {
            nameTextField.text = "Overall Monthly Budget"
        }
    }
    
    private func populateIfEditing() {
        guard let item = budgetToEdit else { return }
        nameTextField.text = item.name
        limitTextField.text = String(format: "%.2f", item.limit)
        if item.isOverall {
            typeSegmented.selectedSegmentIndex = 1
            categoryButton.isEnabled = false
        } else {
            typeSegmented.selectedSegmentIndex = 0
            selectedCategory = item.category ?? "Food"
            categoryButton.setTitle(selectedCategory, for: .normal)
        }
        alert50Switch.isOn = item.alert50Enabled
        alert75Switch.isOn = item.alert75Enabled
        alert90Switch.isOn = item.alert90Enabled
    }
    
    @objc private func cancelTapped() {
        dismiss(animated: true)
    }
    
    @objc private func saveTapped() {
        let limitText = (limitTextField.text ?? "").replacingOccurrences(of: ",", with: ".").trimmingCharacters(in: .whitespacesAndNewlines)
        guard let limit = Double(limitText), limit > 0 else {
            let alert = UIAlertController(title: "Invalid Limit", message: "Please enter a valid budget limit greater than 0.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        
        let name = (nameTextField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let isOverall = (typeSegmented.selectedSegmentIndex == 1)
        let resolvedCategory: String? = isOverall ? nil : selectedCategory
        let resolvedName = name.isEmpty ? (isOverall ? "Overall Monthly Budget" : "\(selectedCategory) Budget") : name
        
        if let editing = budgetToEdit {
            BudgetManager.shared.updateBudget(
                budget: editing,
                name: resolvedName,
                category: resolvedCategory,
                limit: limit,
                alert50: alert50Switch.isOn,
                alert75: alert75Switch.isOn,
                alert90: alert90Switch.isOn
            )
        } else {
            BudgetManager.shared.createBudget(
                name: resolvedName,
                category: resolvedCategory,
                limit: limit,
                month: Date(),
                alert50: alert50Switch.isOn,
                alert75: alert75Switch.isOn,
                alert90: alert90Switch.isOn
            )
        }
        
        dismiss(animated: true)
    }
}
