//
//  AIAssistantView.swift
//  BudgetTracker
//
//  Created by ali on 10/10/2026.
//

import SwiftUI

public struct ChatMessage: Identifiable {
    public let id = UUID()
    public let isUser: Bool
    public let text: String
    public let proposedTx: ProposedTransaction?
    public let timestamp: Date = Date()
}

public struct AIAssistantView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var theme = ThemeManager.shared
    @ObservedObject private var currency = CurrencyManager.shared
    
    @State private var inputText: String = ""
    @State private var messages: [ChatMessage] = []
    @State private var addedTransactionIds: Set<UUID> = []
    
    private let promptChips = [
        "Where did I spend the most?",
        "Log: Spent $25 on dinner with card",
        "How much did I save this month?",
        "Where am I overspending?",
        "Log: Paid $60 for gas yesterday"
    ]
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Messages List
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            // Assistant Intro Card
                            assistantIntroCard
                            
                            ForEach(messages) { msg in
                                chatBubble(msg)
                                    .id(msg.id)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                    }
                    .onChange(of: messages.count) { _ in
                        if let last = messages.last {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                proxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }
                }
                
                // Prompt Chips Carousel
                promptChipsCarousel
                
                Divider()
                    .background(theme.colors.separatorColor.opacity(0.3))
                
                // Input Bar
                inputBar
            }
            .background(theme.colors.backgroundColor.ignoresSafeArea())
            .navigationTitle("AI Financial Assistant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        messages.removeAll()
                    }) {
                        Image(systemName: "trash")
                            .font(.system(size: 15))
                    }
                }
            }
            .onAppear {
                if messages.isEmpty {
                    messages.append(ChatMessage(
                        isUser: false,
                        text: "Hello! I am your on-device Financial Assistant. You can ask me questions about your monthly spending, or simply type something like 'Spent $45 on groceries' and I'll log it for you.",
                        proposedTx: nil
                    ))
                }
            }
        }
    }
    
    // MARK: - Assistant Intro Card
    
    private var assistantIntroCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "sparkles")
                .foregroundColor(.purple)
                .font(.system(size: 20))
                .padding(8)
                .background(Color.purple.opacity(0.12))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Private & On-Device")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(theme.colors.textColor)
                
                Text(AIAssistantService.disclaimer)
                    .font(.system(size: 11))
                    .foregroundColor(theme.colors.secondaryTextColor)
                    .lineSpacing(2)
            }
        }
        .padding(12)
        .background(theme.colors.cardColor)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(theme.colors.separatorColor.opacity(0.35), lineWidth: 0.75)
        )
    }
    
    // MARK: - Chat Bubble
    
    private func chatBubble(_ msg: ChatMessage) -> some View {
        HStack(alignment: .bottom, spacing: 8) {
            if msg.isUser {
                Spacer(minLength: 40)
                Text(msg.text)
                    .font(.system(size: 15))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(theme.colors.primaryColor)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            } else {
                Circle()
                    .fill(Color.purple.opacity(0.15))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: "sparkles")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.purple)
                    )
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(msg.text)
                        .font(.system(size: 15))
                        .foregroundColor(theme.colors.textColor)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(theme.colors.cardColor)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(theme.colors.separatorColor.opacity(0.35), lineWidth: 0.75)
                        )
                    
                    if let proposed = msg.proposedTx {
                        proposedTransactionCard(proposed: proposed, messageId: msg.id)
                    }
                }
                
                Spacer(minLength: 40)
            }
        }
    }
    
    // MARK: - Proposed Transaction Card
    
    private func proposedTransactionCard(proposed: ProposedTransaction, messageId: UUID) -> some View {
        let isAdded = addedTransactionIds.contains(messageId)
        
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("PROPOSED TRANSACTION")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(theme.colors.secondaryTextColor)
                    .tracking(0.5)
                
                Spacer()
                
                Text(proposed.category)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(theme.colors.primaryColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(theme.colors.primaryColor.opacity(0.12))
                    .clipShape(Capsule())
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(proposed.title)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(theme.colors.textColor)
                    
                    Text("\(proposed.paymentMethod) • \(formattedDate(proposed.date))")
                        .font(.system(size: 12))
                        .foregroundColor(theme.colors.secondaryTextColor)
                }
                
                Spacer()
                
                Text("-\(currency.format(proposed.amount))")
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(theme.colors.dangerColor)
            }
            
            Divider()
                .background(theme.colors.separatorColor.opacity(0.3))
            
            Button(action: {
                saveProposed(proposed, messageId: messageId)
            }) {
                HStack(spacing: 6) {
                    Image(systemName: isAdded ? "checkmark.circle.fill" : "plus.circle.fill")
                        .font(.system(size: 14))
                    Text(isAdded ? "Added to Transactions" : "Confirm & Save")
                        .font(.system(size: 13, weight: .bold))
                }
                .foregroundColor(isAdded ? theme.colors.successColor : .white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(isAdded ? theme.colors.successColor.opacity(0.12) : theme.colors.primaryColor)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .disabled(isAdded)
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(12)
        .background(theme.colors.elevatedCardColor)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(theme.colors.primaryColor.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - Prompt Chips Carousel
    
    private var promptChipsCarousel: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(promptChips, id: \.self) { chip in
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        sendPrompt(chip)
                    }) {
                        Text(chip)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(theme.colors.textColor)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(theme.colors.cardColor)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(theme.colors.separatorColor.opacity(0.4), lineWidth: 0.5)
                            )
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }
    
    // MARK: - Input Bar
    
    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("Ask anything or log an expense...", text: $inputText)
                .font(.system(size: 15))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(theme.colors.cardColor)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(theme.colors.separatorColor.opacity(0.4), lineWidth: 0.75)
                )
                .onSubmit {
                    handleSubmit()
                }
            
            Button(action: {
                handleSubmit()
            }) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(inputText.trimmingCharacters(in: .whitespaces).isEmpty ? theme.colors.secondaryTextColor.opacity(0.5) : theme.colors.primaryColor)
            }
            .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(theme.colors.backgroundColor)
    }
    
    // MARK: - Handlers
    
    private func handleSubmit() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        inputText = ""
        sendPrompt(text)
    }
    
    private func sendPrompt(_ text: String) {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        
        // Add user message
        messages.append(ChatMessage(isUser: true, text: text, proposedTx: nil))
        
        // Check for proposed expense parsing
        if let proposed = AIAssistantService.shared.parseExpense(text: text) {
            messages.append(ChatMessage(
                isUser: false,
                text: "I detected an expense of \(currency.format(proposed.amount)) for \(proposed.title). Would you like me to record this?",
                proposedTx: proposed
            ))
        } else {
            // Answer general financial query
            let answer = AIAssistantService.shared.answerQuery(text: text)
            messages.append(ChatMessage(isUser: false, text: answer, proposedTx: nil))
        }
    }
    
    private func saveProposed(_ proposed: ProposedTransaction, messageId: UUID) {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        _ = TransactionManager.shared.createTransaction(
            title: proposed.title,
            amount: proposed.amount,
            type: .expense,
            category: proposed.category,
            merchant: nil,
            note: nil,
            date: proposed.date,
            paymentMethod: proposed.paymentMethod
        )
        addedTransactionIds.insert(messageId)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
