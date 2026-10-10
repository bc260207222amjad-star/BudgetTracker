//
//  OnboardingViewController.swift
//  BudgetTracker
//
//  Created by ali on 10/10/2026.
//

import UIKit

public class OnboardingViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    public var onCompletion: (() -> Void)?
    
    private let collectionView: UICollectionView
    private let pageControl = UIPageControl()
    private let nextButton = UIButton(type: .system)
    private let skipButton = UIButton(type: .system)
    
    private var currentPage: Int = 0
    private var selectedCurrencyCode: String = CurrencyManager.shared.currentCurrency.code
    private var enableBiometricsOnFinish: Bool = false
    
    public init() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        self.collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = ThemeManager.shared.colors.background
        
        // Skip Button
        skipButton.setTitle("Skip", for: .normal)
        skipButton.setTitleColor(.secondaryLabel, for: .normal)
        skipButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        skipButton.addTarget(self, action: #selector(finishOnboardingClean), for: .touchUpInside)
        skipButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(skipButton)
        
        // Collection View for Paging
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.isPagingEnabled = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundColor = .clear
        collectionView.register(OnboardingWelcomeCell.self, forCellWithReuseIdentifier: OnboardingWelcomeCell.identifier)
        collectionView.register(OnboardingCurrencyCell.self, forCellWithReuseIdentifier: OnboardingCurrencyCell.identifier)
        collectionView.register(OnboardingSecurityCell.self, forCellWithReuseIdentifier: OnboardingSecurityCell.identifier)
        collectionView.register(OnboardingReadyCell.self, forCellWithReuseIdentifier: OnboardingReadyCell.identifier)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)
        
        // Bottom Controls
        let bottomStack = UIStackView()
        bottomStack.axis = .vertical
        bottomStack.spacing = 16
        bottomStack.alignment = .center
        bottomStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bottomStack)
        
        pageControl.numberOfPages = 4
        pageControl.currentPage = 0
        pageControl.currentPageIndicatorTintColor = ThemeManager.shared.colors.primary
        pageControl.pageIndicatorTintColor = ThemeManager.shared.colors.separator
        bottomStack.addArrangedSubview(pageControl)
        
        nextButton.setTitle("Continue", for: .normal)
        nextButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .bold)
        nextButton.backgroundColor = ThemeManager.shared.colors.primary
        nextButton.setTitleColor(.white, for: .normal)
        nextButton.layer.cornerRadius = 16
        nextButton.layer.cornerCurve = .continuous
        nextButton.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)
        nextButton.translatesAutoresizingMaskIntoConstraints = false
        nextButton.widthAnchor.constraint(equalToConstant: 320).isActive = true
        nextButton.heightAnchor.constraint(equalToConstant: 54).isActive = true
        bottomStack.addArrangedSubview(nextButton)
        
        NSLayoutConstraint.activate([
            skipButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            skipButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            collectionView.topAnchor.constraint(equalTo: skipButton.bottomAnchor, constant: 4),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomStack.topAnchor, constant: -12),
            
            bottomStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            bottomStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            bottomStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
    }
    
    // MARK: - Actions
    
    @objc private func nextTapped() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        if currentPage < 3 {
            currentPage += 1
            let nextIndex = IndexPath(item: currentPage, section: 0)
            collectionView.scrollToItem(at: nextIndex, at: .centeredHorizontally, animated: true)
            pageControl.currentPage = currentPage
            updateNextButtonTitle()
        } else {
            finishWithSampleDataPrompt()
        }
    }
    
    @objc private func finishOnboardingClean() {
        completeOnboarding(withSampleData: false)
    }
    
    private func finishWithSampleDataPrompt() {
        completeOnboarding(withSampleData: false)
    }
    
    public func completeOnboarding(withSampleData: Bool) {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        UserDefaults.standard.set(true, forKey: "BudgetTracker_HasCompletedOnboarding")
        CurrencyManager.shared.setCurrency(code: selectedCurrencyCode)
        if enableBiometricsOnFinish {
            BiometricAuthManager.shared.isBiometricsEnabled = true
        }
        if withSampleData {
            SampleDataLoader.shared.loadRealisticSampleData()
        } else {
            AccountManager.shared.ensureDefaultAccountsExist()
        }
        
        dismiss(animated: true) { [weak self] in
            self?.onCompletion?()
        }
    }
    
    private func updateNextButtonTitle() {
        if currentPage == 3 {
            nextButton.setTitle("Start Budgeting", for: .normal)
            skipButton.isHidden = true
        } else {
            nextButton.setTitle("Continue", for: .normal)
            skipButton.isHidden = false
        }
    }
    
    // MARK: - UICollectionView DataSource & Delegate
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 4
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch indexPath.item {
        case 0:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: OnboardingWelcomeCell.identifier, for: indexPath) as! OnboardingWelcomeCell
            cell.configure()
            return cell
        case 1:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: OnboardingCurrencyCell.identifier, for: indexPath) as! OnboardingCurrencyCell
            cell.configure(selectedCode: selectedCurrencyCode) { [weak self] newCode in
                self?.selectedCurrencyCode = newCode
            }
            return cell
        case 2:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: OnboardingSecurityCell.identifier, for: indexPath) as! OnboardingSecurityCell
            cell.configure(isEnabled: enableBiometricsOnFinish) { [weak self] enabled in
                self?.enableBiometricsOnFinish = enabled
            }
            return cell
        default:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: OnboardingReadyCell.identifier, for: indexPath) as! OnboardingReadyCell
            cell.configure(
                onSampleDataSelected: { [weak self] in
                    self?.completeOnboarding(withSampleData: true)
                },
                onCleanStartSelected: { [weak self] in
                    self?.completeOnboarding(withSampleData: false)
                }
            )
            return cell
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return collectionView.bounds.size
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let page = Int(scrollView.contentOffset.x / scrollView.bounds.width)
        self.currentPage = page
        self.pageControl.currentPage = page
        updateNextButtonTitle()
    }
}

