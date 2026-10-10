//
//  CommonComponents.swift
//  BudgetTracker
//
//  Created by ali on 10/10/2026.
//

import SwiftUI

// MARK: - Reusable Card Container

public struct CardContainer<Content: View>: View {
    @ObservedObject private var theme = ThemeManager.shared
    private let content: Content
    
    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    public var body: some View {
        content
            .padding(16)
            .background(theme.colors.cardColor)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(theme.colors.separatorColor.opacity(0.35), lineWidth: 0.75)
            )
            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 3)
    }
}

// MARK: - Hero Balance Card

public struct HeroBalanceCardView: View {
    let summary: FinancialSummary
    @ObservedObject private var theme = ThemeManager.shared
    @ObservedObject private var auth = BiometricAuthManager.shared
    @ObservedObject private var currency = CurrencyManager.shared
    
    public init(summary: FinancialSummary) {
        self.summary = summary
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header Row: TOTAL BALANCE + Privacy Eye Toggle
            HStack {
                Text("TOTAL BALANCE")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(theme.colors.secondaryTextColor)
                    .tracking(0.5)
                
                Spacer()
                
                Button(action: {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    auth.hideBalance.toggle()
                }) {
                    Image(systemName: auth.hideBalance ? "eye.slash.fill" : "eye.fill")
                        .foregroundColor(theme.colors.secondaryTextColor)
                        .font(.system(size: 16))
                }
            }
            
            // Balance Text
            if auth.hideBalance {
                Text("••••••••")
                    .font(.system(size: 36, weight: .heavy, design: .rounded))
                    .foregroundColor(theme.colors.textColor)
            } else {
                Text(currency.format(summary.totalBalance))
                    .font(.system(size: 38, weight: .heavy, design: .rounded))
                    .foregroundColor(theme.colors.textColor)
            }
            
            // Net Cash Flow Pill Badge
            let net = summary.totalIncome - summary.totalExpenses
            let isPositive = net >= 0
            HStack(spacing: 6) {
                Image(systemName: isPositive ? "arrow.up.right" : "arrow.down.right")
                    .font(.system(size: 12, weight: .bold))
                
                if auth.hideBalance {
                    Text("Cash Flow Hidden")
                        .font(.system(size: 13, weight: .semibold))
                } else {
                    let sign = isPositive ? "+" : "-"
                    Text("\(sign)\(currency.format(abs(net))) net this month")
                        .font(.system(size: 13, weight: .semibold))
                }
            }
            .foregroundColor(isPositive ? theme.colors.successColor : theme.colors.dangerColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                (isPositive ? theme.colors.successColor : theme.colors.dangerColor)
                    .opacity(0.12)
            )
            .clipShape(Capsule())
            
            Divider()
                .background(theme.colors.separatorColor.opacity(0.4))
                .padding(.vertical, 2)
            
            // Income & Expense Breakdown Pills
            HStack(spacing: 12) {
                // Income Pill
                metricPill(
                    title: "Income",
                    amount: auth.hideBalance ? "••••••" : currency.format(summary.totalIncome),
                    icon: "arrow.down.left",
                    color: theme.colors.successColor
                )
                
                // Expense Pill
                metricPill(
                    title: "Expenses",
                    amount: auth.hideBalance ? "••••••" : currency.format(summary.totalExpenses),
                    icon: "arrow.up.right",
                    color: theme.colors.dangerColor
                )
            }
        }
        .padding(20)
        .background(theme.colors.cardColor)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(theme.colors.separatorColor.opacity(0.35), lineWidth: 0.75)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
    
    private func metricPill(title: String, amount: String, icon: String, color: Color) -> some View {
        HStack(spacing: 10) {
            Circle()
                .fill(color.opacity(0.14))
                .frame(width: 34, height: 34)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(color)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(theme.colors.secondaryTextColor)
                
                Text(amount)
                    .font(.system(size: 15, weight: .bold, design: .monospaced))
                    .foregroundColor(theme.colors.textColor)
            }
            
            Spacer()
        }
        .padding(10)
        .background(theme.colors.elevatedCardColor)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

// MARK: - Circular Action Icon Button

public struct ActionIconButtonView: View {
    let title: String
    let iconName: String
    let color: Color
    let action: () -> Void
    
    @ObservedObject private var theme = ThemeManager.shared
    @State private var isPressed = false
    
    public init(title: String, iconName: String, color: Color, action: @escaping () -> Void) {
        self.title = title
        self.iconName = iconName
        self.color = color
        self.action = action
    }
    
    public var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        }) {
            VStack(spacing: 8) {
                Circle()
                    .fill(color)
                    .frame(width: 54, height: 54)
                    .overlay(
                        Image(systemName: iconName)
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.white)
                    )
                    .shadow(color: color.opacity(0.3), radius: 6, x: 0, y: 3)
                
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(theme.colors.textColor)
                    .lineLimit(1)
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

public struct ScaleButtonStyle: ButtonStyle {
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.93 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Custom Progress Bar

public struct CustomProgressBar: View {
    let progress: Double
    let color: Color
    
    public init(progress: Double, color: Color = .blue) {
        self.progress = min(max(progress, 0.0), 1.0)
        self.color = color
    }
    
    public var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.gray.opacity(0.18))
                    .frame(height: 8)
                
                Capsule()
                    .fill(color)
                    .frame(width: proxy.size.width * CGFloat(progress), height: 8)
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: progress)
            }
        }
        .frame(height: 8)
    }
}

// MARK: - Reusable Empty State View

public struct EmptyStateContainer: View {
    let iconName: String
    let title: String
    let subtitle: String
    let buttonTitle: String?
    let action: (() -> Void)?
    
    @ObservedObject private var theme = ThemeManager.shared
    
    public init(iconName: String, title: String, subtitle: String, buttonTitle: String? = nil, action: (() -> Void)? = nil) {
        self.iconName = iconName
        self.title = title
        self.subtitle = subtitle
        self.buttonTitle = buttonTitle
        self.action = action
    }
    
    public var body: some View {
        VStack(spacing: 16) {
            Circle()
                .fill(theme.colors.primaryColor.opacity(0.12))
                .frame(width: 72, height: 72)
                .overlay(
                    Image(systemName: iconName)
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundColor(theme.colors.primaryColor)
                )
            
            Text(title)
                .font(.system(size: 19, weight: .bold))
                .foregroundColor(theme.colors.textColor)
            
            Text(subtitle)
                .font(.system(size: 14))
                .foregroundColor(theme.colors.secondaryTextColor)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            if let bTitle = buttonTitle, let act = action {
                Button(action: {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    act()
                }) {
                    Text(bTitle)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(theme.colors.primaryColor)
                        .clipShape(Capsule())
                }
                .padding(.top, 4)
            }
        }
        .padding(.vertical, 32)
    }
}
