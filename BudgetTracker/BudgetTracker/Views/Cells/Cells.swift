//
//  Cells.swift
//  BudgetTracker
//
//  Created by ali on 10/10/2026.
//

import UIKit

// MARK: - Transaction Cell

public class TransactionCell: UITableViewCell {
    public static let reuseIdentifier = "TransactionCell"
    
    private let iconContainer = UIView()
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let amountLabel = UILabel()
    private let dateLabel = UILabel()
    private let receiptIndicator = UIImageView()
    
    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }
    
    private func setupViews() {
        selectionStyle = .none
        backgroundColor = .clear
        
        iconContainer.layer.cornerRadius = 14
        iconContainer.layer.cornerCurve = .continuous
        iconContainer.layer.masksToBounds = true
        iconContainer.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(iconContainer)
        
        iconImageView.tintColor = .white
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconContainer.addSubview(iconImageView)
        
        let textStack = UIStackView()
        textStack.axis = .vertical
        textStack.spacing = 3
        textStack.alignment = .leading
        textStack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(textStack)
        
        let titleRow = UIStackView()
        titleRow.axis = .horizontal
        titleRow.spacing = 6
        titleRow.alignment = .center
        
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleRow.addArrangedSubview(titleLabel)
        
        receiptIndicator.image = UIImage(systemName: "paperclip")
        receiptIndicator.tintColor = .secondaryLabel
        receiptIndicator.contentMode = .scaleAspectFit
        receiptIndicator.isHidden = true
        receiptIndicator.translatesAutoresizingMaskIntoConstraints = false
        receiptIndicator.widthAnchor.constraint(equalToConstant: 12).isActive = true
        receiptIndicator.heightAnchor.constraint(equalToConstant: 12).isActive = true
        titleRow.addArrangedSubview(receiptIndicator)
        
        textStack.addArrangedSubview(titleRow)
        
        subtitleLabel.font = .systemFont(ofSize: 13, weight: .regular)
        subtitleLabel.textColor = .secondaryLabel
        textStack.addArrangedSubview(subtitleLabel)
        
        let amountStack = UIStackView()
        amountStack.axis = .vertical
        amountStack.spacing = 3
        amountStack.alignment = .trailing
        amountStack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(amountStack)
        
        amountLabel.font = .monospacedDigitSystemFont(ofSize: 16, weight: .bold)
        amountLabel.textAlignment = .right
        amountStack.addArrangedSubview(amountLabel)
        
        dateLabel.font = .systemFont(ofSize: 12, weight: .regular)
        dateLabel.textColor = .tertiaryLabel
        dateLabel.textAlignment = .right
        amountStack.addArrangedSubview(dateLabel)
        
        NSLayoutConstraint.activate([
            iconContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            iconContainer.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconContainer.widthAnchor.constraint(equalToConstant: 44),
            iconContainer.heightAnchor.constraint(equalToConstant: 44),
            
            iconImageView.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 22),
            iconImageView.heightAnchor.constraint(equalToConstant: 22),
            
            textStack.leadingAnchor.constraint(equalTo: iconContainer.trailingAnchor, constant: 14),
            textStack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            textStack.trailingAnchor.constraint(lessThanOrEqualTo: amountStack.leadingAnchor, constant: -12),
            
            amountStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            amountStack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 68)
        ])
    }
    
    public func configure(with item: TransactionEntity) {
        let colors = ThemeManager.shared.colors
        titleLabel.textColor = colors.text
        titleLabel.text = item.title ?? "Transaction"
        
        var subtitleParts: [String] = []
        if let merchant = item.merchant, !merchant.isEmpty {
            subtitleParts.append(merchant)
        }
        if let pm = item.paymentMethod, !pm.isEmpty {
            subtitleParts.append(pm)
        }
        if subtitleParts.isEmpty {
            subtitleParts.append(item.category ?? "General")
        }
        subtitleLabel.text = subtitleParts.joined(separator: " • ")
        
        let catItem = CategoryManager.shared.category(named: item.category ?? "")
        iconContainer.backgroundColor = catItem.color
        iconImageView.image = UIImage(systemName: catItem.iconName) ?? UIImage(systemName: "tag.fill")
        
        receiptIndicator.isHidden = (item.receiptImagePath == nil || item.receiptImagePath?.isEmpty == true)
        
        let isIncome = (item.type == TransactionType.income.rawValue)
        let isTransfer = (item.type == TransactionType.transfer.rawValue)
        
        if BiometricAuthManager.shared.hideTransactionAmounts {
            amountLabel.text = "••••••"
            amountLabel.textColor = colors.secondaryText
        } else {
            if isTransfer {
                amountLabel.text = CurrencyManager.shared.format(item.amount)
                amountLabel.textColor = colors.text
            } else if isIncome {
                amountLabel.text = CurrencyManager.shared.formatWithSign(item.amount, isIncome: true)
                amountLabel.textColor = colors.income
            } else {
                amountLabel.text = CurrencyManager.shared.formatWithSign(item.amount, isIncome: false)
                amountLabel.textColor = colors.expense
            }
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "h:mm a"
        if let d = item.date {
            dateLabel.text = dateFormatter.string(from: d)
        } else {
            dateLabel.text = ""
        }
    }
}

