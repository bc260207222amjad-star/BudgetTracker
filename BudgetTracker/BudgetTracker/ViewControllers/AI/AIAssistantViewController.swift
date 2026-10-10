//
//  AIAssistantViewController.swift
//  BudgetTracker
//
//  Created by ali on 10/10/2026.
//

import UIKit

public struct ChatMessage {
    public let text: String
    public let isUser: Bool
    public let proposedTransaction: ProposedTransaction?
}

public class AIAssistantViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate {
    
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let inputContainer = UIView()
    private let inputTextField = UITextField()
    private let sendButton = UIButton(type: .system)
    
    private let suggestionsScrollView = UIScrollView()
    private let suggestionsStack = UIStackView()
    
    private var messages: [ChatMessage] = []
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigation()
        setupUI()
        setupInitialWelcomeMessage()
    }
    
    private func setupNavigation() {
        title = "AI Financial Assistant"
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(closeTapped))
    }
    
    private func setupUI() {
        view.backgroundColor = ThemeManager.shared.colors.background
        
        // Quick Prompt Suggestions
        suggestionsScrollView.showsHorizontalScrollIndicator = false
        suggestionsScrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(suggestionsScrollView)
        
        suggestionsStack.axis = .horizontal
        suggestionsStack.spacing = 8
        suggestionsStack.translatesAutoresizingMaskIntoConstraints = false
        suggestionsScrollView.addSubview(suggestionsStack)
        
        buildSuggestionsChips()
        
        // TableView
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.keyboardDismissMode = .interactive
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        
        // Input bar
        inputContainer.backgroundColor = ThemeManager.shared.colors.card
        inputContainer.layer.borderWidth = 0.5
        inputContainer.layer.borderColor = ThemeManager.shared.colors.separator.cgColor
        inputContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(inputContainer)
        
        inputTextField.placeholder = "Ask a question or type 'Spent $25 on lunch'..."
        inputTextField.font = .systemFont(ofSize: 15)
        inputTextField.delegate = self
        inputTextField.returnKeyType = .send
        inputTextField.translatesAutoresizingMaskIntoConstraints = false
        inputContainer.addSubview(inputTextField)
        
        sendButton.setImage(UIImage(systemName: "arrow.up.circle.fill"), for: .normal)
        sendButton.tintColor = .systemBlue
        sendButton.contentMode = .scaleAspectFit
        sendButton.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        inputContainer.addSubview(sendButton)
        
        NSLayoutConstraint.activate([
            suggestionsScrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 6),
            suggestionsScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            suggestionsScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            suggestionsScrollView.heightAnchor.constraint(equalToConstant: 40),
            
            suggestionsStack.topAnchor.constraint(equalTo: suggestionsScrollView.topAnchor),
            suggestionsStack.leadingAnchor.constraint(equalTo: suggestionsScrollView.leadingAnchor, constant: 16),
            suggestionsStack.trailingAnchor.constraint(equalTo: suggestionsScrollView.trailingAnchor, constant: -16),
            suggestionsStack.bottomAnchor.constraint(equalTo: suggestionsScrollView.bottomAnchor),
            suggestionsStack.heightAnchor.constraint(equalTo: suggestionsScrollView.heightAnchor),
            
            tableView.topAnchor.constraint(equalTo: suggestionsScrollView.bottomAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: inputContainer.topAnchor),
            
            inputContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            inputContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            inputContainer.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor),
            inputContainer.heightAnchor.constraint(equalToConstant: 60),
            
            inputTextField.leadingAnchor.constraint(equalTo: inputContainer.leadingAnchor, constant: 16),
            inputTextField.centerYAnchor.constraint(equalTo: inputContainer.centerYAnchor),
            inputTextField.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -8),
            
            sendButton.trailingAnchor.constraint(equalTo: inputContainer.trailingAnchor, constant: -16),
            sendButton.centerYAnchor.constraint(equalTo: inputContainer.centerYAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 36),
            sendButton.heightAnchor.constraint(equalToConstant: 36)
        ])
    }
    
    private func setupInitialWelcomeMessage() {
        let welcome = "Hello! I am your privacy-first AI budgeting assistant. All calculations run strictly on your device.\n\nAsk me about your expenses, savings, budget limits, or type a natural transaction like:\n• 'Spent $25 on lunch today'\n• 'Where did I spend the most?'\n• 'Can I afford a $500 purchase?'\n\n\(AIAssistantService.disclaimer)"
        messages.append(ChatMessage(text: welcome, isUser: false, proposedTransaction: nil))
        tableView.reloadData()
    }
    
    private func buildSuggestionsChips() {
        let suggestions = [
            "Where did I spend the most this month?",
            "How much did I spend on food?",
            "Can I afford a $500 purchase?",
            "How much did I save this month?",
            "Where am I overspending?"
        ]
        
        for q in suggestions {
            let chip = UIButton(type: .system)
            chip.setTitle(" \(q) ", for: .normal)
            chip.titleLabel?.font = .systemFont(ofSize: 13, weight: .medium)
            chip.backgroundColor = .secondarySystemBackground
            chip.setTitleColor(.label, for: .normal)
            chip.layer.cornerRadius = 14
            chip.contentEdgeInsets = UIEdgeInsets(top: 6, left: 10, bottom: 6, right: 10)
            chip.addAction(UIAction { [weak self] _ in
                self?.handleUserQuery(q)
            }, for: .touchUpInside)
            suggestionsStack.addArrangedSubview(chip)
        }
    }
    
    // MARK: - Message Handling
    
    @objc private func sendTapped() {
        guard let text = inputTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else { return }
        inputTextField.text = ""
        handleUserQuery(text)
    }
    
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        sendTapped()
        return true
    }
    
    private func handleUserQuery(_ query: String) {
        messages.append(ChatMessage(text: query, isUser: true, proposedTransaction: nil))
        tableView.reloadData()
        scrollToBottom()
        
        // Check if query is a natural language transaction
        if let proposed = AIAssistantService.shared.parseExpense(text: query) {
            let reply = "I parsed this expense from your request. Please review and confirm before saving:"
            messages.append(ChatMessage(text: reply, isUser: false, proposedTransaction: proposed))
        } else {
            let answer = AIAssistantService.shared.answerQuery(text: query)
            messages.append(ChatMessage(text: answer, isUser: false, proposedTransaction: nil))
        }
        
        tableView.reloadData()
        scrollToBottom()
    }
    
    private func scrollToBottom() {
        guard !messages.isEmpty else { return }
        let ip = IndexPath(row: messages.count - 1, section: 0)
        tableView.scrollToRow(at: ip, at: .bottom, animated: true)
    }
    
    // MARK: - TableView
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let msg = messages[indexPath.row]
        let cell = UITableViewCell(style: .default, reuseIdentifier: "ChatCell")
        cell.backgroundColor = .clear
        cell.selectionStyle = .none
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }
        
        let container = UIView()
        container.layer.cornerRadius = 16
        container.translatesAutoresizingMaskIntoConstraints = false
        cell.contentView.addSubview(container)
        
        let label = UILabel()
        label.text = msg.text
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 15)
        label.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(label)
        
        if msg.isUser {
            container.backgroundColor = .systemBlue
            label.textColor = .white
            
            NSLayoutConstraint.activate([
                container.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -16),
                container.leadingAnchor.constraint(greaterThanOrEqualTo: cell.contentView.leadingAnchor, constant: 64),
                container.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 6),
                container.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -6),
                
                label.topAnchor.constraint(equalTo: container.topAnchor, constant: 10),
                label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 14),
                label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -14),
                label.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -10)
            ])
        } else {
            container.backgroundColor = ThemeManager.shared.colors.card
            label.textColor = ThemeManager.shared.colors.text
            
            if let proposed = msg.proposedTransaction {
                let card = buildProposedTransactionCard(proposed: proposed, index: indexPath.row)
                card.translatesAutoresizingMaskIntoConstraints = false
                container.addSubview(card)
                
                NSLayoutConstraint.activate([
                    container.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 16),
                    container.trailingAnchor.constraint(lessThanOrEqualTo: cell.contentView.trailingAnchor, constant: -40),
                    container.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 6),
                    container.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -6),
                    
                    label.topAnchor.constraint(equalTo: container.topAnchor, constant: 10),
                    label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 14),
                    label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -14),
                    
                    card.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 10),
                    card.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 14),
                    card.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -14),
                    card.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -12)
                ])
            } else {
                NSLayoutConstraint.activate([
                    container.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 16),
                    container.trailingAnchor.constraint(lessThanOrEqualTo: cell.contentView.trailingAnchor, constant: -48),
                    container.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 6),
                    container.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -6),
                    
                    label.topAnchor.constraint(equalTo: container.topAnchor, constant: 10),
                    label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 14),
                    label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -14),
                    label.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -10)
                ])
            }
        }
        
        return cell
    }
    
    private func buildProposedTransactionCard(proposed: ProposedTransaction, index: Int) -> UIView {
        let card = CardView()
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)
        
        let titleLbl = UILabel()
        titleLbl.text = "PROPOSED EXPENSE"
        titleLbl.font = .systemFont(ofSize: 11, weight: .bold)
        titleLbl.textColor = .secondaryLabel
        stack.addArrangedSubview(titleLbl)
        
        let detailsLbl = UILabel()
        detailsLbl.text = "• Amount: \(CurrencyManager.shared.format(proposed.amount))\n• Title: \(proposed.title)\n• Category: \(proposed.category)\n• Payment: \(proposed.paymentMethod)"
        detailsLbl.numberOfLines = 0
        detailsLbl.font = .systemFont(ofSize: 14, weight: .medium)
        stack.addArrangedSubview(detailsLbl)
        
        let btnRow = UIStackView()
        btnRow.axis = .horizontal
        btnRow.spacing = 8
        btnRow.distribution = .fillEqually
        
        let confirmBtn = UIButton(type: .system)
        confirmBtn.setTitle("Confirm & Save", for: .normal)
        confirmBtn.backgroundColor = .systemGreen
        confirmBtn.setTitleColor(.white, for: .normal)
        confirmBtn.layer.cornerRadius = 8
        confirmBtn.titleLabel?.font = .systemFont(ofSize: 13, weight: .bold)
        confirmBtn.addAction(UIAction { [weak self] _ in
            self?.confirmProposedTransaction(proposed)
        }, for: .touchUpInside)
        btnRow.addArrangedSubview(confirmBtn)
        
        let editBtn = UIButton(type: .system)
        editBtn.setTitle("Edit", for: .normal)
        editBtn.backgroundColor = .systemBlue
        editBtn.setTitleColor(.white, for: .normal)
        editBtn.layer.cornerRadius = 8
        editBtn.titleLabel?.font = .systemFont(ofSize: 13, weight: .semibold)
        editBtn.addAction(UIAction { [weak self] _ in
            self?.editProposedTransaction(proposed)
        }, for: .touchUpInside)
        btnRow.addArrangedSubview(editBtn)
        
        stack.addArrangedSubview(btnRow)
        
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 10),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 10),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -10),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -10)
        ])
        
        return card
    }
    
    private func confirmProposedTransaction(_ proposed: ProposedTransaction) {
        TransactionManager.shared.createTransaction(
            title: proposed.title,
            amount: proposed.amount,
            type: proposed.type,
            category: proposed.category,
            merchant: proposed.title,
            note: "Created via AI Assistant",
            date: proposed.date,
            paymentMethod: proposed.paymentMethod
        )
        
        messages.append(ChatMessage(
            text: "✅ Transaction '\(proposed.title)' (\(CurrencyManager.shared.format(proposed.amount))) successfully saved to your records!",
            isUser: false,
            proposedTransaction: nil
        ))
        tableView.reloadData()
        scrollToBottom()
    }
    
    private func editProposedTransaction(_ proposed: ProposedTransaction) {
        let addVC = AddExpenseViewController()
        let nav = UINavigationController(rootViewController: addVC)
        present(nav, animated: true)
    }
    
    @objc private func closeTapped() {
        dismiss(animated: true)
    }
}
