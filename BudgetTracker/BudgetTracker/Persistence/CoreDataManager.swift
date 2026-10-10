//
//  CoreDataManager.swift
//  BudgetTracker
//
//  Created by ali on 10/10/2026.
//

import Foundation
import CoreData

public class CoreDataManager {
    public static let shared = CoreDataManager()
    
    public let persistentContainer: NSPersistentContainer
    
    public var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    public init(inMemory: Bool = false) {
        let model = Self.createManagedObjectModel()
        persistentContainer = NSPersistentContainer(name: "BudgetTrackerModel", managedObjectModel: model)
        
        if inMemory {
            let description = NSPersistentStoreDescription()
            description.type = NSInMemoryStoreType
            persistentContainer.persistentStoreDescriptions = [description]
        } else {
            let storeURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
                .appendingPathComponent("BudgetTracker.sqlite")
            
            // Ensure application support directory exists
            try? FileManager.default.createDirectory(at: storeURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            
            let description = NSPersistentStoreDescription(url: storeURL)
            description.shouldMigrateStoreAutomatically = true
            description.shouldInferMappingModelAutomatically = true
            persistentContainer.persistentStoreDescriptions = [description]
        }
        
        persistentContainer.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Failed to load Core Data persistent stores: \(error.localizedDescription)")
            }
        }
        
        persistentContainer.viewContext.automaticallyMergesChangesFromParent = true
        persistentContainer.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
    // MARK: - Save Context
    
    public func saveContext() {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                print("CoreDataManager saveContext error: \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    public func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        persistentContainer.performBackgroundTask { context in
            context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            block(context)
            if context.hasChanges {
                try? context.save()
            }
        }
    }
    
    public func deleteAllData() {
        let entityNames = [
            "TransactionEntity",
            "BudgetEntity",
            "SavingsGoalEntity",
            "AccountEntity",
            "RecurringTransactionEntity",
            "DebtEntity"
        ]
        
        let context = persistentContainer.viewContext
        for entityName in entityNames {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            do {
                try context.execute(deleteRequest)
            } catch {
                // Fallback to fetch and delete
                let fetch = NSFetchRequest<NSManagedObject>(entityName: entityName)
                if let objects = try? context.fetch(fetch) {
                    for obj in objects {
                        context.delete(obj)
                    }
                }
            }
        }
        saveContext()
    }
    
    // MARK: - Programmatic Managed Object Model
    
    private static func createManagedObjectModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()
        
        // 1. TransactionEntity
        let transactionEntity = NSEntityDescription()
        transactionEntity.name = "TransactionEntity"
        transactionEntity.managedObjectClassName = NSStringFromClass(TransactionEntity.self)
        
        let tId = NSAttributeDescription()
        tId.name = "id"
        tId.attributeType = .UUIDAttributeType
        tId.isOptional = true
        
        let tAmount = NSAttributeDescription()
        tAmount.name = "amount"
        tAmount.attributeType = .doubleAttributeType
        tAmount.isOptional = false
        tAmount.defaultValue = 0.0
        
        let tType = NSAttributeDescription()
        tType.name = "type"
        tType.attributeType = .stringAttributeType
        tType.isOptional = true
        
        let tCategory = NSAttributeDescription()
        tCategory.name = "category"
        tCategory.attributeType = .stringAttributeType
        tCategory.isOptional = true
        
        let tTitle = NSAttributeDescription()
        tTitle.name = "title"
        tTitle.attributeType = .stringAttributeType
        tTitle.isOptional = true
        
        let tMerchant = NSAttributeDescription()
        tMerchant.name = "merchant"
        tMerchant.attributeType = .stringAttributeType
        tMerchant.isOptional = true
        
        let tNote = NSAttributeDescription()
        tNote.name = "note"
        tNote.attributeType = .stringAttributeType
        tNote.isOptional = true
        