// MARK: - Budget Cell

public class BudgetCell: UITableViewCell {
    public static let reuseIdentifier = "BudgetCell"
    
    private let card = CardView()
    private let iconContainer = UIView()
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let statusBadge = UILabel()
    private let amountLabel = UILabel()
    private let progressBar = ProgressBarView()
    private let remainingLabel = UILabel()
    private let percentageLabel = UILabel()
    
    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }
    
    private func setupViews() {
        selectionStyle = .none
        backgroundColor = .clear
        
        card.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(card)
        
        let headerRow = UIStackView()
        headerRow.axis = .horizontal
        headerRow.alignment = .center
        headerRow.spacing = 10
        headerRow.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(headerRow)
        
        iconContainer.layer.cornerRadius = 12
        iconContainer.layer.cornerCurve = .continuous
        iconContainer.translatesAutoresizingMaskIntoConstraints = false
        iconContainer.widthAnchor.constraint(equalToConstant: 36).isActive = true
        iconContainer.heightAnchor.constraint(equalToConstant: 36).isActive = true
        
        iconImageView.tintColor = .white
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconContainer.addSubview(iconImageView)
        iconImageView.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor).isActive = true
        iconImageView.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor).isActive = true
        iconImageView.widthAnchor.constraint(equalToConstant: 18).isActive = true
        iconImageView.heightAnchor.constraint(equalToConstant: 18).isActive = true
        headerRow.addArrangedSubview(iconContainer)
        
        titleLabel.font = .systemFont(ofSize: 16, weight: .bold)
        titleLabel.textColor = .label
        headerRow.addArrangedSubview(titleLabel)
        
        let spacer = UIView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        headerRow.addArrangedSubview(spacer)
        
        statusBadge.font = .systemFont(ofSize: 11, weight: .bold)
        statusBadge.layer.cornerRadius = 8
        statusBadge.layer.cornerCurve = .continuous
        statusBadge.layer.masksToBounds = true
        statusBadge.textAlignment = .center
        statusBadge.translatesAutoresizingMaskIntoConstraints = false
        statusBadge.heightAnchor.constraint(equalToConstant: 22).isActive = true
        headerRow.addArrangedSubview(statusBadge)
        
        amountLabel.font = .monospacedDigitSystemFont(ofSize: 15, weight: .semibold)
        amountLabel.textColor = .label
        amountLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(amountLabel)
        
        progressBar.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(progressBar)
        
        let footerRow = UIStackView()
        footerRow.axis = .horizontal
        footerRow.distribution = .equalSpacing
        footerRow.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(footerRow)
        
        remainingLabel.font = .systemFont(ofSize: 13, weight: .regular)
        remainingLabel.textColor = .secondaryLabel
        footerRow.addArrangedSubview(remainingLabel)
        
        percentageLabel.font = .systemFont(ofSize: 13, weight: .bold)
        footerRow.addArrangedSubview(percentageLabel)
        
        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
            
            headerRow.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
            headerRow.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            headerRow.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            
            amountLabel.topAnchor.constraint(equalTo: headerRow.bottomAnchor, constant: 12),
            amountLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            amountLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            
            progressBar.topAnchor.constraint(equalTo: amountLabel.bottomAnchor, constant: 8),
            progressBar.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            progressBar.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            progressBar.heightAnchor.constraint(equalToConstant: 8),
            
            footerRow.topAnchor.constraint(equalTo: progressBar.bottomAnchor, constant: 8),
            footerRow.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            footerRow.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            footerRow.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -14)
        ])
    }
    
    public func configure(with status: BudgetStatus) {
        let colors = ThemeManager.shared.colors
        let currency = CurrencyManager.shared
        
        titleLabel.text = status.budget.name ?? "Budget"
        titleLabel.textColor = colors.text
        
        if status.budget.isOverall {
            iconContainer.backgroundColor = colors.primary
            iconImageView.image = UIImage(systemName: "chart.pie.fill")
        } else {
            let cat = status.budget.category ?? ""
            let catItem = CategoryManager.shared.category(named: cat)
            iconContainer.backgroundColor = catItem.color
            iconImageView.image = UIImage(systemName: catItem.iconName)
        }
        
        statusBadge.text = " \(status.level.label.uppercased()) "
        statusBadge.textColor = status.level.color
        statusBadge.backgroundColor = status.level.color.withAlphaComponent(0.14)
        
        amountLabel.text = "\(currency.format(status.usedAmount)) / \(currency.format(status.limitAmount))"
        amountLabel.textColor = colors.text
        
        progressBar.progress = status.percentage
        progressBar.progressColor = status.level.color
        
        remainingLabel.text = "\(currency.format(status.remainingAmount)) remaining"
        remainingLabel.textColor = colors.secondaryText
        
        let percentInt = Int(status.percentage * 100)
        percentageLabel.text = "\(percentInt)%"
        percentageLabel.textColor = status.level.color
    }
}

