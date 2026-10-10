//
//  CommonViews.swift
//  BudgetTracker
//
//  Created by ali on 10/10/2026.
//

import UIKit

// MARK: - Refined Card View

public class CardView: UIView {
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupCard()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupCard()
    }
    
    private func setupCard() {
        layer.cornerRadius = 18
        layer.cornerCurve = .continuous
        layer.masksToBounds = false
        
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.05
        layer.shadowOffset = CGSize(width: 0, height: 4)
        layer.shadowRadius = 10
        
        applyTheme()
        NotificationCenter.default.addObserver(self, selector: #selector(applyTheme), name: .themeDidChange, object: nil)
    }
    
    @objc public func applyTheme() {
        backgroundColor = ThemeManager.shared.colors.card
        layer.borderColor = ThemeManager.shared.colors.separator.withAlphaComponent(0.35).cgColor
        layer.borderWidth = 0.75
    }
}

// MARK: - Hero Balance Card (Modern Financial Style)

public class HeroBalanceCard: UIView {
    private let titleLabel = UILabel()
    private let balanceLabel = UILabel()
    private let toggleEyeButton = UIButton(type: .system)
    private let cashFlowBadge = UIView()
    private let cashFlowLabel = UILabel()
    
    private let incomeMetricContainer = UIView()
    private let incomeAmountLabel = UILabel()
    
    private let expenseMetricContainer = UIView()
    private let expenseAmountLabel = UILabel()
    
    public var onToggleVisibility: (() -> Void)?
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        layer.cornerRadius = 24
        layer.cornerCurve = .continuous
        layer.masksToBounds = true
        
        // Subtle gradient background
        backgroundColor = ThemeManager.shared.colors.card
        layer.borderColor = ThemeManager.shared.colors.separator.withAlphaComponent(0.35).cgColor
        layer.borderWidth = 0.75
        
