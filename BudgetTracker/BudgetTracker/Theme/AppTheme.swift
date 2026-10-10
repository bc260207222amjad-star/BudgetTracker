//
//  AppTheme.swift
//  BudgetTracker
//
//  Created by ali on 10/10/2026.
//

import UIKit

public enum AppThemeType: String, CaseIterable {
    case light = "Light"
    case dark = "Dark"
    case amoled = "AMOLED"
    case blue = "Ocean Blue"
    case green = "Emerald Green"
    case minimal = "Minimal Monochrome"
    case highContrast = "High Contrast"
    
    public var userInterfaceStyle: UIUserInterfaceStyle {
        switch self {
        case .light: return .light
        case .dark, .amoled: return .dark
        default: return .unspecified
        }
    }
}

public protocol AppThemeColors {
    var primary: UIColor { get }
    var secondary: UIColor { get }
    var background: UIColor { get }
    var card: UIColor { get }
    var elevatedCard: UIColor { get }
    var text: UIColor { get }
    var secondaryText: UIColor { get }
    var separator: UIColor { get }
    var success: UIColor { get }
    var warning: UIColor { get }
    var danger: UIColor { get }
    var income: UIColor { get }
    var expense: UIColor { get }
    var accent: UIColor { get }
}

public struct StandardLightColors: AppThemeColors {
    public let primary = UIColor(hex: "#0A84FF")!
    public let secondary = UIColor(hex: "#5E5CE6")!
    public let background = UIColor(hex: "#F2F2F7")!
    public let card = UIColor(hex: "#FFFFFF")!
    public let elevatedCard = UIColor(hex: "#FAFAFC")!
    public let text = UIColor(hex: "#1C1C1E")!
    public let secondaryText = UIColor(hex: "#8E8E93")!
    public let separator = UIColor(hex: "#E5E5EA")!
    public let success = UIColor(hex: "#34C759")!
    public let warning = UIColor(hex: "#FF9500")!
    public let danger = UIColor(hex: "#FF3B30")!
    public let income = UIColor(hex: "#34C759")!
    public let expense = UIColor(hex: "#FF3B30")!
    public let accent = UIColor(hex: "#007AFF")!
}

public struct StandardDarkColors: AppThemeColors {
    public let primary = UIColor(hex: "#0A84FF")!
    public let secondary = UIColor(hex: "#5E5CE6")!
    public let background = UIColor(hex: "#1C1C1E")!
    public let card = UIColor(hex: "#2C2C2E")!
    public let elevatedCard = UIColor(hex: "#3A3A3C")!
    public let text = UIColor(hex: "#FFFFFF")!
    public let secondaryText = UIColor(hex: "#8E8E93")!
    public let separator = UIColor(hex: "#38383A")!
    public let success = UIColor(hex: "#30D158")!
    public let warning = UIColor(hex: "#FF9F0A")!
    public let danger = UIColor(hex: "#FF453A")!
    public let income = UIColor(hex: "#30D158")!
    public let expense = UIColor(hex: "#FF453A")!
    public let accent = UIColor(hex: "#0A84FF")!
}

public struct AmoledColors: AppThemeColors {
    public let primary = UIColor(hex: "#0A84FF")!
    public let secondary = UIColor(hex: "#BF5AF2")!
    public let background = UIColor(hex: "#000000")!
    public let card = UIColor(hex: "#121212")!
    public let elevatedCard = UIColor(hex: "#1E1E1E")!
    public let text = UIColor(hex: "#FFFFFF")!
    public let secondaryText = UIColor(hex: "#9E9E9E")!
    public let separator = UIColor(hex: "#262626")!
    public let success = UIColor(hex: "#30D158")!
    public let warning = UIColor(hex: "#FFD60A")!
    public let danger = UIColor(hex: "#FF453A")!
    public let income = UIColor(hex: "#30D158")!
    public let expense = UIColor(hex: "#FF453A")!
    public let accent = UIColor(hex: "#0A84FF")!
}

public struct BlueColors: AppThemeColors {
    public let primary = UIColor(hex: "#007AFF")!
    public let secondary = UIColor(hex: "#5AC8FA")!
    public let background = UIColor(hex: "#0B192C")!
    public let card = UIColor(hex: "#1E3E62")!
    public let elevatedCard = UIColor(hex: "#2A4E7A")!
    public let text = UIColor(hex: "#F1F6F9")!
    public let secondaryText = UIColor(hex: "#9BA4B5")!
    public let separator = UIColor(hex: "#2B4865")!
    public let success = UIColor(hex: "#34C759")!
    public let warning = UIColor(hex: "#FF9500")!
    public let danger = UIColor(hex: "#FF3B30")!
    public let income = UIColor(hex: "#34C759")!
    public let expense = UIColor(hex: "#FF3B30")!
    public let accent = UIColor(hex: "#00B4D8")!
}