// MARK: - Slide 1: Welcome Cell

class OnboardingWelcomeCell: UICollectionViewCell {
    static let identifier = "OnboardingWelcomeCell"
    
    func configure() {
        contentView.subviews.forEach { $0.removeFromSuperview() }
        
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 24
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stack)
        
        // Hero Icon with Gradient Glow
        let iconContainer = UIView()
        iconContainer.layer.cornerRadius = 38
        iconContainer.layer.cornerCurve = .continuous
        iconContainer.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.12)
        iconContainer.translatesAutoresizingMaskIntoConstraints = false
        
        let icon = UIImageView(image: UIImage(systemName: "wallet.pass.fill"))
        icon.tintColor = .systemBlue
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false
        iconContainer.addSubview(icon)
        stack.addArrangedSubview(iconContainer)
        
        // Titles
        let titleStack = UIStackView()
        titleStack.axis = .vertical
        titleStack.spacing = 8
        titleStack.alignment = .center
        
        let titleLabel = UILabel()
        titleLabel.text = "BudgetTracker"
        titleLabel.font = .systemFont(ofSize: 32, weight: .heavy)
        titleLabel.textColor = .label
        titleStack.addArrangedSubview(titleLabel)
        
        let subtitleLabel = UILabel()
        subtitleLabel.text = "Private, intelligent budgeting made effortless."
        subtitleLabel.font = .systemFont(ofSize: 16, weight: .regular)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.textAlignment = .center
        titleStack.addArrangedSubview(subtitleLabel)
        
        stack.addArrangedSubview(titleStack)
        
        // Feature Cards
        let featuresStack = UIStackView()
        featuresStack.axis = .vertical
        featuresStack.spacing = 16
        featuresStack.alignment = .fill
        featuresStack.translatesAutoresizingMaskIntoConstraints = false
        stack.addArrangedSubview(featuresStack)
        
        featuresStack.addArrangedSubview(createFeatureRow(
            icon: "lock.shield.fill",
            color: .systemGreen,
            title: "100% Offline & Private",
            desc: "All financial data stays strictly on your device. Zero telemetry, zero tracking."
        ))
        
        featuresStack.addArrangedSubview(createFeatureRow(
            icon: "chart.line.uptrend.xyaxis",
            color: .systemBlue,
            title: "Interactive Swift Charts",
            desc: "Visual cash flow, donut category breakdowns, and net worth analysis."
        ))
        
        featuresStack.addArrangedSubview(createFeatureRow(
            icon: "doc.viewfinder.fill",
            color: .systemOrange,
            title: "OCR Receipt Scanning & AI",
            desc: "Extract totals instantly with Vision OCR and get intelligent budgeting advice."
        ))
        
        NSLayoutConstraint.activate([
            iconContainer.widthAnchor.constraint(equalToConstant: 76),
            iconContainer.heightAnchor.constraint(equalToConstant: 76),
            icon.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            icon.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 40),
            icon.heightAnchor.constraint(equalToConstant: 40),
            
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 28),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -28),
            featuresStack.widthAnchor.constraint(equalTo: stack.widthAnchor)
        ])
    }
    
    private func createFeatureRow(icon: String, color: UIColor, title: String, desc: String) -> UIView {
        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = 14
        row.alignment = .top
        
        let iconView = UIImageView(image: UIImage(systemName: icon))
        iconView.tintColor = color
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.widthAnchor.constraint(equalToConstant: 24).isActive = true
        iconView.heightAnchor.constraint(equalToConstant: 24).isActive = true
        row.addArrangedSubview(iconView)
        
        let textStack = UIStackView()
        textStack.axis = .vertical
        textStack.spacing = 3
        
        let tLabel = UILabel()
        tLabel.text = title
        tLabel.font = .systemFont(ofSize: 15, weight: .bold)
        tLabel.textColor = .label
        textStack.addArrangedSubview(tLabel)
        
        let dLabel = UILabel()
        dLabel.text = desc
        dLabel.font = .systemFont(ofSize: 13, weight: .regular)
        dLabel.textColor = .secondaryLabel
        dLabel.numberOfLines = 0
        textStack.addArrangedSubview(dLabel)
        
        row.addArrangedSubview(textStack)
        return row
    }
}