        let contentStack = UIStackView()
        contentStack.axis = .vertical
        contentStack.spacing = 14
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentStack)
        
        // Header Row: "TOTAL BALANCE" + Eye Button
        let headerRow = UIStackView()
        headerRow.axis = .horizontal
        headerRow.alignment = .center
        
        titleLabel.text = "TOTAL BALANCE"
        titleLabel.font = .systemFont(ofSize: 12, weight: .bold)
        titleLabel.textColor = .secondaryLabel
        headerRow.addArrangedSubview(titleLabel)
        
        let spacer = UIView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        headerRow.addArrangedSubview(spacer)
        
        toggleEyeButton.setImage(UIImage(systemName: "eye.fill"), for: .normal)
        toggleEyeButton.tintColor = .secondaryLabel
        toggleEyeButton.addAction(UIAction { [weak self] _ in
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            self?.onToggleVisibility?()
        }, for: .touchUpInside)
        headerRow.addArrangedSubview(toggleEyeButton)
        contentStack.addArrangedSubview(headerRow)
        
        // Balance Row
        balanceLabel.font = .systemFont(ofSize: 38, weight: .heavy)
        balanceLabel.textColor = ThemeManager.shared.colors.text
        contentStack.addArrangedSubview(balanceLabel)
        
        // Cash Flow Pill Badge
        cashFlowBadge.layer.cornerRadius = 12
        cashFlowBadge.layer.cornerCurve = .continuous
        cashFlowBadge.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.12)
        cashFlowBadge.translatesAutoresizingMaskIntoConstraints = false
        
        let badgeRow = UIStackView()
        badgeRow.axis = .horizontal
        badgeRow.spacing = 6
        badgeRow.alignment = .center
        badgeRow.translatesAutoresizingMaskIntoConstraints = false
        cashFlowBadge.addSubview(badgeRow)
        
        let badgeIcon = UIImageView(image: UIImage(systemName: "arrow.up.right"))
        badgeIcon.tintColor = .systemGreen
        badgeIcon.contentMode = .scaleAspectFit
        badgeIcon.translatesAutoresizingMaskIntoConstraints = false
        badgeIcon.widthAnchor.constraint(equalToConstant: 12).isActive = true
        badgeIcon.heightAnchor.constraint(equalToConstant: 12).isActive = true
        badgeRow.addArrangedSubview(badgeIcon)
        
        cashFlowLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        cashFlowLabel.textColor = .systemGreen
        badgeRow.addArrangedSubview(cashFlowLabel)
        
        let badgeContainer = UIView()
        badgeContainer.addSubview(cashFlowBadge)
        contentStack.addArrangedSubview(badgeContainer)
        
        // Divider
        let divider = UIView()
        divider.backgroundColor = ThemeManager.shared.colors.separator.withAlphaComponent(0.4)
        divider.translatesAutoresizingMaskIntoConstraints = false
        divider.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
        contentStack.addArrangedSubview(divider)
        
        // Bottom Metrics: Income & Expenses
        let metricsRow = UIStackView()
        metricsRow.axis = .horizontal
        metricsRow.distribution = .fillEqually
        metricsRow.spacing = 12
        
        metricsRow.addArrangedSubview(createMetricPill(title: "Income", amountLabel: incomeAmountLabel, icon: "arrow.down.left", iconColor: .systemGreen))
        metricsRow.addArrangedSubview(createMetricPill(title: "Expenses", amountLabel: expenseAmountLabel, icon: "arrow.up.right", iconColor: .systemRed))
        contentStack.addArrangedSubview(metricsRow)
        
        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            contentStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            contentStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20),
            
            badgeRow.topAnchor.constraint(equalTo: cashFlowBadge.topAnchor, constant: 5),
            badgeRow.leadingAnchor.constraint(equalTo: cashFlowBadge.leadingAnchor, constant: 10),
            badgeRow.trailingAnchor.constraint(equalTo: cashFlowBadge.trailingAnchor, constant: -10),
            badgeRow.bottomAnchor.constraint(equalTo: cashFlowBadge.bottomAnchor, constant: -5),
            
            cashFlowBadge.topAnchor.constraint(equalTo: badgeContainer.topAnchor),
            cashFlowBadge.leadingAnchor.constraint(equalTo: badgeContainer.leadingAnchor),
            cashFlowBadge.bottomAnchor.constraint(equalTo: badgeContainer.bottomAnchor)
        ])
        
        NotificationCenter.default.addObserver(self, selector: #selector(applyTheme), name: .themeDidChange, object: nil)
    }
    
    private func createMetricPill(title: String, amountLabel: UILabel, icon: String, iconColor: UIColor) -> UIView {
        let container = UIView()
        container.layer.cornerRadius = 14
        container.layer.cornerCurve = .continuous
        container.backgroundColor = ThemeManager.shared.colors.elevatedCard
        
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 10
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(stack)
        
        let iconCircle = UIView()
        iconCircle.layer.cornerRadius = 16
        iconCircle.layer.cornerCurve = .continuous
        iconCircle.backgroundColor = iconColor.withAlphaComponent(0.12)
        iconCircle.translatesAutoresizingMaskIntoConstraints = false
        iconCircle.widthAnchor.constraint(equalToConstant: 32).isActive = true
        iconCircle.heightAnchor.constraint(equalToConstant: 32).isActive = true
        
        let img = UIImageView(image: UIImage(systemName: icon))
        img.tintColor = iconColor
        img.contentMode = .scaleAspectFit
        img.translatesAutoresizingMaskIntoConstraints = false
        iconCircle.addSubview(img)
        img.centerXAnchor.constraint(equalTo: iconCircle.centerXAnchor).isActive = true
        img.centerYAnchor.constraint(equalTo: iconCircle.centerYAnchor).isActive = true
        img.widthAnchor.constraint(equalToConstant: 14).isActive = true
        img.heightAnchor.constraint(equalToConstant: 14).isActive = true
        stack.addArrangedSubview(iconCircle)
        
        let textStack = UIStackView()
        textStack.axis = .vertical
        textStack.spacing = 2
        
        let tLbl = UILabel()
        tLbl.text = title
        tLbl.font = .systemFont(ofSize: 11, weight: .medium)
        tLbl.textColor = .secondaryLabel
        textStack.addArrangedSubview(tLbl)
        
        amountLabel.font = .systemFont(ofSize: 15, weight: .bold)
        amountLabel.textColor = ThemeManager.shared.colors.text
        textStack.addArrangedSubview(amountLabel)
        
        stack.addArrangedSubview(textStack)
        
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 10),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 10),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -10),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -10)
        ])
        
        return container
    }
    
    public func configure(summary: FinancialSummary, isHidden: Bool) {
        let currency = CurrencyManager.shared
        toggleEyeButton.setImage(UIImage(systemName: isHidden ? "eye.slash.fill" : "eye.fill"), for: .normal)
        
        if isHidden {
            balanceLabel.text = "••••••••"
            incomeAmountLabel.text = "••••••"
            expenseAmountLabel.text = "••••••"
            cashFlowLabel.text = "Cash Flow Hidden"
        } else {
            balanceLabel.text = currency.format(summary.totalBalance)
            incomeAmountLabel.text = currency.format(summary.totalIncome)
            expenseAmountLabel.text = currency.format(summary.totalExpenses)
            
            let net = summary.totalIncome - summary.totalExpenses
            let sign = net >= 0 ? "+" : "-"
            cashFlowLabel.text = "\(sign)\(currency.format(abs(net))) net cash flow this month"
        }
    }
    
    @objc public func applyTheme() {
        backgroundColor = ThemeManager.shared.colors.card
        balanceLabel.textColor = ThemeManager.shared.colors.text
        incomeAmountLabel.textColor = ThemeManager.shared.colors.text
        expenseAmountLabel.textColor = ThemeManager.shared.colors.text
    }
}

