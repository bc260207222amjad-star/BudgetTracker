//
//  AddIncomeViewController.swift
//  BudgetTracker
//
//  Created by ali on 10/10/2026.
//

import UIKit
import CoreData

public class AddIncomeViewController: UIViewController {
    
    public var transactionToEdit: TransactionEntity?
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    private let currencySymbolLabel = UILabel()
    private let amountTextField = UITextField()
    
    private let categoryScrollView = UIScrollView()
    private let categoryStack = UIStackView()
    private var selectedCategoryName: String = "Salary"
    
    private let titleTextField = UITextField()
    private let datePicker = UIDatePicker()
    
    private let accountButton = UIButton(type: .system)
    private var selectedAccountId: UUID?
    
    private let noteTextView = UITextView()
    
    // Recurring Option
    private let recurringSwitch = UISwitch()
    private let frequencyButton = UIButton(type: .system)
    private var selectedFrequency: RecurringFrequency = .monthly
    
    private let saveButton = UIButton(type: .system)
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigation()
        setupUI()
        populateIfEditing()
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if transactionToEdit == nil {
            amountTextField.becomeFirstResponder()
        }
    }
    
    private func setupNavigation() {
        title = transactionToEdit != nil ? "Edit Income" : "Add Income"
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
        
        // Amount Container
        let amountContainer = CardView()
        amountContainer.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(amountContainer)
        
        currencySymbolLabel.text = CurrencyManager.shared.currentCurrency.symbol
        currencySymbolLabel.font = .systemFont(ofSize: 38, weight: .heavy)
        currencySymbolLabel.textColor = .systemGreen
        currencySymbolLabel.translatesAutoresizingMaskIntoConstraints = false
        amountContainer.addSubview(currencySymbolLabel)
        
        amountTextField.placeholder = "0.00"
        amountTextField.font = .systemFont(ofSize: 42, weight: .heavy)
        amountTextField.textColor = .systemGreen
        amountTextField.keyboardType = .decimalPad
        amountTextField.translatesAutoresizingMaskIntoConstraints = false
        amountContainer.addSubview(amountTextField)
        
        // Income Source Chips
        let categoryLabel = UILabel()
        categoryLabel.text = "Income Source"
        categoryLabel.font = .systemFont(ofSize: 15, weight: .bold)
        categoryLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(categoryLabel)
        
        categoryScrollView.showsHorizontalScrollIndicator = false
        categoryScrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(categoryScrollView)
        
        categoryStack.axis = .horizontal
        categoryStack.spacing = 8
        categoryStack.translatesAutoresizingMaskIntoConstraints = false
        categoryScrollView.addSubview(categoryStack)
        
        buildIncomeCategoryChips()
        
        // Details Card
        let fieldsCard = CardView()
        fieldsCard.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(fieldsCard)
        
        let fieldsStack = UIStackView()
        fieldsStack.axis = .vertical
        fieldsStack.spacing = 16
        fieldsStack.translatesAutoresizingMaskIntoConstraints = false
        fieldsCard.addSubview(fieldsStack)
        
        titleTextField.placeholder = "Source Title (e.g. Salary, Client Payout)"
        titleTextField.font = .systemFont(ofSize: 16)
        titleTextField.borderStyle = .roundedRect
        fieldsStack.addArrangedSubview(titleTextField)
        
        // Date & Time row
        let dateRow = UIStackView()
        dateRow.axis = .horizontal
        dateRow.distribution = .equalSpacing
        dateRow.alignment = .center
        
        let dateTitle = UILabel()
        dateTitle.text = "Date & Time"
        dateTitle.font = .systemFont(ofSize: 15, weight: .medium)
        dateRow.addArrangedSubview(dateTitle)
        
        datePicker.datePickerMode = .dateAndTime
        datePicker.preferredDatePickerStyle = .compact
        dateRow.addArrangedSubview(datePicker)
        fieldsStack.addArrangedSubview(dateRow)
        
        // Account row
        let accountRow = UIStackView()
        accountRow.axis = .horizontal
        accountRow.distribution = .equalSpacing
        accountRow.alignment = .center
        
        let accountTitle = UILabel()
        accountTitle.text = "Deposit Account"
        accountTitle.font = .systemFont(ofSize: 15, weight: .medium)
        accountRow.addArrangedSubview(accountTitle)
        
        setupAccountMenu()
        accountRow.addArrangedSubview(accountButton)
        fieldsStack.addArrangedSubview(accountRow)
        
        // Recurring Option Row
        let recurringCard = CardView()
        recurringCard.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(recurringCard)
        
        let recurringStack = UIStackView()
        recurringStack.axis = .vertical
        recurringStack.spacing = 12
        recurringStack.translatesAutoresizingMaskIntoConstraints = false
        recurringCard.addSubview(recurringStack)
        
        let recurringHeader = UIStackView()
        recurringHeader.axis = .horizontal
        recurringHeader.distribution = .equalSpacing
        recurringHeader.alignment = .center
        
        let recTitle = UILabel()
        recTitle.text = "Recurring Income"
        recTitle.font = .systemFont(ofSize: 15, weight: .semibold)
        recurringHeader.addArrangedSubview(recTitle)
        
        recurringSwitch.addTarget(self, action: #selector(recurringSwitchChanged), for: .valueChanged)
        recurringHeader.addArrangedSubview(recurringSwitch)
        recurringStack.addArrangedSubview(recurringHeader)
        
        let freqRow = UIStackView()
        freqRow.axis = .horizontal
        freqRow.distribution = .equalSpacing
        freqRow.alignment = .center
        
        let freqLabel = UILabel()
        freqLabel.text = "Repeat Frequency"
        freqLabel.font = .systemFont(ofSize: 14)
        freqLabel.textColor = .secondaryLabel
        freqRow.addArrangedSubview(freqLabel)
        
        setupFrequencyMenu()
        freqRow.addArrangedSubview(frequencyButton)
        recurringStack.addArrangedSubview(freqRow)
        
        // Note
        let noteLabel = UILabel()
        noteLabel.text = "Note"
        noteLabel.font = .systemFont(ofSize: 14, weight: .medium)
        noteLabel.textColor = .secondaryLabel
        fieldsStack.addArrangedSubview(noteLabel)
        
        noteTextView.font = .systemFont(ofSize: 15)
        noteTextView.layer.cornerRadius = 8
        noteTextView.layer.borderColor = UIColor.systemGray4.cgColor
        noteTextView.layer.borderWidth = 0.5
        noteTextView.heightAnchor.constraint(equalToConstant: 70).isActive = true
        fieldsStack.addArrangedSubview(noteTextView)
        
        // Save Button
        saveButton.setTitle("Save Income", for: .normal)
        saveButton.backgroundColor = .systemGreen
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .bold)
        saveButton.layer.cornerRadius = 14
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(saveButton)
        
        NSLayoutConstraint.activate([
            amountContainer.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            amountContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            amountContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            currencySymbolLabel.leadingAnchor.constraint(equalTo: amountContainer.leadingAnchor, constant: 20),
            currencySymbolLabel.centerYAnchor.constraint(equalTo: amountContainer.centerYAnchor),
            
            amountTextField.leadingAnchor.constraint(equalTo: currencySymbolLabel.trailingAnchor, constant: 8),
            amountTextField.trailingAnchor.constraint(equalTo: amountContainer.trailingAnchor, constant: -20),
            amountTextField.topAnchor.constraint(equalTo: amountContainer.topAnchor, constant: 18),
            amountTextField.bottomAnchor.constraint(equalTo: amountContainer.bottomAnchor, constant: -18),
            
            categoryLabel.topAnchor.constraint(equalTo: amountContainer.bottomAnchor, constant: 20),
            categoryLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 18),
            
            categoryScrollView.topAnchor.constraint(equalTo: categoryLabel.bottomAnchor, constant: 10),
            categoryScrollView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            categoryScrollView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            categoryScrollView.heightAnchor.constraint(equalToConstant: 44),
            
            categoryStack.topAnchor.constraint(equalTo: categoryScrollView.topAnchor),
            categoryStack.leadingAnchor.constraint(equalTo: categoryScrollView.leadingAnchor, constant: 16),
            categoryStack.trailingAnchor.constraint(equalTo: categoryScrollView.trailingAnchor, constant: -16),
            categoryStack.bottomAnchor.constraint(equalTo: categoryScrollView.bottomAnchor),
            categoryStack.heightAnchor.constraint(equalTo: categoryScrollView.heightAnchor),
            
            fieldsCard.topAnchor.constraint(equalTo: categoryScrollView.bottomAnchor, constant: 16),
            fieldsCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            fieldsCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            fieldsStack.topAnchor.constraint(equalTo: fieldsCard.topAnchor, constant: 16),
            fieldsStack.leadingAnchor.constraint(equalTo: fieldsCard.leadingAnchor, constant: 16),
            fieldsStack.trailingAnchor.constraint(equalTo: fieldsCard.trailingAnchor, constant: -16),
            fieldsStack.bottomAnchor.constraint(equalTo: fieldsCard.bottomAnchor, constant: -16),
            
            recurringCard.topAnchor.constraint(equalTo: fieldsCard.bottomAnchor, constant: 16),
            recurringCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            recurringCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            recurringStack.topAnchor.constraint(equalTo: recurringCard.topAnchor, constant: 14),
            recurringStack.leadingAnchor.constraint(equalTo: recurringCard.leadingAnchor, constant: 16),
            recurringStack.trailingAnchor.constraint(equalTo: recurringCard.trailingAnchor, constant: -16),
            recurringStack.bottomAnchor.constraint(equalTo: recurringCard.bottomAnchor, constant: -14),
            
            saveButton.topAnchor.constraint(equalTo: recurringCard.bottomAnchor, constant: 24),
            saveButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            saveButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            saveButton.heightAnchor.constraint(equalToConstant: 52),
            saveButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -30)
        ])
    }
    
    private func buildIncomeCategoryChips() {
        categoryStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let categories = CategoryManager.shared.getIncomeCategories()
        
        for cat in categories {
            let chip = UIButton(type: .system)
            chip.setTitle(" \(cat.name) ", for: .normal)
            chip.setImage(UIImage(systemName: cat.iconName), for: .normal)
            chip.tintColor = cat.color
            chip.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
            chip.layer.cornerRadius = 16
            chip.contentEdgeInsets = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)
            
            let isSelected = (cat.name.lowercased() == selectedCategoryName.lowercased())
            if isSelected {
                chip.backgroundColor = cat.color
                chip.tintColor = .white
                chip.setTitleColor(.white, for: .normal)
            } else {
                chip.backgroundColor = .secondarySystemBackground
                chip.tintColor = cat.color
                chip.setTitleColor(.label, for: .normal)
            }
            
            chip.addAction(UIAction { [weak self] _ in
                self?.selectedCategoryName = cat.name
                self?.buildIncomeCategoryChips()
            }, for: .touchUpInside)
            
            categoryStack.addArrangedSubview(chip)
        }
    }
    
    private func setupAccountMenu() {
        AccountManager.shared.ensureDefaultAccountsExist()
        let accounts = AccountManager.shared.fetchAccounts()
        if selectedAccountId == nil, let first = accounts.first {
            selectedAccountId = first.id
        }
        
        var actions: [UIAction] = []
        for acc in accounts {
            let act = UIAction(title: acc.name ?? "Account", state: acc.id == selectedAccountId ? .on : .off) { [weak self] _ in
                self?.selectedAccountId = acc.id
                self?.accountButton.setTitle(acc.name, for: .normal)
            }
            actions.append(act)
        }
        accountButton.menu = UIMenu(children: actions)
        accountButton.showsMenuAsPrimaryAction = true
        let initialAccName = accounts.first(where: { $0.id == selectedAccountId })?.name ?? "Select Account"
        accountButton.setTitle(initialAccName, for: .normal)
        accountButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
    }
    
    private func setupFrequencyMenu() {
        let actions = RecurringFrequency.allCases.map { freq in
            UIAction(title: freq.title, state: freq == selectedFrequency ? .on : .off) { [weak self] _ in
                self?.selectedFrequency = freq
                self?.frequencyButton.setTitle(freq.title, for: .normal)
            }
        }
        frequencyButton.menu = UIMenu(children: actions)
        frequencyButton.showsMenuAsPrimaryAction = true
        frequencyButton.setTitle(selectedFrequency.title, for: .normal)
        frequencyButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        frequencyButton.isEnabled = recurringSwitch.isOn
    }
    
    @objc private func recurringSwitchChanged() {
        frequencyButton.isEnabled = recurringSwitch.isOn
    }
    
    private func populateIfEditing() {
        guard let item = transactionToEdit else { return }
        amountTextField.text = String(format: "%.2f", item.amount)
        titleTextField.text = item.title
        selectedCategoryName = item.category ?? "Salary"
        buildIncomeCategoryChips()
        if let d = item.date { datePicker.date = d }
        selectedAccountId = item.accountId
        setupAccountMenu()
        noteTextView.text = item.note
        recurringSwitch.isOn = item.isRecurring
        frequencyButton.isEnabled = item.isRecurring
    }
    
    @objc private func cancelTapped() {
        dismiss(animated: true)
    }
    
    @objc private func saveTapped() {
        let amountText = (amountTextField.text ?? "").replacingOccurrences(of: ",", with: ".").trimmingCharacters(in: .whitespacesAndNewlines)
        guard let amount = Double(amountText), amount > 0 else {
            let alert = UIAlertController(title: "Invalid Amount", message: "Please enter an amount greater than 0.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        
        let title = (titleTextField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedTitle = title.isEmpty ? selectedCategoryName : title
        let note = noteTextView.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        let date = datePicker.date
        
        if let editingItem = transactionToEdit {
            TransactionManager.shared.updateTransaction(
                transaction: editingItem,
                title: resolvedTitle,
                amount: amount,
                type: .income,
                category: selectedCategoryName,
                merchant: resolvedTitle,
                note: note,
                date: date,
                paymentMethod: "Bank",
                receiptImagePath: nil,
                accountId: selectedAccountId
            )
        } else {
            TransactionManager.shared.createTransaction(
                title: resolvedTitle,
                amount: amount,
                type: .income,
                category: selectedCategoryName,
                merchant: resolvedTitle,
                note: note,
                date: date,
                paymentMethod: "Bank",
                isRecurring: recurringSwitch.isOn,
                recurringRule: recurringSwitch.isOn ? selectedFrequency.rawValue : nil,
                accountId: selectedAccountId
            )
            
            // If recurring is enabled, also create RecurringTransactionEntity
            if recurringSwitch.isOn {
                let context = CoreDataManager.shared.viewContext
                let recurring = RecurringTransactionEntity(context: context)
                recurring.id = UUID()
                recurring.title = resolvedTitle
                recurring.amount = amount
                recurring.type = "income"
                recurring.category = selectedCategoryName
                recurring.frequency = selectedFrequency.rawValue
                recurring.nextDate = selectedFrequency.nextOccurrence(from: date)
                recurring.isEnabled = true
                recurring.createdAt = Date()
                recurring.accountId = selectedAccountId
                CoreDataManager.shared.saveContext()
            }
        }
        
        dismiss(animated: true)
    }
}
