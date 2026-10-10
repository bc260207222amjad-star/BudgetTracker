//
//  TransactionDetailViewController.swift
//  BudgetTracker
//
//  Created by ali on 10/10/2026.
//

import UIKit

public class TransactionDetailViewController: UIViewController {
    
    public var transaction: TransactionEntity
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    private let amountLabel = UILabel()
    private let typeBadge = UILabel()
    private let categoryImageView = UIImageView()
    private let detailsCard = CardView()
    private let detailsStack = UIStackView()
    
    private let receiptCard = CardView()
    private let receiptImageView = UIImageView()
    
    private let editButton = UIButton(type: .system)
    private let deleteButton = UIButton(type: .system)
    
    public init(transaction: TransactionEntity) {
        self.transaction = transaction
        super.init(nibName: nil, bundle: nil)
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigation()
        setupUI()
        populateData()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        populateData()
    }
    
    private func setupNavigation() {
        title = "Transaction Details"
        navigationItem.largeTitleDisplayMode = .never
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
        
        // Header Area
        let headerCard = CardView()
        headerCard.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(headerCard)
        
        categoryImageView.contentMode = .scaleAspectFit
        categoryImageView.tintColor = .white
        categoryImageView.layer.cornerRadius = 28
        categoryImageView.layer.masksToBounds = true
        categoryImageView.translatesAutoresizingMaskIntoConstraints = false
        headerCard.addSubview(categoryImageView)
        
        amountLabel.font = .systemFont(ofSize: 36, weight: .heavy)
        amountLabel.textAlignment = .center
        amountLabel.translatesAutoresizingMaskIntoConstraints = false
        headerCard.addSubview(amountLabel)
        
        typeBadge.font = .systemFont(ofSize: 13, weight: .bold)
        typeBadge.textAlignment = .center
        typeBadge.layer.cornerRadius = 8
        typeBadge.layer.masksToBounds = true
        typeBadge.translatesAutoresizingMaskIntoConstraints = false
        headerCard.addSubview(typeBadge)
        
        // Details Card
        detailsCard.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(detailsCard)
        
        detailsStack.axis = .vertical
        detailsStack.spacing = 14
        detailsStack.translatesAutoresizingMaskIntoConstraints = false
        detailsCard.addSubview(detailsStack)
        
        // Receipt Card
        receiptCard.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(receiptCard)
        
        let receiptTitle = UILabel()
        receiptTitle.text = "Attached Receipt"
        receiptTitle.font = .systemFont(ofSize: 15, weight: .bold)
        receiptTitle.translatesAutoresizingMaskIntoConstraints = false
        receiptCard.addSubview(receiptTitle)
        
        receiptImageView.contentMode = .scaleAspectFill
        receiptImageView.layer.cornerRadius = 10
        receiptImageView.layer.masksToBounds = true
        receiptImageView.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(receiptImageTapped))
        receiptImageView.addGestureRecognizer(tap)
        receiptImageView.translatesAutoresizingMaskIntoConstraints = false
        receiptCard.addSubview(receiptImageView)
        
        // Buttons
        let buttonStack = UIStackView()
        buttonStack.axis = .horizontal
        buttonStack.spacing = 14
        buttonStack.distribution = .fillEqually
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(buttonStack)
        
        editButton.setTitle("Edit", for: .normal)
        editButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        editButton.backgroundColor = .systemBlue
        editButton.setTitleColor(.white, for: .normal)
        editButton.layer.cornerRadius = 12
        editButton.addTarget(self, action: #selector(editTapped), for: .touchUpInside)
        buttonStack.addArrangedSubview(editButton)
        
        deleteButton.setTitle("Delete", for: .normal)
        deleteButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        deleteButton.backgroundColor = .systemRed.withAlphaComponent(0.12)
        deleteButton.setTitleColor(.systemRed, for: .normal)
        deleteButton.layer.cornerRadius = 12
        deleteButton.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)
        buttonStack.addArrangedSubview(deleteButton)
        