// MARK: - Modern Circular Quick Action Button

public class ActionIconButton: UIView {
    private let iconCircle = UIView()
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    
    public var onTap: (() -> Void)?
    
    public init(title: String, iconName: String, gradientColors: [UIColor]) {
        super.init(frame: .zero)
        setup(title: title, iconName: iconName, bg: gradientColors.first ?? .systemBlue)
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    private func setup(title: String, iconName: String, bg: UIColor) {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        
        iconCircle.layer.cornerRadius = 27
        iconCircle.layer.cornerCurve = .continuous
        iconCircle.backgroundColor = bg
        iconCircle.translatesAutoresizingMaskIntoConstraints = false
        iconCircle.widthAnchor.constraint(equalToConstant: 54).isActive = true
        iconCircle.heightAnchor.constraint(equalToConstant: 54).isActive = true
        
        iconImageView.image = UIImage(systemName: iconName)?.withConfiguration(UIImage.SymbolConfiguration(pointSize: 22, weight: .semibold))
        iconImageView.tintColor = .white
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconCircle.addSubview(iconImageView)
        
        stack.addArrangedSubview(iconCircle)
        
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        titleLabel.textColor = ThemeManager.shared.colors.text
        titleLabel.textAlignment = .center
        stack.addArrangedSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            iconImageView.centerXAnchor.constraint(equalTo: iconCircle.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: iconCircle.centerYAnchor)
        ])
        
        isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tap)
    }
    
    @objc private func handleTap() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        UIView.animate(withDuration: 0.1, animations: {
            self.transform = CGAffineTransform(scaleX: 0.94, y: 0.94)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.transform = .identity
            }
            self.onTap?()
        }
    }
}

// MARK: - Progress Bar View

public class ProgressBarView: UIView {
    private let trackLayer = CALayer()
    private let progressLayer = CALayer()
    