        let tDate = NSAttributeDescription()
        tDate.name = "date"
        tDate.attributeType = .dateAttributeType
        tDate.isOptional = true
        
        let tPaymentMethod = NSAttributeDescription()
        tPaymentMethod.name = "paymentMethod"
        tPaymentMethod.attributeType = .stringAttributeType
        tPaymentMethod.isOptional = true
        
        let tReceiptPath = NSAttributeDescription()
        tReceiptPath.name = "receiptImagePath"
        tReceiptPath.attributeType = .stringAttributeType
        tReceiptPath.isOptional = true
        
        let tIsRecurring = NSAttributeDescription()
        tIsRecurring.name = "isRecurring"
        tIsRecurring.attributeType = .booleanAttributeType
        tIsRecurring.isOptional = false
        tIsRecurring.defaultValue = false
        
        let tRecurringRule = NSAttributeDescription()
        tRecurringRule.name = "recurringRule"
        tRecurringRule.attributeType = .stringAttributeType
        tRecurringRule.isOptional = true
        
        let tCreatedAt = NSAttributeDescription()
        tCreatedAt.name = "createdAt"
        tCreatedAt.attributeType = .dateAttributeType
        tCreatedAt.isOptional = true
        
        let tAccountId = NSAttributeDescription()
        tAccountId.name = "accountId"
        tAccountId.attributeType = .UUIDAttributeType
        tAccountId.isOptional = true
        
        let tTransferToAccountId = NSAttributeDescription()
        tTransferToAccountId.name = "transferToAccountId"
        tTransferToAccountId.attributeType = .UUIDAttributeType
        tTransferToAccountId.isOptional = true
        
        transactionEntity.properties = [
            tId, tAmount, tType, tCategory, tTitle, tMerchant, tNote,
            tDate, tPaymentMethod, tReceiptPath, tIsRecurring, tRecurringRule,
            tCreatedAt, tAccountId, tTransferToAccountId
        ]
        
        // 2. BudgetEntity
        let budgetEntity = NSEntityDescription()
        budgetEntity.name = "BudgetEntity"
        budgetEntity.managedObjectClassName = NSStringFromClass(BudgetEntity.self)
        
        let bId = NSAttributeDescription()
        bId.name = "id"
        bId.attributeType = .UUIDAttributeType
        bId.isOptional = true
        
        let bName = NSAttributeDescription()
        bName.name = "name"
        bName.attributeType = .stringAttributeType
        bName.isOptional = true
        
        let bCategory = NSAttributeDescription()
        bCategory.name = "category"
        bCategory.attributeType = .stringAttributeType
        bCategory.isOptional = true
        
        let bLimit = NSAttributeDescription()
        bLimit.name = "limit"
        bLimit.attributeType = .doubleAttributeType
        bLimit.isOptional = false
        bLimit.defaultValue = 0.0
        
        let bMonth = NSAttributeDescription()
        bMonth.name = "month"
        bMonth.attributeType = .dateAttributeType
        bMonth.isOptional = true
        
        let bAlert50 = NSAttributeDescription()
        bAlert50.name = "alert50Enabled"
        bAlert50.attributeType = .booleanAttributeType
        bAlert50.isOptional = false
        bAlert50.defaultValue = true
        
        let bAlert75 = NSAttributeDescription()
        bAlert75.name = "alert75Enabled"
        bAlert75.attributeType = .booleanAttributeType
        bAlert75.isOptional = false
        bAlert75.defaultValue = true
        
        let bAlert90 = NSAttributeDescription()
        bAlert90.name = "alert90Enabled"
        bAlert90.attributeType = .booleanAttributeType
        bAlert90.isOptional = false
        bAlert90.defaultValue = true
        
        let bCreatedAt = NSAttributeDescription()
        bCreatedAt.name = "createdAt"
        bCreatedAt.attributeType = .dateAttributeType
        bCreatedAt.isOptional = true
        
