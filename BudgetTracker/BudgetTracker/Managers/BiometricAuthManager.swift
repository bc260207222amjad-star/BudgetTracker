//
//  BiometricAuthManager.swift
//  BudgetTracker
//
//  Created by ali on 10/10/2026.
//

import UIKit
import LocalAuthentication

public enum LockTimeout: Int, CaseIterable {
    case immediately = 0
    case oneMinute = 60
    case fiveMinutes = 300
    case fifteenMinutes = 900
    
    public var title: String {
        switch self {
        case .immediately: return "Immediately"
        case .oneMinute: return "1 minute"
        case .fiveMinutes: return "5 minutes"
        case .fifteenMinutes: return "15 minutes"
        }
    }
}

public class BiometricAuthManager {
    public static let shared = BiometricAuthManager()
    
    private let biometricsEnabledKey = "BudgetTracker_BiometricsEnabled"
    private let lockTimeoutKey = "BudgetTracker_LockTimeout"
    private let hideBalanceKey = "BudgetTracker_HideBalance"
    private let hideAmountsKey = "BudgetTracker_HideTransactionAmounts"
    
    public private(set) var isLocked: Bool = false
    private var lastBackgroundDate: Date?
    
    private var blurEffectView: UIVisualEffectView?
    
    private init() {
        if isBiometricsEnabled {
            isLocked = true
        }
    }
    
    // MARK: - Settings
    
    public var isBiometricsEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: biometricsEnabledKey) }
        set {
            UserDefaults.standard.set(newValue, forKey: biometricsEnabledKey)
            if !newValue {
                isLocked = false
            }
            NotificationCenter.default.post(name: .securitySettingsDidChange, object: nil)
        }
    }
    
    public var lockTimeout: LockTimeout {
        get {
            let seconds = UserDefaults.standard.integer(forKey: lockTimeoutKey)
            return LockTimeout(rawValue: seconds) ?? .immediately
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: lockTimeoutKey)
            NotificationCenter.default.post(name: .securitySettingsDidChange, object: nil)
        }
    }
    
    public var hideBalance: Bool {
        get { UserDefaults.standard.bool(forKey: hideBalanceKey) }
        set {
            UserDefaults.standard.set(newValue, forKey: hideBalanceKey)
            NotificationCenter.default.post(name: .privacyDisplayDidChange, object: nil)
        }
    }
    
    public var hideTransactionAmounts: Bool {
        get { UserDefaults.standard.bool(forKey: hideAmountsKey) }
        set {
            UserDefaults.standard.set(newValue, forKey: hideAmountsKey)
            NotificationCenter.default.post(name: .privacyDisplayDidChange, object: nil)
        }
    }
    
    // MARK: - Biometry Detection
    
    public var biometryType: LABiometryType {
        let context = LAContext()
        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            return context.biometryType
        }
        return .none
    }
    
    public var biometryTitle: String {
        switch biometryType {
        case .faceID: return "Face ID"
        case .touchID: return "Touch ID"
        case .opticID: return "Optic ID"
        default: return "Biometrics / Passcode"
        }
    }
    
    public var biometryIconName: String {
        switch biometryType {
        case .faceID: return "faceid"
        case .touchID: return "touchid"
        case .opticID: return "opticid"
        default: return "lock.shield.fill"
        }
    }
    
    // MARK: - Authentication
    
    public func authenticate(reason: String = "Unlock your Budget Tracker data", completion: @escaping (Bool) -> Void) {
        let context = LAContext()
        context.localizedCancelTitle = "Cancel"
        
        var error: NSError?
        // Fallback to passcode if biometrics not available or failed
        let policy: LAPolicy = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
            ? .deviceOwnerAuthentication
            : .deviceOwnerAuthentication
        
        context.evaluatePolicy(policy, localizedReason: reason) { [weak self] success, evalError in
            DispatchQueue.main.async {
                if success {
                    self?.isLocked = false
                }
                completion(success)
            }
        }
    }
    
    // MARK: - Lifecycle Lock Handling
    
    public func appWillResignActive(window: UIWindow?) {
        showPrivacyBlur(on: window)
    }
    
    public func appDidEnterBackground() {
        lastBackgroundDate = Date()
    }
    
    public func appWillEnterForeground() {
        guard isBiometricsEnabled else { return }
        
        if let lastDate = lastBackgroundDate {
            let elapsed = Date().timeIntervalSince(lastDate)
            if elapsed >= Double(lockTimeout.rawValue) {
                isLocked = true
            }
        }
    }
    
    public func appDidBecomeActive(window: UIWindow?) {
        if !isLocked {
            removePrivacyBlur()
        }
    }
    
    // MARK: - Privacy Blur
    
    public func showPrivacyBlur(on window: UIWindow?) {
        guard let window = window, blurEffectView == nil else { return }
        let blur = UIBlurEffect(style: .systemThinMaterial)
        let effectView = UIVisualEffectView(effect: blur)
        effectView.frame = window.bounds
        effectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        // Add lock icon in the center of blur
        let lockImageView = UIImageView(image: UIImage(systemName: "lock.shield.fill"))
        lockImageView.tintColor = .secondaryLabel
        lockImageView.contentMode = .scaleAspectFit
        lockImageView.translatesAutoresizingMaskIntoConstraints = false
        effectView.contentView.addSubview(lockImageView)
        
        NSLayoutConstraint.activate([
            lockImageView.centerXAnchor.constraint(equalTo: effectView.contentView.centerXAnchor),
            lockImageView.centerYAnchor.constraint(equalTo: effectView.contentView.centerYAnchor),
            lockImageView.widthAnchor.constraint(equalToConstant: 64),
            lockImageView.heightAnchor.constraint(equalToConstant: 64)
        ])
        
        window.addSubview(effectView)
        self.blurEffectView = effectView
    }
    
    public func removePrivacyBlur() {
        blurEffectView?.removeFromSuperview()
        blurEffectView = nil
    }
}

extension Notification.Name {
    public static let securitySettingsDidChange = Notification.Name("BudgetTracker_SecuritySettingsDidChange")
    public static let privacyDisplayDidChange = Notification.Name("BudgetTracker_PrivacyDisplayDidChange")
}