// MARK: - Upcoming Expense Cell (Calendar Day Tile Style)

public class UpcomingExpenseCell: UITableViewCell {
    public static let reuseIdentifier = "UpcomingExpenseCell"
    
    private let calendarTile = UIView()
    private let monthTileLabel = UILabel()
    private let dayTileLabel = UILabel()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let amountLabel = UILabel()
    
    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }
    
    private func setupViews() {
        selectionStyle = .none
        backgroundColor = .clear
        
        calendarTile.layer.cornerRadius = 12
        calendarTile.layer.cornerCurve = .continuous
        calendarTile.layer.masksToBounds = true
        calendarTile.backgroundColor = UIColor.systemRed.withAlphaComponent(0.12)
        calendarTile.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(calendarTile)
        
        let tileStack = UIStackView()
        tileStack.axis = .vertical
        tileStack.alignment = .center
        tileStack.spacing = 1
        tileStack.translatesAutoresizingMaskIntoConstraints = false
        calendarTile.addSubview(tileStack)
        
        monthTileLabel.font = .systemFont(ofSize: 10, weight: .heavy)
        monthTileLabel.textColor = .systemRed
        tileStack.addArrangedSubview(monthTileLabel)
        
        dayTileLabel.font = .systemFont(ofSize: 16, weight: .bold)
        dayTileLabel.textColor = .systemRed
        tileStack.addArrangedSubview(dayTileLabel)
        
        let textStack = UIStackView()
        textStack.axis = .vertical
        textStack.spacing = 2
        textStack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(textStack)
        
        titleLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        textStack.addArrangedSubview(titleLabel)
        
        subtitleLabel.font = .systemFont(ofSize: 13, weight: .regular)
        subtitleLabel.textColor = .secondaryLabel
        textStack.addArrangedSubview(subtitleLabel)
        
        amountLabel.font = .monospacedDigitSystemFont(ofSize: 15, weight: .bold)
        amountLabel.textColor = .systemRed
        amountLabel.textAlignment = .right
        amountLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(amountLabel)
        
        NSLayoutConstraint.activate([
            calendarTile.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            calendarTile.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            calendarTile.widthAnchor.constraint(equalToConstant: 44),
            calendarTile.heightAnchor.constraint(equalToConstant: 44),
            
            tileStack.centerXAnchor.constraint(equalTo: calendarTile.centerXAnchor),
            tileStack.centerYAnchor.constraint(equalTo: calendarTile.centerYAnchor),
            
            textStack.leadingAnchor.constraint(equalTo: calendarTile.trailingAnchor, constant: 14),
            textStack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            textStack.trailingAnchor.constraint(lessThanOrEqualTo: amountLabel.leadingAnchor, constant: -8),
            
            amountLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            amountLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 60)
        ])
    }
    
    public func configure(title: String, dueDate: Date, amount: Double) {
        let colors = ThemeManager.shared.colors
        titleLabel.text = title
        titleLabel.textColor = colors.text
        
        let monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "MMM"
        monthTileLabel.text = monthFormatter.string(from: dueDate).uppercased()
        
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "d"
        dayTileLabel.text = dayFormatter.string(from: dueDate)
        
        let fullDateFormatter = DateFormatter()
        fullDateFormatter.dateStyle = .medium
        subtitleLabel.text = "Due \(fullDateFormatter.string(from: dueDate))"
        
        amountLabel.text = "-\(CurrencyManager.shared.format(amount))"
        amountLabel.textColor = colors.expense
    }
}