    public var progress: Double = 0.0 {
        didSet {
            setNeedsLayout()
        }
    }
    
    public var progressColor: UIColor = .systemBlue {
        didSet {
            progressLayer.backgroundColor = progressColor.cgColor
        }
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayers()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayers()
    }
    
    private func setupLayers() {
        layer.cornerRadius = 4.5
        layer.cornerCurve = .continuous
        layer.masksToBounds = true
        trackLayer.backgroundColor = UIColor.systemGray5.cgColor
        layer.addSublayer(trackLayer)
        
        progressLayer.cornerRadius = 4.5
        progressLayer.cornerCurve = .continuous
        progressLayer.masksToBounds = true
        progressLayer.backgroundColor = progressColor.cgColor
        layer.addSublayer(progressLayer)
        
        NotificationCenter.default.addObserver(self, selector: #selector(applyTheme), name: .themeDidChange, object: nil)
    }
    
    @objc private func applyTheme() {
        trackLayer.backgroundColor = ThemeManager.shared.colors.separator.cgColor
        progressLayer.backgroundColor = progressColor.cgColor
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        trackLayer.frame = bounds
        let validProgress = CGFloat(min(max(progress, 0.0), 1.0))
        let fillWidth = bounds.width * validProgress
        progressLayer.frame = CGRect(x: 0, y: 0, width: fillWidth, height: bounds.height)
    }
}

// MARK: - Empty State View

public class EmptyStateView: UIView {
    private let imageView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let actionButton = UIButton(type: .system)
    
    public var onActionTapped: (() -> Void)?
    
    public init(symbolName: String, title: String, subtitle: String, buttonTitle: String? = nil) {
        super.init(frame: .zero)
        setup(symbolName: symbolName, title: title, subtitle: subtitle, buttonTitle: buttonTitle)
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    private func setup(symbolName: String, title: String, subtitle: String, buttonTitle: String?) {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 14
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        
        let iconCircle = UIView()
        iconCircle.layer.cornerRadius = 36
        iconCircle.layer.cornerCurve = .continuous
        iconCircle.backgroundColor = UIColor.systemGray5.withAlphaComponent(0.6)
        iconCircle.translatesAutoresizingMaskIntoConstraints = false
        iconCircle.widthAnchor.constraint(equalToConstant: 72).isActive = true
        iconCircle.heightAnchor.constraint(equalToConstant: 72).isActive = true
        
        imageView.image = UIImage(systemName: symbolName)?.withConfiguration(UIImage.SymbolConfiguration(pointSize: 32, weight: .regular))
        imageView.tintColor = .secondaryLabel
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        iconCircle.addSubview(imageView)
        imageView.centerXAnchor.constraint(equalTo: iconCircle.centerXAnchor).isActive = true
        imageView.centerYAnchor.constraint(equalTo: iconCircle.centerYAnchor).isActive = true
        stack.addArrangedSubview(iconCircle)
        
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 18, weight: .bold)
        titleLabel.textColor = .label
        titleLabel.textAlignment = .center
        stack.addArrangedSubview(titleLabel)
        
        subtitleLabel.text = subtitle
        subtitleLabel.font = .systemFont(ofSize: 14, weight: .regular)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0
        stack.addArrangedSubview(subtitleLabel)
        
        if let btnTitle = buttonTitle {
            actionButton.setTitle(btnTitle, for: .normal)
            actionButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
            actionButton.backgroundColor = .systemBlue
            actionButton.setTitleColor(.white, for: .normal)
            actionButton.layer.cornerRadius = 12
            actionButton.layer.cornerCurve = .continuous
            actionButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 24, bottom: 10, right: 24)
            actionButton.addTarget(self, action: #selector(btnTapped), for: .touchUpInside)
            stack.addArrangedSubview(actionButton)
        }
        
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 32),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -32)
        ])
    }
    
    @objc private func btnTapped() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        onActionTapped?()
    }
}
