//
//  OnboardingView.swift
//  BudgetTracker
//
//  Created by ali on 10/10/2026.
//

import SwiftUI

public struct OnboardingView: View {
    public let onComplete: () -> Void
    
    @State private var currentPage = 0
    @State private var selectedCurrencyCode: String = CurrencyManager.shared.currentCurrency.code
    @State private var enableBiometrics: Bool = false
    @State private var searchText: String = ""
    
    @ObservedObject private var theme = ThemeManager.shared
    
    public init(onComplete: @escaping () -> Void) {
        self.onComplete = onComplete
    }
    
    public var body: some View {
        ZStack {
            theme.colors.backgroundColor
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header Bar (Skip Button)
                HStack {
                    Spacer()
                    if currentPage < 3 {
                        Button(action: {
                            finish(loadSample: false)
                        }) {
                            Text("Skip")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(theme.colors.secondaryTextColor)
                                .padding(.horizontal, 20)
                                .padding(.top, 12)
                        }
                    } else {
                        Color.clear.frame(height: 32)
                    }
                }
                
                // Paging Tabs
                TabView(selection: $currentPage) {
                    welcomeSlide
                        .tag(0)
                    
                    currencySlide
                        .tag(1)
                    
                    securitySlide
                        .tag(2)
                    
                    readySlide
                        .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // Bottom Controls
                VStack(spacing: 16) {
                    // Page Indicator Dots
                    HStack(spacing: 8) {
                        ForEach(0..<4) { index in
                            Capsule()
                                .fill(currentPage == index ? theme.colors.primaryColor : theme.colors.separatorColor.opacity(0.6))
                                .frame(width: currentPage == index ? 22 : 8, height: 8)
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPage)
                        }
                    }
                    .padding(.top, 8)
                    
                    if currentPage < 3 {
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            withAnimation {
                                currentPage += 1
                            }
                        }) {
                            Text("Continue")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                                .background(theme.colors.primaryColor)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .padding(.horizontal, 24)
                    }
                }
                .padding(.bottom, 24)
            }
        }
    }
    
    // MARK: - Slide 1: Welcome
    
    private var welcomeSlide: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer().frame(height: 12)
                
                // App Logo
                Circle()
                    .fill(Color.blue.opacity(0.12))
                    .frame(width: 84, height: 84)
                    .overlay(
                        Image(systemName: "wallet.pass.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.blue)
                    )
                
                VStack(spacing: 6) {
                    Text("BudgetTracker")
                        .font(.system(size: 32, weight: .heavy, design: .rounded))
                        .foregroundColor(theme.colors.textColor)
                    
                    Text("Private, intelligent budgeting made effortless.")
                        .font(.system(size: 16))
                        .foregroundColor(theme.colors.secondaryTextColor)
                        .multilineTextAlignment(.center)
                }
                
                VStack(spacing: 16) {
                    featureRow(
                        icon: "lock.shield.fill",
                        color: .green,
                        title: "100% Offline & Private",
                        desc: "Financial data is persisted locally via Core Data. No servers, no tracking."
                    )
                    
                    featureRow(
                        icon: "chart.line.uptrend.xyaxis",
                        color: .blue,
                        title: "Interactive Swift Charts",
                        desc: "Monitor cash flows, donut category breakdowns, and monthly trends."
                    )
                    
                    featureRow(
                        icon: "doc.viewfinder.fill",
                        color: .orange,
                        title: "Receipt Scanning & AI",
                        desc: "Extract totals instantly with Vision OCR and get on-device smart budget guidance."
                    )
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)
            }
        }
    }
    
    private func featureRow(icon: String, color: Color, title: String, desc: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(theme.colors.textColor)
                
                Text(desc)
                    .font(.system(size: 13))
                    .foregroundColor(theme.colors.secondaryTextColor)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(14)
        .background(theme.colors.cardColor)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
    
    // MARK: - Slide 2: Currency
    
    private var currencySlide: some View {
        VStack(spacing: 16) {
            VStack(spacing: 6) {
                Text("Select Currency")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(theme.colors.textColor)
                
                Text("We will format all transactions and budgets in your chosen currency.")
                    .font(.system(size: 14))
                    .foregroundColor(theme.colors.secondaryTextColor)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            .padding(.top, 12)
            
            List {
                ForEach(CurrencyInfo.supportedCurrencies, id: \.code) { item in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.name)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(theme.colors.textColor)
                            Text(item.code)
                                .font(.system(size: 12))
                                .foregroundColor(theme.colors.secondaryTextColor)
                        }
                        
                        Spacer()
                        
                        Text(item.symbol.trimmingCharacters(in: .whitespaces))
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(theme.colors.textColor)
                        
                        if selectedCurrencyCode == item.code {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                                .font(.system(size: 14, weight: .bold))
                                .padding(.leading, 8)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        selectedCurrencyCode = item.code
                        CurrencyManager.shared.setCurrency(code: item.code)
                    }
                    .listRowBackground(theme.colors.cardColor)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
        }
    }
    
    // MARK: - Slide 3: Security
    
    private var securitySlide: some View {
        VStack(spacing: 24) {
            Spacer().frame(height: 24)
            
            Circle()
                .fill(Color.green.opacity(0.12))
                .frame(width: 88, height: 88)
                .overlay(
                    Image(systemName: "faceid")
                        .font(.system(size: 44))
                        .foregroundColor(.green)
                )
            
            VStack(spacing: 8) {
                Text("Protect Your Privacy")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(theme.colors.textColor)
                
                Text("Lock BudgetTracker with Face ID, Touch ID, or Passcode. Your screen is automatically blurred when switching apps.")
                    .font(.system(size: 14))
                    .foregroundColor(theme.colors.secondaryTextColor)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            CardContainer {
                Toggle(isOn: $enableBiometrics) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Enable Biometric App Lock")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(theme.colors.textColor)
                        
                        Text("Requires Face ID / Touch ID on launch")
                            .font(.system(size: 12))
                            .foregroundColor(theme.colors.secondaryTextColor)
                    }
                }
                .tint(.green)
            }
            .padding(.horizontal, 24)
            
            Spacer()
        }
    }
    
    // MARK: - Slide 4: Ready
    
    private var readySlide: some View {
        VStack(spacing: 24) {
            Spacer().frame(height: 24)
            
            Circle()
                .fill(Color.blue.opacity(0.12))
                .frame(width: 88, height: 88)
                .overlay(
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 46))
                        .foregroundColor(.blue)
                )
            
            VStack(spacing: 8) {
                Text("You're All Set!")
                    .font(.system(size: 28, weight: .heavy))
                    .foregroundColor(theme.colors.textColor)
                
                Text("How would you like to start your budgeting journey?")
                    .font(.system(size: 15))
                    .foregroundColor(theme.colors.secondaryTextColor)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            
            VStack(spacing: 14) {
                // Explore with sample data
                Button(action: {
                    finish(loadSample: true)
                }) {
                    HStack {
                        Image(systemName: "sparkles")
                        Text("Explore with Sample Data (Recommended)")
                    }
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Color.blue.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.blue.opacity(0.35), lineWidth: 1)
                    )
                }
                
                // Start fresh
                Button(action: {
                    finish(loadSample: false)
                }) {
                    Text("Start Fresh (Blank Database)")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(theme.colors.textColor)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(theme.colors.cardColor)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(theme.colors.separatorColor.opacity(0.4), lineWidth: 1)
                        )
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            
            Spacer()
        }
    }
    
    private func finish(loadSample: Bool) {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        UserDefaults.standard.set(true, forKey: "BudgetTracker_HasCompletedOnboarding")
        CurrencyManager.shared.setCurrency(code: selectedCurrencyCode)
        
        if enableBiometrics {
            BiometricAuthManager.shared.isBiometricsEnabled = true
        }
        
        if loadSample {
            SampleDataLoader.shared.loadRealisticSampleData()
        } else {
            AccountManager.shared.ensureDefaultAccountsExist()
        }
        
        onComplete()
    }
}