// MARK: - Slide 2: Currency Cell

class OnboardingCurrencyCell: UICollectionViewCell, UITableViewDataSource, UITableViewDelegate {
    static let identifier = "OnboardingCurrencyCell"
    
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var selectedCode: String = "USD"
    private var onSelect: ((String) -> Void)?
    
    func configure(selectedCode: String, onSelect: @escaping (String) -> Void) {
        self.selectedCode = selectedCode
        self.onSelect = onSelect
        contentView.subviews.forEach { $0.removeFromSuperview() }
        
        let headerStack = UIStackView()
        headerStack.axis = .vertical
        headerStack.spacing = 8
        headerStack.alignment = .center
        headerStack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(headerStack)
        
        let titleLabel = UILabel()
        titleLabel.text = "Choose Your Currency"
        titleLabel.font = .systemFont(ofSize: 26, weight: .heavy)
        titleLabel.textColor = .label
        headerStack.addArrangedSubview(titleLabel)
        
        let subtitleLabel = UILabel()
        subtitleLabel.text = "We will format all transactions and budgets in your preferred currency."
        subtitleLabel.font = .systemFont(ofSize: 14)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0
        headerStack.addArrangedSubview(subtitleLabel)
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = .clear
        tableView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            headerStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            headerStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            headerStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            
            tableView.topAnchor.constraint(equalTo: headerStack.bottomAnchor, constant: 12),
            tableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return CurrencyInfo.supportedCurrencies.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: "CurCell")
        let item = CurrencyInfo.supportedCurrencies[indexPath.row]
        cell.backgroundColor = ThemeManager.shared.colors.card
        cell.textLabel?.text = "\(item.name) (\(item.code))"
        cell.textLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        cell.detailTextLabel?.text = item.symbol.trimmingCharacters(in: .whitespaces)
        cell.detailTextLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        
        if item.code == selectedCode {
            cell.accessoryType = .checkmark
            cell.textLabel?.textColor = .systemBlue
        } else {
            cell.accessoryType = .none
            cell.textLabel?.textColor = .label
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let chosen = CurrencyInfo.supportedCurrencies[indexPath.row]
        self.selectedCode = chosen.code
        onSelect?(chosen.code)
        tableView.reloadData()
    }
}

// MARK: - Slide 3: Security Cell

class OnboardingSecurityCell: UICollectionViewCell {
    static let identifier = "OnboardingSecurityCell"
    
    private let biometricsSwitch = UISwitch()
    private var onToggle: ((Bool) -> Void)?
    
    func configure(isEnabled: Bool, onToggle: @escaping (Bool) -> Void) {
        self.onToggle = onToggle
        contentView.subviews.forEach { $0.removeFromSuperview() }
        
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 24
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stack)
        