        budgetEntity.properties = [bId, bName, bCategory, bLimit, bMonth, bAlert50, bAlert75, bAlert90, bCreatedAt]
        
        // 3. SavingsGoalEntity
        let savingsEntity = NSEntityDescription()
        savingsEntity.name = "SavingsGoalEntity"
        savingsEntity.managedObjectClassName = NSStringFromClass(SavingsGoalEntity.self)
        
        let sId = NSAttributeDescription()
        sId.name = "id"
        sId.attributeType = .UUIDAttributeType
        sId.isOptional = true
        
        let sName = NSAttributeDescription()
        sName.name = "name"
        sName.attributeType = .stringAttributeType
        sName.isOptional = true
        
        let sTarget = NSAttributeDescription()
        sTarget.name = "targetAmount"
        sTarget.attributeType = .doubleAttributeType
        sTarget.isOptional = false
        sTarget.defaultValue = 0.0
        
        let sCurrent = NSAttributeDescription()
        sCurrent.name = "currentAmount"
        sCurrent.attributeType = .doubleAttributeType
        sCurrent.isOptional = false
        sCurrent.defaultValue = 0.0
        
        let sDeadline = NSAttributeDescription()
        sDeadline.name = "deadline"
        sDeadline.attributeType = .dateAttributeType
        sDeadline.isOptional = true
        
        let sCreatedAt = NSAttributeDescription()
        sCreatedAt.name = "createdAt"
        sCreatedAt.attributeType = .dateAttributeType
        sCreatedAt.isOptional = true
        
        let sIcon = NSAttributeDescription()
        sIcon.name = "icon"
        sIcon.attributeType = .stringAttributeType
        sIcon.isOptional = true
        
        savingsEntity.properties = [sId, sName, sTarget, sCurrent, sDeadline, sCreatedAt, sIcon]
        
        // 4. AccountEntity
        let accountEntity = NSEntityDescription()
        accountEntity.name = "AccountEntity"
        accountEntity.managedObjectClassName = NSStringFromClass(AccountEntity.self)
        
        let aId = NSAttributeDescription()
        aId.name = "id"
        aId.attributeType = .UUIDAttributeType
        aId.isOptional = true
        
        let aName = NSAttributeDescription()
        aName.name = "name"
        aName.attributeType = .stringAttributeType
        aName.isOptional = true
        
        let aType = NSAttributeDescription()
        aType.name = "type"
        aType.attributeType = .stringAttributeType
        aType.isOptional = true
        
        let aBalance = NSAttributeDescription()
        aBalance.name = "balance"
        aBalance.attributeType = .doubleAttributeType
        aBalance.isOptional = false
        aBalance.defaultValue = 0.0
        
        let aCreatedAt = NSAttributeDescription()
        aCreatedAt.name = "createdAt"
        aCreatedAt.attributeType = .dateAttributeType
        aCreatedAt.isOptional = true
        
        let aIsDefault = NSAttributeDescription()
        aIsDefault.name = "isDefault"
        aIsDefault.attributeType = .booleanAttributeType
        aIsDefault.isOptional = false
        aIsDefault.defaultValue = false
        
        accountEntity.properties = [aId, aName, aType, aBalance, aCreatedAt, aIsDefault]
        
        // 5. RecurringTransactionEntity
        let recurringEntity = NSEntityDescription()
        recurringEntity.name = "RecurringTransactionEntity"
        recurringEntity.managedObjectClassName = NSStringFromClass(RecurringTransactionEntity.self)
        
        let rId = NSAttributeDescription()
        rId.name = "id"
        rId.attributeType = .UUIDAttributeType
        rId.isOptional = true
        
        let rTitle = NSAttributeDescription()
        rTitle.name = "title"
        rTitle.attributeType = .stringAttributeType
        rTitle.isOptional = true
        
