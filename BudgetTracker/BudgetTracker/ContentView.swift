//
//  ContentView.swift
//  BudgetTracker
//
//  Created by ali on 10/10/2026.
//

import SwiftUI

public struct ContentView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @StateObject private var auth = BiometricAuthManager.shared
    
    public init() {}
    
    public var body: some View {
        ZStack {
            if !hasCompletedOnboarding {
                OnboardingView {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        hasCompletedOnboarding = true
                    }
                }
            } else {
                MainTabView()
            }
            
            if auth.isLocked {
                LockScreenView()
                    .transition(.opacity)
                    .zIndex(999)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
