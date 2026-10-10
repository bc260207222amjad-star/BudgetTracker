//
//  AddExpenseViewController.swift
//  BudgetTracker
//
//  Created by ali on 10/10/2026.
//

import UIKit
import PhotosUI

public class AddExpenseViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, PHPickerViewControllerDelegate {
    
    public var shouldOpenReceiptScannerOnAppear: Bool = false
    public var transactionToEdit: TransactionEntity?
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    // Amount Hero Visual
    private let amountContainer = CardView()
    private let currencySymbolLabel = UILabel()
    private let amountTextField = UITextField()
    private let quickPresetsStack = UIStackView()
    
    // Category Chips
    private let categoryScrollView = UIScrollView()
    private let categoryStack = UIStackView()
    private var selectedCategoryName: String = "Food"
    
    // Details Fields
    private let titleTextField = UITextField()
    private let merchantTextField = UITextField()
    private let datePicker = UIDatePicker()
    private let paymentMethodButton = UIButton(type: .system)
    private var selectedPaymentMethod: String = "Cash"
    
    private let accountButton = UIButton(type: .system)
    private var selectedAccountId: UUID?
    
    private let noteTextView = UITextView()
    
    // Receipt Card
    private let receiptButton = UIButton(type: .system)
    private let receiptPreviewImageView = UIImageView()
    private var savedReceiptPath: String?
    