        NSLayoutConstraint.activate([
            headerCard.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            headerCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            headerCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            categoryImageView.topAnchor.constraint(equalTo: headerCard.topAnchor, constant: 20),
            categoryImageView.centerXAnchor.constraint(equalTo: headerCard.centerXAnchor),
            categoryImageView.widthAnchor.constraint(equalToConstant: 56),
            categoryImageView.heightAnchor.constraint(equalToConstant: 56),
            
            amountLabel.topAnchor.constraint(equalTo: categoryImageView.bottomAnchor, constant: 12),
            amountLabel.leadingAnchor.constraint(equalTo: headerCard.leadingAnchor, constant: 16),
            amountLabel.trailingAnchor.constraint(equalTo: headerCard.trailingAnchor, constant: -16),
            
            typeBadge.topAnchor.constraint(equalTo: amountLabel.bottomAnchor, constant: 8),
            typeBadge.centerXAnchor.constraint(equalTo: headerCard.centerXAnchor),
            typeBadge.widthAnchor.constraint(equalToConstant: 90),
            typeBadge.heightAnchor.constraint(equalToConstant: 26),
            typeBadge.bottomAnchor.constraint(equalTo: headerCard.bottomAnchor, constant: -20),
            
            detailsCard.topAnchor.constraint(equalTo: headerCard.bottomAnchor, constant: 16),
            detailsCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            detailsCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            detailsStack.topAnchor.constraint(equalTo: detailsCard.topAnchor, constant: 16),
            detailsStack.leadingAnchor.constraint(equalTo: detailsCard.leadingAnchor, constant: 16),
            detailsStack.trailingAnchor.constraint(equalTo: detailsCard.trailingAnchor, constant: -16),
            detailsStack.bottomAnchor.constraint(equalTo: detailsCard.bottomAnchor, constant: -16),
            
            receiptCard.topAnchor.constraint(equalTo: detailsCard.bottomAnchor, constant: 16),
            receiptCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            receiptCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            receiptTitle.topAnchor.constraint(equalTo: receiptCard.topAnchor, constant: 14),
            receiptTitle.leadingAnchor.constraint(equalTo: receiptCard.leadingAnchor, constant: 16),
            
            receiptImageView.topAnchor.constraint(equalTo: receiptTitle.bottomAnchor, constant: 12),
            receiptImageView.leadingAnchor.constraint(equalTo: receiptCard.leadingAnchor, constant: 16),
            receiptImageView.trailingAnchor.constraint(equalTo: receiptCard.trailingAnchor, constant: -16),
            receiptImageView.heightAnchor.constraint(equalToConstant: 220),
            receiptImageView.bottomAnchor.constraint(equalTo: receiptCard.bottomAnchor, constant: -16),
            
            buttonStack.topAnchor.constraint(equalTo: receiptCard.bottomAnchor, constant: 24),
            buttonStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            buttonStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            buttonStack.heightAnchor.constraint(equalToConstant: 48),
            buttonStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -30)
        ])
    }
    
    private func populateData() {
        let colors = ThemeManager.shared.colors
        let currency = CurrencyManager.shared
        
        let isIncome = (transaction.type == TransactionType.income.rawValue)
        let isTransfer = (transaction.type == TransactionType.transfer.rawValue)
        
        if isTransfer {
            amountLabel.text = currency.format(transaction.amount)
            amountLabel.textColor = colors.text
            typeBadge.text = "TRANSFER"
            typeBadge.backgroundColor = .systemGray5
            typeBadge.textColor = .secondaryLabel
        } else if isIncome {
            amountLabel.text = currency.formatWithSign(transaction.amount, isIncome: true)
            amountLabel.textColor = colors.income
            typeBadge.text = "INCOME"
            typeBadge.backgroundColor = colors.income.withAlphaComponent(0.15)
            typeBadge.textColor = colors.income
        } else {
            amountLabel.text = currency.formatWithSign(transaction.amount, isIncome: false)
            amountLabel.textColor = colors.expense
            typeBadge.text = "EXPENSE"
            typeBadge.backgroundColor = colors.expense.withAlphaComponent(0.15)
            typeBadge.textColor = colors.expense
        }
        
        let catItem = CategoryManager.shared.category(named: transaction.category ?? "")
        categoryImageView.backgroundColor = catItem.color
        categoryImageView.image = UIImage(systemName: catItem.iconName)
        
        detailsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        addDetailRow(title: "Title", value: transaction.title ?? "Transaction")
        addDetailRow(title: "Category", value: transaction.category ?? "General")
        if let m = transaction.merchant, !m.isEmpty {
            addDetailRow(title: "Merchant", value: m)
        }
        
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short
        if let d = transaction.date {
            addDetailRow(title: "Date & Time", value: df.string(from: d))
        }
        
        if let pm = transaction.paymentMethod, !pm.isEmpty {
            addDetailRow(title: "Payment Method", value: pm)
        }
        
        if let accId = transaction.accountId, let acc = AccountManager.shared.getAccount(byId: accId) {
            addDetailRow(title: "Account", value: acc.name ?? "Account")
        }
        
        if let note = transaction.note, !note.isEmpty {
            addDetailRow(title: "Note", value: note)
        }
        
        // Receipt image
        if let path = transaction.receiptImagePath, FileManager.default.fileExists(atPath: path),
           let img = UIImage(contentsOfFile: path) {
            receiptCard.isHidden = false
            receiptImageView.image = img
        } else {
            receiptCard.isHidden = true
        }
    }
    
    private func addDetailRow(title: String, value: String) {
        let row = UIStackView()
        row.axis = .horizontal
        row.distribution = .equalSpacing
        row.alignment = .top
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 14, weight: .regular)
        titleLabel.textColor = .secondaryLabel
        row.addArrangedSubview(titleLabel)
        
        let valLabel = UILabel()
        valLabel.text = value
        valLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        valLabel.textColor = .label
        valLabel.textAlignment = .right
        valLabel.numberOfLines = 0
        row.addArrangedSubview(valLabel)
        
        detailsStack.addArrangedSubview(row)
    }
    
    @objc private func receiptImageTapped() {
        guard let img = receiptImageView.image else { return }
        let viewerVC = UIViewController()
        viewerVC.view.backgroundColor = .black
        let fullImageView = UIImageView(image: img)
        fullImageView.contentMode = .scaleAspectFit
        fullImageView.frame = viewerVC.view.bounds
        fullImageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        viewerVC.view.addSubview(fullImageView)
        viewerVC.modalPresentationStyle = .fullScreen
        
        let closeBtn = UIButton(type: .system)
        closeBtn.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        closeBtn.tintColor = .white
        closeBtn.frame = CGRect(x: 20, y: 50, width: 44, height: 44)
        closeBtn.addAction(UIAction { [weak viewerVC] _ in
            viewerVC?.dismiss(animated: true)
        }, for: .touchUpInside)
        viewerVC.view.addSubview(closeBtn)
        
        present(viewerVC, animated: true)
    }
    
    @objc private func editTapped() {
        if transaction.type == TransactionType.income.rawValue {
            let editVC = AddIncomeViewController()
            editVC.transactionToEdit = transaction
            let nav = UINavigationController(rootViewController: editVC)
            present(nav, animated: true)
        } else {
            let editVC = AddExpenseViewController()
            editVC.transactionToEdit = transaction
            let nav = UINavigationController(rootViewController: editVC)
            present(nav, animated: true)
        }
    }
    
    @objc private func deleteTapped() {
        let alert = UIAlertController(title: "Delete Transaction", message: "Are you sure you want to delete this transaction? This action cannot be undone.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { [weak self] _ in
            guard let self = self else { return }
            TransactionManager.shared.deleteTransaction(self.transaction)
            self.navigationController?.popViewController(animated: true)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
}