public struct GreenColors: AppThemeColors {
    public let primary = UIColor(hex: "#2D6A4F")!
    public let secondary = UIColor(hex: "#52B788")!
    public let background = UIColor(hex: "#081C15")!
    public let card = UIColor(hex: "#1B4332")!
    public let elevatedCard = UIColor(hex: "#2D6A4F")!
    public let text = UIColor(hex: "#D8F3DC")!
    public let secondaryText = UIColor(hex: "#95D5B2")!
    public let separator = UIColor(hex: "#2D6A4F")!
    public let success = UIColor(hex: "#40916C")!
    public let warning = UIColor(hex: "#E9D8A6")!
    public let danger = UIColor(hex: "#AE2012")!
    public let income = UIColor(hex: "#52B788")!
    public let expense = UIColor(hex: "#E63946")!
    public let accent = UIColor(hex: "#74C69D")!
}

public struct MinimalColors: AppThemeColors {
    public let primary = UIColor(hex: "#000000")!
    public let secondary = UIColor(hex: "#4A4A4A")!
    public let background = UIColor(hex: "#F8F9FA")!
    public let card = UIColor(hex: "#FFFFFF")!
    public let elevatedCard = UIColor(hex: "#E9ECEF")!
    public let text = UIColor(hex: "#212529")!
    public let secondaryText = UIColor(hex: "#6C757D")!
    public let separator = UIColor(hex: "#DEE2E6")!
    public let success = UIColor(hex: "#198754")!
    public let warning = UIColor(hex: "#FFC107")!
    public let danger = UIColor(hex: "#DC3545")!
    public let income = UIColor(hex: "#198754")!
    public let expense = UIColor(hex: "#DC3545")!
    public let accent = UIColor(hex: "#000000")!
}

public struct HighContrastColors: AppThemeColors {
    public let primary = UIColor(hex: "#FFFF00")!
    public let secondary = UIColor(hex: "#00FFFF")!
    public let background = UIColor(hex: "#000000")!
    public let card = UIColor(hex: "#1A1A1A")!
    public let elevatedCard = UIColor(hex: "#2E2E2E")!
    public let text = UIColor(hex: "#FFFFFF")!
    public let secondaryText = UIColor(hex: "#E0E0E0")!
    public let separator = UIColor(hex: "#FFFFFF")!
    public let success = UIColor(hex: "#00FF66")!
    public let warning = UIColor(hex: "#FFCC00")!
    public let danger = UIColor(hex: "#FF0033")!
    public let income = UIColor(hex: "#00FF66")!
    public let expense = UIColor(hex: "#FF0033")!
    public let accent = UIColor(hex: "#FFFF00")!
}

// MARK: - Centralized Theme Manager

public class ThemeManager {
    public static let shared = ThemeManager()
    
    private let themeKey = "BudgetTracker_SelectedTheme"
    
    public private(set) var currentTheme: AppThemeType
    
    private init() {
        let savedTheme = UserDefaults.standard.string(forKey: themeKey) ?? AppThemeType.light.rawValue
        self.currentTheme = AppThemeType(rawValue: savedTheme) ?? .light
    }
    
    public var colors: AppThemeColors {
        switch currentTheme {
        case .light: return StandardLightColors()
        case .dark: return StandardDarkColors()
        case .amoled: return AmoledColors()
        case .blue: return BlueColors()
        case .green: return GreenColors()
        case .minimal: return MinimalColors()
        case .highContrast: return HighContrastColors()
        }
    }
    
    public func setTheme(_ theme: AppThemeType) {
        self.currentTheme = theme
        UserDefaults.standard.set(theme.rawValue, forKey: themeKey)
        NotificationCenter.default.post(name: .themeDidChange, object: nil)
        
        // Update connected windows userInterfaceStyle
        DispatchQueue.main.async {
            for scene in UIApplication.shared.connectedScenes {
                if let windowScene = scene as? UIWindowScene {
                    for window in windowScene.windows {
                        window.overrideUserInterfaceStyle = theme.userInterfaceStyle
                    }
                }
            }
        }
    }
}

extension Notification.Name {
    public static let themeDidChange = Notification.Name("BudgetTracker_ThemeDidChange")
}

// MARK: - UIColor Hex Extension

extension UIColor {
    public convenience init?(hex: String) {
        var cString: String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        if cString.hasPrefix("#") {
            cString.remove(at: cString.startIndex)
        }
        
        if cString.count == 6 {
            var rgbValue: UInt64 = 0
            guard Scanner(string: cString).scanHexInt64(&rgbValue) else { return nil }
            self.init(
                red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
                green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
                blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
                alpha: 1.0
            )
        } else if cString.count == 8 {
            var rgbaValue: UInt64 = 0
            guard Scanner(string: cString).scanHexInt64(&rgbaValue) else { return nil }
            self.init(
                red: CGFloat((rgbaValue & 0xFF000000) >> 24) / 255.0,
                green: CGFloat((rgbaValue & 0x00FF0000) >> 16) / 255.0,
                blue: CGFloat((rgbaValue & 0x0000FF00) >> 8) / 255.0,
                alpha: CGFloat(rgbaValue & 0x000000FF) / 255.0
            )
        } else {
            return nil
        }
    }
    
    public func toHex() -> String {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        let rgb: Int = (Int)(r*255)<<16 | (Int)(g*255)<<8 | (Int)(b*255)<<0
        return String(format: "#%06x", rgb)
    }
}
