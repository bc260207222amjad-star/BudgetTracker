//
//  LockScreenView.swift
//  BudgetTracker
//
//  Created by ali on 10/10/2026.
//

import SwiftUI

public struct LockScreenView: View {
    @ObservedObject private var auth = BiometricAuthManager.shared
    @ObservedObject private var theme = ThemeManager.shared
    @State private var isAuthenticating = false
    
    public init() {}
    
    public var body: some View {
        ZStack {
            theme.colors.backgroundColor
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Spacer()
                
                Circle()
                    .fill(Color.blue.opacity(0.12))
                    .frame(width: 96, height: 96)
                    .overlay(
                        Image(systemName: auth.biometryIconName)
                            .font(.system(size: 46))
                            .foregroundColor(.blue)
                    )
                
                VStack(spacing: 8) {
                    Text("BudgetTracker Locked")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(theme.colors.textColor)
                    
                    Text("Unlock using \(auth.biometryTitle) to access your financial data.")
                        .font(.system(size: 15))
                        .foregroundColor(theme.colors.secondaryTextColor)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                
                Spacer()
                
                Button(action: {
                    authenticate()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: auth.biometryIconName)
                        Text("Unlock App")
                    }
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
        .onAppear {
            authenticate()
        }
    }
    
    private func authenticate() {
        guard !isAuthenticating else { return }
        isAuthenticating = true
        auth.authenticate { success in
            isAuthenticating = false
            if success {
                withAnimation(.easeInOut(duration: 0.25)) {
                    auth.isLocked = false
                }
            }
        }
    }
}
