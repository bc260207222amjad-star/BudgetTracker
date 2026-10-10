//
//  MainTabBarController.swift
//  BudgetTracker
//
//  Created by ali on 10/10/2026.
//

import UIKit

public class MainTabBarController: UITabBarController {
    
    private var lockOverlayView: UIView?
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupTabs()
        applyTheme()
        setupObservers()
        checkInitialLock()
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        checkOnboarding()
    }
    
    private func checkOnboarding() {
        if !UserDefaults.standard.bool(forKey: "BudgetTracker_HasCompletedOnboarding") {
            let onboarding = OnboardingViewController()
            onboarding.onCompletion = { [weak self] in
                self?.checkInitialLock()
                if let nav = self?.viewControllers?.first as? UINavigationController,
                   let dash = nav.viewControllers.first as? DashboardViewController {
                    dash.reloadData()
                }
            }
            present(onboarding, animated: true)
        }
    }
    
    private func setupTabs() {
        // 1. Dashboard
        let dashboardVC = DashboardViewController()
        let dashboardNav = UINavigationController(rootViewController: dashboardVC)
        dashboardNav.tabBarItem = UITabBarItem(
            title: "Dashboard",
            image: UIImage(systemName: "square.grid.2x2"),
            selectedImage: UIImage(systemName: "square.grid.2x2.fill")
        )
        
        // 2. Transactions
        let transactionsVC = TransactionsViewController()
        let transactionsNav = UINavigationController(rootViewController: transactionsVC)
        transactionsNav.tabBarItem = UITabBarItem(
            title: "Transactions",
            image: UIImage(systemName: "list.bullet.rectangle.portrait"),
            selectedImage: UIImage(systemName: "list.bullet.rectangle.portrait.fill")
        )
        
        // 3. Budgets
        let budgetsVC = BudgetsViewController()
        let budgetsNav = UINavigationController(rootViewController: budgetsVC)
        budgetsNav.tabBarItem = UITabBarItem(
            title: "Budgets",
            image: UIImage(systemName: "chart.pie"),
            selectedImage: UIImage(systemName: "chart.pie.fill")
        )
        
        // 4. Analytics
        let analyticsVC = AnalyticsViewController()
        let analyticsNav = UINavigationController(rootViewController: analyticsVC)
        analyticsNav.tabBarItem = UITabBarItem(
            title: "Analytics",
            image: UIImage(systemName: "chart.xyaxis.line"),
            selectedImage: UIImage(systemName: "chart.xyaxis.line")
        )
        
        // 5. Settings
        let settingsVC = SettingsViewController()
        let settingsNav = UINavigationController(rootViewController: settingsVC)
        settingsNav.tabBarItem = UITabBarItem(
            title: "Settings",
            image: UIImage(systemName: "gearshape"),
            selectedImage: UIImage(systemName: "gearshape.fill")
        )
        
        viewControllers = [dashboardNav, transactionsNav, budgetsNav, analyticsNav, settingsNav]
    }
    
    private func setupObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(applyTheme), name: .themeDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleSecurityStateChange), name: .securitySettingsDidChange, object: nil)
    }
    
    @objc private func applyTheme() {
        let colors = ThemeManager.shared.colors
        tabBar.tintColor = colors.primary
        tabBar.unselectedItemTintColor = colors.secondaryText
        tabBar.backgroundColor = colors.card
        tabBar.barTintColor = colors.card
        
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundColor = colors.card
        tabBar.standardAppearance = appearance
        if #available(iOS 15.0, *) {
            tabBar.scrollEdgeAppearance = appearance
        }
    }
    
    // MARK: - App Lock Protection
    
    public func checkInitialLock() {
        if BiometricAuthManager.shared.isBiometricsEnabled && BiometricAuthManager.shared.isLocked {
            showLockScreen()
        }
    }
    
    @objc private func handleSecurityStateChange() {
        if !BiometricAuthManager.shared.isBiometricsEnabled {
            removeLockScreen()
        }
    }
    
    public func showLockScreen() {
        guard lockOverlayView == nil else { return }
        
        let overlay = UIView(frame: view.bounds)
        overlay.backgroundColor = ThemeManager.shared.colors.background
        overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        overlay.addSubview(stack)
        
        let iconView = UIImageView(image: UIImage(systemName: BiometricAuthManager.shared.biometryIconName))
        iconView.tintColor = .systemBlue
        iconView.contentMode = .scaleAspectFit
        iconView.widthAnchor.constraint(equalToConstant: 72).isActive = true
        iconView.heightAnchor.constraint(equalToConstant: 72).isActive = true
        stack.addArrangedSubview(iconView)
        
        let titleLabel = UILabel()
        titleLabel.text = "Budget Tracker Locked"
        titleLabel.font = .systemFont(ofSize: 22, weight: .bold)
        stack.addArrangedSubview(titleLabel)
        
        let subtitle = UILabel()
        subtitle.text = "Unlock using \(BiometricAuthManager.shared.biometryTitle) or passcode."
        subtitle.font = .systemFont(ofSize: 14)
        subtitle.textColor = .secondaryLabel
        stack.addArrangedSubview(subtitle)
        
        let unlockButton = UIButton(type: .system)
        unlockButton.setTitle("Unlock App", for: .normal)
        unlockButton.backgroundColor = .systemBlue
        unlockButton.setTitleColor(.white, for: .normal)
        unlockButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        unlockButton.layer.cornerRadius = 12
        unlockButton.contentEdgeInsets = UIEdgeInsets(top: 12, left: 32, bottom: 12, right: 32)
        unlockButton.addTarget(self, action: #selector(unlockTapped), for: .touchUpInside)
        stack.addArrangedSubview(unlockButton)
        
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: overlay.centerYAnchor)
        ])
        
        view.addSubview(overlay)
        self.lockOverlayView = overlay
        
        // Auto trigger authentication
        unlockTapped()
    }
    
    public func removeLockScreen() {
        lockOverlayView?.removeFromSuperview()
        lockOverlayView = nil
    }
    
    @objc private func unlockTapped() {
        BiometricAuthManager.shared.authenticate { [weak self] success in
            if success {
                self?.removeLockScreen()
            }
        }
    }
}
