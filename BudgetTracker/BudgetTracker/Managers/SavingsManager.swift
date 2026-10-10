//
//  SavingsManager.swift
//  BudgetTracker
//
//  Created by ali on 10/10/2026.
//

import Foundation
import CoreData

public class SavingsManager {
    public static let shared = SavingsManager()
    
    private let coreData = CoreDataManager.shared
    
    private init() {}
    
    @discardableResult
    public func createGoal(
        name: String,
        targetAmount: Double,
        currentAmount: Double = 0.0,
        deadline: Date? = nil,
        icon: String? = "star.fill"
    ) -> SavingsGoalEntity {
        let context = coreData.viewContext
        let goal = SavingsGoalEntity(context: context)
        goal.id = UUID()
        goal.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        goal.targetAmount = targetAmount
        goal.currentAmount = currentAmount
        goal.deadline = deadline
        goal.icon = icon
        goal.createdAt = Date()
        
        coreData.saveContext()
        NotificationCenter.default.post(name: .savingsGoalsDidChange, object: nil)
        return goal
    }
    
    public func addContribution(to goal: SavingsGoalEntity, amount: Double) {
        goal.currentAmount += amount
        coreData.saveContext()
        NotificationCenter.default.post(name: .savingsGoalsDidChange, object: nil)
        
        let remaining = goal.remainingAmount
        if remaining > 0 && remaining <= goal.targetAmount * 0.25 {
            NotificationManager.shared.sendSavingsMilestoneReminder(goalName: goal.name ?? "Goal", remainingAmount: remaining)
        }
    }
    
    public func updateGoal(
        goal: SavingsGoalEntity,
        name: String,
        targetAmount: Double,
        currentAmount: Double,
        deadline: Date?,
        icon: String?
    ) {
        goal.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        goal.targetAmount = targetAmount
        goal.currentAmount = currentAmount
        goal.deadline = deadline
        goal.icon = icon
        
        coreData.saveContext()
        NotificationCenter.default.post(name: .savingsGoalsDidChange, object: nil)
    }
    
    public func deleteGoal(_ goal: SavingsGoalEntity) {
        coreData.viewContext.delete(goal)
        coreData.saveContext()
        NotificationCenter.default.post(name: .savingsGoalsDidChange, object: nil)
    }
    
    public func fetchGoals() -> [SavingsGoalEntity] {
        let request = NSFetchRequest<SavingsGoalEntity>(entityName: "SavingsGoalEntity")
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
        return (try? coreData.viewContext.fetch(request)) ?? []
    }
}

extension Notification.Name {
    public static let savingsGoalsDidChange = Notification.Name("BudgetTracker_SavingsGoalsDidChange")
}