        let iconContainer = UIView()
        iconContainer.layer.cornerRadius = 44
        iconContainer.layer.cornerCurve = .continuous
        iconContainer.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.12)
        iconContainer.translatesAutoresizingMaskIntoConstraints = false
        
        let icon = UIImageView(image: UIImage(systemName: "faceid"))
        icon.tintColor = .systemGreen
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false
        iconContainer.addSubview(icon)
        stack.addArrangedSubview(iconContainer)
        
        let titleLabel = UILabel()
        titleLabel.text = "Protect Your Privacy"
        titleLabel.font = .systemFont(ofSize: 26, weight: .heavy)
        titleLabel.textColor = .label
        stack.addArrangedSubview(titleLabel)
        
        let subtitleLabel = UILabel()
        subtitleLabel.text = "Lock BudgetTracker with Face ID, Touch ID, or your device passcode. Your data is blurred when switching apps."
        subtitleLabel.font = .systemFont(ofSize: 15)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0
        stack.addArrangedSubview(subtitleLabel)
        
        let card = CardView()
        card.translatesAutoresizingMaskIntoConstraints = false
        stack.addArrangedSubview(card)
        
        let row = UIStackView()
        row.axis = .horizontal
        row.distribution = .equalSpacing
        row.alignment = .center
        row.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(row)
        
        let switchLabel = UILabel()
        switchLabel.text = "Enable Biometric App Lock"
        switchLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        row.addArrangedSubview(switchLabel)
        
        biometricsSwitch.isOn = isEnabled
        biometricsSwitch.addTarget(self, action: #selector(toggleChanged), for: .valueChanged)
        row.addArrangedSubview(biometricsSwitch)
        
        NSLayoutConstraint.activate([
            iconContainer.widthAnchor.constraint(equalToConstant: 88),
            iconContainer.heightAnchor.constraint(equalToConstant: 88),
            icon.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            icon.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 48),
            icon.heightAnchor.constraint(equalToConstant: 48),
            
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 28),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            
            card.widthAnchor.constraint(equalTo: stack.widthAnchor),
            row.topAnchor.constraint(equalTo: card.topAnchor, constant: 18),
            row.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 18),
            row.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -18),
            row.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -18)
        ])
    }
    
    @objc private func toggleChanged() {
        onToggle?(biometricsSwitch.isOn)
    }
}

// MARK: - Slide 4: Ready Cell

class OnboardingReadyCell: UICollectionViewCell {
    static let identifier = "OnboardingReadyCell"
    
    func configure(onSampleDataSelected: @escaping () -> Void, onCleanStartSelected: @escaping () -> Void) {
        contentView.subviews.forEach { $0.removeFromSuperview() }
        
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 20
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stack)
        
        let icon = UIImageView(image: UIImage(systemName: "checkmark.seal.fill"))
        icon.tintColor = .systemBlue
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.widthAnchor.constraint(equalToConstant: 68).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 68).isActive = true
        stack.addArrangedSubview(icon)
        
        let titleLabel = UILabel()
        titleLabel.text = "You're All Set!"
        titleLabel.font = .systemFont(ofSize: 28, weight: .heavy)
        titleLabel.textColor = .label
        stack.addArrangedSubview(titleLabel)
        
        let descLabel = UILabel()
        descLabel.text = "How would you like to start your budgeting journey?"
        descLabel.font = .systemFont(ofSize: 15)
        descLabel.textColor = .secondaryLabel
        descLabel.textAlignment = .center
        stack.addArrangedSubview(descLabel)
        
        let sampleBtn = UIButton(type: .system)
        sampleBtn.setTitle("✨ Explore with Sample Data (Recommended)", for: .normal)
        sampleBtn.titleLabel?.font = .systemFont(ofSize: 15, weight: .bold)
        sampleBtn.backgroundColor = .systemBlue.withAlphaComponent(0.12)
        sampleBtn.setTitleColor(.systemBlue, for: .normal)
        sampleBtn.layer.cornerRadius = 14
        sampleBtn.layer.borderWidth = 1
        sampleBtn.layer.borderColor = UIColor.systemBlue.withAlphaComponent(0.3).cgColor
        sampleBtn.addAction(UIAction { _ in onSampleDataSelected() }, for: .touchUpInside)
        sampleBtn.translatesAutoresizingMaskIntoConstraints = false
        sampleBtn.heightAnchor.constraint(equalToConstant: 54).isActive = true
        stack.addArrangedSubview(sampleBtn)
        
        let cleanBtn = UIButton(type: .system)
        cleanBtn.setTitle("Start Fresh (Blank Database)", for: .normal)
        cleanBtn.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        cleanBtn.backgroundColor = .secondarySystemBackground
        cleanBtn.setTitleColor(.label, for: .normal)
        cleanBtn.layer.cornerRadius = 14
        cleanBtn.addAction(UIAction { _ in onCleanStartSelected() }, for: .touchUpInside)
        cleanBtn.translatesAutoresizingMaskIntoConstraints = false
        cleanBtn.heightAnchor.constraint(equalToConstant: 50).isActive = true
        stack.addArrangedSubview(cleanBtn)
        
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 36),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            sampleBtn.widthAnchor.constraint(equalTo: stack.widthAnchor),
            cleanBtn.widthAnchor.constraint(equalTo: stack.widthAnchor)
        ])
    }
}