    // Save
    private let saveButton = UIButton(type: .system)
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigation()
        setupUI()
        populateIfEditing()
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if shouldOpenReceiptScannerOnAppear {
            shouldOpenReceiptScannerOnAppear = false
            presentReceiptSourceOptions()
        } else if transactionToEdit == nil {
            amountTextField.becomeFirstResponder()
        }
    }
    
    private func setupNavigation() {
        title = transactionToEdit != nil ? "Edit Expense" : "New Expense"
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
        
        // 1. Amount Hero Visual
        amountContainer.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(amountContainer)
        
        let amountStack = UIStackView()
        amountStack.axis = .vertical
        amountStack.spacing = 14
        amountStack.alignment = .center
        amountStack.translatesAutoresizingMaskIntoConstraints = false
        amountContainer.addSubview(amountStack)
        
        let amountInputRow = UIStackView()
        amountInputRow.axis = .horizontal
        amountInputRow.spacing = 8
        amountInputRow.alignment = .center
        
        currencySymbolLabel.text = CurrencyManager.shared.currentCurrency.symbol
        currencySymbolLabel.font = .systemFont(ofSize: 38, weight: .heavy)
        currencySymbolLabel.textColor = .systemRed
        amountInputRow.addArrangedSubview(currencySymbolLabel)
        
        amountTextField.placeholder = "0.00"
        amountTextField.font = .monospacedDigitSystemFont(ofSize: 44, weight: .heavy)
        amountTextField.textColor = .systemRed
        amountTextField.keyboardType = .decimalPad
        amountTextField.textAlignment = .left
        amountInputRow.addArrangedSubview(amountTextField)
        amountStack.addArrangedSubview(amountInputRow)
        
        // Quick Presets ($5, $10, $25, $50, $100)
        quickPresetsStack.axis = .horizontal
        quickPresetsStack.spacing = 8
        quickPresetsStack.distribution = .equalSpacing
        buildQuickPresetChips()
        amountStack.addArrangedSubview(quickPresetsStack)
        
        // 2. Category Selector Header
        let categoryHeader = UILabel()
        categoryHeader.text = "CATEGORY"
        categoryHeader.font = .systemFont(ofSize: 12, weight: .bold)
        categoryHeader.textColor = .secondaryLabel
        categoryHeader.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(categoryHeader)
        
        categoryScrollView.showsHorizontalScrollIndicator = false
        categoryScrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(categoryScrollView)
        
        categoryStack.axis = .horizontal
        categoryStack.spacing = 8
        categoryStack.translatesAutoresizingMaskIntoConstraints = false
        categoryScrollView.addSubview(categoryStack)
        buildCategoryChips()
        
        // 3. Form Card
        let fieldsCard = CardView()
        fieldsCard.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(fieldsCard)
        
        let fieldsStack = UIStackView()
        fieldsStack.axis = .vertical
        fieldsStack.spacing = 16
        fieldsStack.translatesAutoresizingMaskIntoConstraints = false
        fieldsCard.addSubview(fieldsStack)
        
        // Title field
        titleTextField.placeholder = "Title (e.g. Lunch with team)"
        titleTextField.font = .systemFont(ofSize: 16)
        titleTextField.borderStyle = .roundedRect
        fieldsStack.addArrangedSubview(titleTextField)
        
        // Merchant field
        merchantTextField.placeholder = "Merchant / Store (e.g. McDonald's, Trader Joe's)"
        merchantTextField.font = .systemFont(ofSize: 16)
        merchantTextField.borderStyle = .roundedRect
        fieldsStack.addArrangedSubview(merchantTextField)
        
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
        
        // Payment Method row
        let paymentRow = UIStackView()
        paymentRow.axis = .horizontal
        paymentRow.distribution = .equalSpacing
        paymentRow.alignment = .center
        
        let paymentTitle = UILabel()
        paymentTitle.text = "Payment Method"
        paymentTitle.font = .systemFont(ofSize: 15, weight: .medium)
        paymentRow.addArrangedSubview(paymentTitle)
        
        setupPaymentMethodMenu()
        paymentRow.addArrangedSubview(paymentMethodButton)
        fieldsStack.addArrangedSubview(paymentRow)
        
        // Account row
        let accountRow = UIStackView()
        accountRow.axis = .horizontal
        accountRow.distribution = .equalSpacing
        accountRow.alignment = .center
        
        let accountTitle = UILabel()
        accountTitle.text = "Account"
        accountTitle.font = .systemFont(ofSize: 15, weight: .medium)
        accountRow.addArrangedSubview(accountTitle)
        
        setupAccountMenu()
        accountRow.addArrangedSubview(accountButton)
        fieldsStack.addArrangedSubview(accountRow)
        
        // Note
        let noteLabel = UILabel()
        noteLabel.text = "Note"
        noteLabel.font = .systemFont(ofSize: 13, weight: .medium)
        noteLabel.textColor = .secondaryLabel
        fieldsStack.addArrangedSubview(noteLabel)
        
        noteTextView.font = .systemFont(ofSize: 15)
        noteTextView.layer.cornerRadius = 8
        noteTextView.layer.borderColor = UIColor.systemGray4.cgColor
        noteTextView.layer.borderWidth = 0.5
        noteTextView.heightAnchor.constraint(equalToConstant: 64).isActive = true
        fieldsStack.addArrangedSubview(noteTextView)
        
        // 4. Receipt Attachment Card
        let receiptCard = CardView()
        receiptCard.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(receiptCard)
        
        receiptButton.setTitle("Attach Receipt (Photo / OCR)", for: .normal)
        receiptButton.setImage(UIImage(systemName: "camera.fill"), for: .normal)
        receiptButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        receiptButton.addTarget(self, action: #selector(receiptButtonTapped), for: .touchUpInside)
        receiptButton.translatesAutoresizingMaskIntoConstraints = false
        receiptCard.addSubview(receiptButton)
        
        receiptPreviewImageView.contentMode = .scaleAspectFill
        receiptPreviewImageView.layer.cornerRadius = 10
        receiptPreviewImageView.layer.masksToBounds = true
        receiptPreviewImageView.isHidden = true
        receiptPreviewImageView.translatesAutoresizingMaskIntoConstraints = false
        receiptCard.addSubview(receiptPreviewImageView)
        
        // 5. Save Button
        saveButton.setTitle("Save Expense", for: .normal)
        saveButton.backgroundColor = .systemRed
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .bold)
        saveButton.layer.cornerRadius = 16
        saveButton.layer.cornerCurve = .continuous
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(saveButton)
        
        NSLayoutConstraint.activate([
            amountContainer.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            amountContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            amountContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            amountStack.topAnchor.constraint(equalTo: amountContainer.topAnchor, constant: 18),
            amountStack.leadingAnchor.constraint(equalTo: amountContainer.leadingAnchor, constant: 16),
            amountStack.trailingAnchor.constraint(equalTo: amountContainer.trailingAnchor, constant: -16),
            amountStack.bottomAnchor.constraint(equalTo: amountContainer.bottomAnchor, constant: -18),
            
            categoryHeader.topAnchor.constraint(equalTo: amountContainer.bottomAnchor, constant: 20),
            categoryHeader.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            categoryScrollView.topAnchor.constraint(equalTo: categoryHeader.bottomAnchor, constant: 10),
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
            
            receiptCard.topAnchor.constraint(equalTo: fieldsCard.bottomAnchor, constant: 16),
            receiptCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            receiptCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            receiptButton.topAnchor.constraint(equalTo: receiptCard.topAnchor, constant: 14),
            receiptButton.leadingAnchor.constraint(equalTo: receiptCard.leadingAnchor, constant: 16),
            receiptButton.trailingAnchor.constraint(equalTo: receiptCard.trailingAnchor, constant: -16),
            
            receiptPreviewImageView.topAnchor.constraint(equalTo: receiptButton.bottomAnchor, constant: 10),
            receiptPreviewImageView.centerXAnchor.constraint(equalTo: receiptCard.centerXAnchor),
            receiptPreviewImageView.widthAnchor.constraint(equalToConstant: 120),
            receiptPreviewImageView.heightAnchor.constraint(equalToConstant: 120),
            receiptPreviewImageView.bottomAnchor.constraint(equalTo: receiptCard.bottomAnchor, constant: -14),
            
            saveButton.topAnchor.constraint(equalTo: receiptCard.bottomAnchor, constant: 24),
            saveButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            saveButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            saveButton.heightAnchor.constraint(equalToConstant: 54),
            saveButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -32)
        ])
    }
    
    private func buildQuickPresetChips() {
        let presets = [5.0, 10.0, 25.0, 50.0, 100.0]
        for preset in presets {
            let chip = UIButton(type: .system)
            chip.setTitle("+\(Int(preset))", for: .normal)
            chip.titleLabel?.font = .systemFont(ofSize: 13, weight: .bold)
            chip.backgroundColor = UIColor.systemRed.withAlphaComponent(0.1)
            chip.setTitleColor(.systemRed, for: .normal)
            chip.layer.cornerRadius = 12
            chip.layer.cornerCurve = .continuous
            chip.contentEdgeInsets = UIEdgeInsets(top: 6, left: 10, bottom: 6, right: 10)
            chip.addAction(UIAction { [weak self] _ in
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                let cur = Double(self?.amountTextField.text?.replacingOccurrences(of: ",", with: ".") ?? "0") ?? 0
                let newTotal = cur + preset
                self?.amountTextField.text = String(format: "%.2f", newTotal)
            }, for: .touchUpInside)
            quickPresetsStack.addArrangedSubview(chip)
        }
    }
    
    private func buildCategoryChips() {
        categoryStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let categories = CategoryManager.shared.getExpenseCategories()
        
        for cat in categories {
            let chip = UIButton(type: .system)
            chip.setTitle(" \(cat.name) ", for: .normal)
            chip.setImage(UIImage(systemName: cat.iconName), for: .normal)
            chip.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
            chip.layer.cornerRadius = 16
            chip.layer.cornerCurve = .continuous
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
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                self?.selectedCategoryName = cat.name
                self?.buildCategoryChips()
            }, for: .touchUpInside)
            
            categoryStack.addArrangedSubview(chip)
        }
    }
    
    private func setupPaymentMethodMenu() {
        let methods = ["Cash", "Debit Card", "Credit Card", "Bank", "Digital Wallet", "Other"]
        let actions = methods.map { method in
            UIAction(title: method, state: method == selectedPaymentMethod ? .on : .off) { [weak self] _ in
                self?.selectedPaymentMethod = method
                self?.paymentMethodButton.setTitle(method, for: .normal)
            }
        }
        paymentMethodButton.menu = UIMenu(children: actions)
        paymentMethodButton.showsMenuAsPrimaryAction = true
        paymentMethodButton.setTitle(selectedPaymentMethod, for: .normal)
        paymentMethodButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
    }
    
    private func setupAccountMenu() {
        AccountManager.shared.ensureDefaultAccountsExist()
        let accounts = AccountManager.shared.fetchAccounts()
        if selectedAccountId == nil, let first = accounts.first {
            selectedAccountId = first.id
        }
        
        let actions = accounts.map { acc in
            UIAction(title: acc.name ?? "Account", state: acc.id == selectedAccountId ? .on : .off) { [weak self] _ in
                self?.selectedAccountId = acc.id
                self?.accountButton.setTitle(acc.name, for: .normal)
            }
        }
        accountButton.menu = UIMenu(children: actions)
        accountButton.showsMenuAsPrimaryAction = true
        let name = accounts.first(where: { $0.id == selectedAccountId })?.name ?? "Select Account"
        accountButton.setTitle(name, for: .normal)
        accountButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
    }
    
    private func populateIfEditing() {
        guard let item = transactionToEdit else { return }
        amountTextField.text = String(format: "%.2f", item.amount)
        titleTextField.text = item.title
        merchantTextField.text = item.merchant
        selectedCategoryName = item.category ?? "Food"
        buildCategoryChips()
        if let d = item.date { datePicker.date = d }
        if let pm = item.paymentMethod {
            selectedPaymentMethod = pm
            paymentMethodButton.setTitle(pm, for: .normal)
        }
        selectedAccountId = item.accountId
        setupAccountMenu()
        noteTextView.text = item.note
        
        if let path = item.receiptImagePath, FileManager.default.fileExists(atPath: path) {
            savedReceiptPath = path
            receiptPreviewImageView.image = ReceiptScannerManager.shared.loadThumbnail(from: path)
            receiptPreviewImageView.isHidden = false
            receiptButton.setTitle("Receipt Attached (Tap to change)", for: .normal)
        }
    }
    
    // MARK: - Receipt Scanner & Photos
    
    @objc private func receiptButtonTapped() {
        presentReceiptSourceOptions()
    }
    
    private func presentReceiptSourceOptions() {
        let sheet = UIAlertController(title: "Add Receipt", message: "Choose source to attach and OCR scan receipt:", preferredStyle: .actionSheet)
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            sheet.addAction(UIAlertAction(title: "Take Photo (Camera)", style: .default, handler: { [weak self] _ in
                let picker = UIImagePickerController()
                picker.sourceType = .camera
                picker.delegate = self
                self?.present(picker, animated: true)
            }))
        }
        sheet.addAction(UIAlertAction(title: "Choose from Photos", style: .default, handler: { [weak self] _ in
            guard let self = self else { return }
            var config = PHPickerConfiguration()
            config.filter = .images
            config.selectionLimit = 1
            let picker = PHPickerViewController(configuration: config)
            picker.delegate = self
            self.present(picker, animated: true)
        }))
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(sheet, animated: true)
    }
    
    public func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let provider = results.first?.itemProvider, provider.canLoadObject(ofClass: UIImage.self) else { return }
        provider.loadObject(ofClass: UIImage.self) { [weak self] image, _ in
            guard let uiImage = image as? UIImage else { return }
            DispatchQueue.main.async {
                self?.processReceiptImage(uiImage)
            }
        }
    }
    
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        if let image = info[.originalImage] as? UIImage {
            processReceiptImage(image)
        }
    }
    
    private func processReceiptImage(_ image: UIImage) {
        guard let savedPath = ReceiptScannerManager.shared.saveReceiptImage(image) else { return }
        self.savedReceiptPath = savedPath
        self.receiptPreviewImageView.image = image
        self.receiptPreviewImageView.isHidden = false
        self.receiptButton.setTitle("Receipt Attached (Tap to change)", for: .normal)
        
        ReceiptScannerManager.shared.scanReceiptImage(image) { [weak self] data in
            guard let self = self else { return }
            var parts: [String] = []
            if let m = data.merchant { parts.append("Merchant: \(m)") }
            if let a = data.amount { parts.append("Amount: \(CurrencyManager.shared.format(a))") }
            if let d = data.date {
                let df = DateFormatter()
                df.dateStyle = .medium
                parts.append("Date: \(df.string(from: d))")
            }
            guard !parts.isEmpty else { return }
            
            let alert = UIAlertController(title: "Receipt Scanned", message: "Extracted details:\n\n" + parts.joined(separator: "\n") + "\n\nAutofill these fields?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Apply", style: .default, handler: { _ in
                if let a = data.amount { self.amountTextField.text = String(format: "%.2f", a) }
                if let m = data.merchant {
                    self.merchantTextField.text = m
                    if self.titleTextField.text?.isEmpty == true { self.titleTextField.text = m }
                }
                if let d = data.date { self.datePicker.date = d }
            }))
            alert.addAction(UIAlertAction(title: "Keep Manual", style: .cancel))
            self.present(alert, animated: true)
        }
    }
    
    // MARK: - Save & Cancel
    
    @objc private func cancelTapped() {
        dismiss(animated: true)
    }
    
    @objc private func saveTapped() {
        let amountText = (amountTextField.text ?? "").replacingOccurrences(of: ",", with: ".").trimmingCharacters(in: .whitespacesAndNewlines)
        guard let amount = Double(amountText), amount > 0 else {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            let alert = UIAlertController(title: "Invalid Amount", message: "Please enter an amount greater than 0.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        let title = (titleTextField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedTitle = title.isEmpty ? (merchantTextField.text?.isEmpty == false ? merchantTextField.text! : selectedCategoryName) : title
        let merchant = merchantTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        let note = noteTextView.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        let date = datePicker.date
        
        if let editingItem = transactionToEdit {
            TransactionManager.shared.updateTransaction(
                transaction: editingItem,
                title: resolvedTitle,
                amount: amount,
                type: .expense,
                category: selectedCategoryName,
                merchant: merchant,
                note: note,
                date: date,
                paymentMethod: selectedPaymentMethod,
                receiptImagePath: savedReceiptPath,
                accountId: selectedAccountId
            )
        } else {
            TransactionManager.shared.createTransaction(
                title: resolvedTitle,
                amount: amount,
                type: .expense,
                category: selectedCategoryName,
                merchant: merchant,
                note: note,
                date: date,
                paymentMethod: selectedPaymentMethod,
                receiptImagePath: savedReceiptPath,
                accountId: selectedAccountId
            )
        }
        
        dismiss(animated: true)
    }
}