// MARK: - Savings Goal Cell

public class SavingsGoalCell: UITableViewCell {
    public static let reuseIdentifier = "SavingsGoalCell"
    
    private let card = CardView()
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let progressLabel = UILabel()
    private let progressBar = ProgressBarView()
    private let savedVsTargetLabel = UILabel()
    private let remainingLabel = UILabel()
    
    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }
    
    private func setupViews() {
        selectionStyle = .none
        backgroundColor = .clear
        
        card.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(card)
        
        let header = UIStackView()
        header.axis = .horizontal
        header.alignment = .center
        header.spacing = 10
        header.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(header)
        
        iconImageView.tintColor = .systemYellow
        iconImageView.image = UIImage(systemName: "star.fill")
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.widthAnchor.constraint(equalToConstant: 22).isActive = true
        iconImageView.heightAnchor.constraint(equalToConstant: 22).isActive = true
        header.addArrangedSubview(iconImageView)
        
        titleLabel.font = .systemFont(ofSize: 16, weight: .bold)
        titleLabel.textColor = .label
        header.addArrangedSubview(titleLabel)
        
        progressLabel.font = .systemFont(ofSize: 14, weight: .bold)
        progressLabel.textColor = .systemBlue
        progressLabel.textAlignment = .right
        header.addArrangedSubview(progressLabel)
        
        savedVsTargetLabel.font = .monospacedDigitSystemFont(ofSize: 14, weight: .semibold)
        savedVsTargetLabel.textColor = .label
        savedVsTargetLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(savedVsTargetLabel)
        
        progressBar.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(progressBar)
        
        remainingLabel.font = .systemFont(ofSize: 13, weight: .regular)
        remainingLabel.textColor = .secondaryLabel
        remainingLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(remainingLabel)
        
        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
            
            header.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
            header.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            header.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            
            savedVsTargetLabel.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 10),
            savedVsTargetLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            savedVsTargetLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            
            progressBar.topAnchor.constraint(equalTo: savedVsTargetLabel.bottomAnchor, constant: 8),
            progressBar.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            progressBar.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            progressBar.heightAnchor.constraint(equalToConstant: 8),
            
            remainingLabel.topAnchor.constraint(equalTo: progressBar.bottomAnchor, constant: 8),
            remainingLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            remainingLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            remainingLabel.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -14)
        ])
    }
    
    public func configure(with goal: SavingsGoalEntity) {
        let colors = ThemeManager.shared.colors
        let currency = CurrencyManager.shared
        
        titleLabel.text = goal.name ?? "Goal"
        titleLabel.textColor = colors.text
        
        let percentInt = Int(goal.progressPercentage * 100)
        progressLabel.text = "\(percentInt)%"
        progressLabel.textColor = colors.primary
        
        savedVsTargetLabel.text = "\(currency.format(goal.currentAmount)) / \(currency.format(goal.targetAmount))"
        savedVsTargetLabel.textColor = colors.text
        
        progressBar.progress = goal.progressPercentage
        progressBar.progressColor = colors.primary
        
        var remText = "\(currency.format(goal.remainingAmount)) remaining"
        if let deadline = goal.deadline {
            let df = DateFormatter()
            df.dateFormat = "MMM d, yyyy"
            remText += " • Due \(df.string(from: deadline))"
        }
        remainingLabel.text = remText
        remainingLabel.textColor = colors.secondaryText
    }
}