        let rAmount = NSAttributeDescription()
        rAmount.name = "amount"
        rAmount.attributeType = .doubleAttributeType
        rAmount.isOptional = false
        rAmount.defaultValue = 0.0
        
        let rType = NSAttributeDescription()
        rType.name = "type"
        rType.attributeType = .stringAttributeType
        rType.isOptional = true
        
        let rCategory = NSAttributeDescription()
        rCategory.name = "category"
        rCategory.attributeType = .stringAttributeType
        rCategory.isOptional = true
        
        let rFrequency = NSAttributeDescription()
        rFrequency.name = "frequency"
        rFrequency.attributeType = .stringAttributeType
        rFrequency.isOptional = true
        
        let rNextDate = NSAttributeDescription()
        rNextDate.name = "nextDate"
        rNextDate.attributeType = .dateAttributeType
        rNextDate.isOptional = true
        
        let rIsEnabled = NSAttributeDescription()
        rIsEnabled.name = "isEnabled"
        rIsEnabled.attributeType = .booleanAttributeType
        rIsEnabled.isOptional = false
        rIsEnabled.defaultValue = true
        
        let rCreatedAt = NSAttributeDescription()
        rCreatedAt.name = "createdAt"
        rCreatedAt.attributeType = .dateAttributeType
        rCreatedAt.isOptional = true
        
        let rAccountId = NSAttributeDescription()
        rAccountId.name = "accountId"
        rAccountId.attributeType = .UUIDAttributeType
        rAccountId.isOptional = true
        
        recurringEntity.properties = [rId, rTitle, rAmount, rType, rCategory, rFrequency, rNextDate, rIsEnabled, rCreatedAt, rAccountId]
        
        // 6. DebtEntity
        let debtEntity = NSEntityDescription()
        debtEntity.name = "DebtEntity"
        debtEntity.managedObjectClassName = NSStringFromClass(DebtEntity.self)
        
        let dId = NSAttributeDescription()
        dId.name = "id"
        dId.attributeType = .UUIDAttributeType
        dId.isOptional = true
        
        let dName = NSAttributeDescription()
        dName.name = "name"
        dName.attributeType = .stringAttributeType
        dName.isOptional = true
        
        let dTotal = NSAttributeDescription()
        dTotal.name = "totalAmount"
        dTotal.attributeType = .doubleAttributeType
        dTotal.isOptional = false
        dTotal.defaultValue = 0.0
        
        let dRemaining = NSAttributeDescription()
        dRemaining.name = "remainingAmount"
        dRemaining.attributeType = .doubleAttributeType
        dRemaining.isOptional = false
        dRemaining.defaultValue = 0.0
        
        let dInterest = NSAttributeDescription()
        dInterest.name = "interestRate"
        dInterest.attributeType = .doubleAttributeType
        dInterest.isOptional = false
        dInterest.defaultValue = 0.0
        
        let dMinPayment = NSAttributeDescription()
        dMinPayment.name = "minimumPayment"
        dMinPayment.attributeType = .doubleAttributeType
        dMinPayment.isOptional = false
        dMinPayment.defaultValue = 0.0
        
        let dDueDate = NSAttributeDescription()
        dDueDate.name = "dueDate"
        dDueDate.attributeType = .dateAttributeType
        dDueDate.isOptional = true
        
        let dCreatedAt = NSAttributeDescription()
        dCreatedAt.name = "createdAt"
        dCreatedAt.attributeType = .dateAttributeType
        dCreatedAt.isOptional = true
        
        let dDebtType = NSAttributeDescription()
        dDebtType.name = "debtType"
        dDebtType.attributeType = .stringAttributeType
        dDebtType.isOptional = true
        
        debtEntity.properties = [dId, dName, dTotal, dRemaining, dInterest, dMinPayment, dDueDate, dCreatedAt, dDebtType]
        
        model.entities = [transactionEntity, budgetEntity, savingsEntity, accountEntity, recurringEntity, debtEntity]
        return model
    }
}
