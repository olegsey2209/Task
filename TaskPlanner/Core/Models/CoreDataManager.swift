//
//  CoreDataManager.swift
//  TaskPlanner
//
//  Created by Лия Форрат on 13.12.25.
//

import Foundation
import CoreData
import SwiftUI

#if canImport(WidgetKit)
import WidgetKit
#endif

class CoreDataManager {
    static let shared = CoreDataManager()
        
        let container: NSPersistentContainer
        
        private init() {
            container = NSPersistentContainer(name: "TaskPlannerModel")
            
            if let url = FileManager.default.containerURL(
                forSecurityApplicationGroupIdentifier: "group.com.taskplanner.shared"
            ) {
                let storeURL = url.appendingPathComponent("TaskPlannerModel.sqlite")
                let description = NSPersistentStoreDescription(url: storeURL)
                description.shouldMigrateStoreAutomatically = true
                description.shouldInferMappingModelAutomatically = true
                container.persistentStoreDescriptions = [description]
            }
            
            container.loadPersistentStores { _, error in
                if let error = error {
                    fatalError(" CoreData не загрузилась: \(error)")
                }
                print("CoreData загружена")
            }
            
            container.viewContext.automaticallyMergesChangesFromParent = true
            container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        }
  
    
    var viewContext: NSManagedObjectContext {
        return container.viewContext
    }
    
    func saveContext() {
           let context = container.viewContext
           guard context.hasChanges else { return }
           
           do {
               try context.save()
               print("CoreData сохранена")
               
   
               #if canImport(WidgetKit)
               WidgetCenter.shared.reloadAllTimelines()
               print(" Виджет перезагружен")
               #endif
               
           } catch {
               print(" Ошибка сохранения CoreData: \(error)")
           }
       }
    
    func createUser(username: String, password: String) -> User? {
        let context = viewContext
        let user = User(context: context)
        user.id = UUID()
        user.username = username
        user.password = password
        user.createdAt = Date()
        
        saveContext()
        return user
    }
    
    func getUser(username: String, password: String) -> User? {
        let request: NSFetchRequest<User> = User.fetchRequest()
        request.predicate = NSPredicate(format: "username == %@ AND password == %@", username, password)
        
        do {
            let users = try viewContext.fetch(request)
            return users.first
        } catch {
            print("\(error)")
            return nil
        }
    }
    
    func userExists(username: String) -> Bool {
        let request: NSFetchRequest<User> = User.fetchRequest()
        request.predicate = NSPredicate(format: "username == %@", username)
        
        do {
            let count = try viewContext.count(for: request)
            return count > 0
        } catch {
            print(" \(error)")
            return false
        }
    }
    
    func getCurrentUser() -> User? {
        if let userId = UserDefaults.standard.string(forKey: "currentUserId") {
            let request: NSFetchRequest<User> = User.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", UUID(uuidString: userId)! as CVarArg)
            
            do {
                let users = try viewContext.fetch(request)
                return users.first
            } catch {
                print("\(error)")
            }
        }
        return nil
    }
    
 
    func createTask(
        title: String,
        description: String?,
        imageData: Data?,
        date: Date,
        time: Date?,
        difficulty: Int16,
        hasReminder: Bool,
        user: User
    ) -> Task {

        let task = Task(context: viewContext)
        task.id = UUID()
        task.title = title
        task.taskDescription = description
        task.imageData = imageData
        task.date = date
        task.time = time
        task.difficulty = difficulty
        task.hasReminder = hasReminder
        task.isCompleted = false
        task.user = user

        saveContext()

        DispatchQueue.main.async {
            RefreshManager.shared.refreshTasks()
            RefreshManager.shared.refreshStats()
        }

        return task
    }
    
    func getTasks(for date: Date, user: User) -> [Task] {
        let request: NSFetchRequest<Task> = Task.fetchRequest()
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        request.predicate = NSPredicate(format: "user == %@ AND date >= %@ AND date < %@", user, startOfDay as NSDate, endOfDay as NSDate)
        request.sortDescriptors = [NSSortDescriptor(key: "time", ascending: true)]
        
        do {
            return try viewContext.fetch(request)
        } catch {
            print("задачи: \(error)")
            return []
        }
    }
   
  
        func getTasksForMonth(startDate: Date, endDate: Date, user: User) -> [Task] {
            let request: NSFetchRequest<Task> = Task.fetchRequest()
            request.predicate = NSPredicate(
                format: "user == %@ AND date >= %@ AND date < %@",
                user, startDate as NSDate, endDate as NSDate
            )
            
            do {
                return try viewContext.fetch(request)
            } catch {
                print(" \(error)")
                return []
            }
        }
    
    func getTasksWithSteps(for date: Date, user: User) -> [Task] {
        let tasks = getTasks(for: date, user: user)
        return tasks.filter { $0.goalStep != nil }
    }
    
    func getTasksWithoutSteps(for date: Date, user: User) -> [Task] {
        let tasks = getTasks(for: date, user: user)
        return tasks.filter { $0.goalStep == nil }
    }
    
    func updateTask(_ task: Task, title: String? = nil, date: Date? = nil, time: Date? = nil, difficulty: Int16? = nil, hasReminder: Bool? = nil) {
        let oldReminder = task.hasReminder
        
        if let title = title { task.title = title }
        if let date = date { task.date = date }
        if let time = time { task.time = time }
        if let difficulty = difficulty { task.difficulty = difficulty }
        if let hasReminder = hasReminder { task.hasReminder = hasReminder }
        

        if oldReminder != hasReminder {
            if hasReminder == true {
                NotificationService.shared.scheduleNotification(for: task)
            } else {
                NotificationService.shared.removeNotification(for: task)
            }
        } else if hasReminder == true {
            NotificationService.shared.updateNotification(for: task)
        }
        
        saveContext()
    }
    
    func toggleTaskCompletion(_ task: Task) {
        task.isCompleted.toggle()
        
        if let goalStep = task.goalStep {
            goalStep.isCompleted = task.isCompleted
            goalStep.completedAt = task.isCompleted ? Date() : nil
            
            if task.isCompleted {
                print("выполнена обнов шаг: \(goalStep.title ?? "")")
            }
        }
        
        saveContext()
    }
    
    func deleteTask(_ task: Task) {
        viewContext.delete(task)
        
        DispatchQueue.main.async {
               RefreshManager.shared.refreshTasks()
               RefreshManager.shared.refreshStats()
           }
        saveContext()
    }
    

    func createGoal(title: String, description: String? = nil, user: User) -> Goal {
        let context = viewContext
        let goal = Goal(context: context)
        goal.id = UUID()
        goal.title = title
        goal.goalDescription = description
        goal.user = user
        
        saveContext()
        return goal
    }
    
    func getGoals(for user: User) -> [Goal] {
        let request: NSFetchRequest<Goal> = Goal.fetchRequest()
        request.predicate = NSPredicate(format: "user == %@", user)
        request.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
        
        do {
            return try viewContext.fetch(request)
        } catch {
            print("цели: \(error)")
            return []
        }
    }
    
    func updateGoal(_ goal: Goal, title: String? = nil, description: String? = nil) {
        if let title = title { goal.title = title }
        if let description = description { goal.goalDescription = description }
        
        saveContext()
    }
    
    func deleteGoal(_ goal: Goal) {
        viewContext.delete(goal)
        saveContext()
        
    }
    

    func createGoalStep(title: String, description: String?, goal: Goal) -> GoalStep {
        let context = viewContext
        let step = GoalStep(context: context)
        step.id = UUID()
        step.title = title
        step.stepDescription = description
        step.order = Int16((goal.steps?.count ?? 0))
        step.isCompleted = false
        step.goal = goal
        
        saveContext()
        return step
    }
    
    func updateGoalStep(_ step: GoalStep, title: String? = nil, description: String?) {
        if let title = title { step.title = title }
        step.stepDescription = description
        saveContext()
    }
    
    func deleteGoalStep(_ step: GoalStep) {
        viewContext.delete(step)
        saveContext()
    }
    
    func toggleGoalStepCompletion(_ step: GoalStep) {
        step.isCompleted.toggle()
        step.completedAt = step.isCompleted ? Date() : nil
        
        if let task = step.task, step.isCompleted {
            task.isCompleted = true
        }
        
        saveContext()
    }
    
    func createTaskFromStep(_ step: GoalStep, description: String?, date: Date, time: Date? = nil, difficulty: Int16 = 1, hasReminder: Bool = false,imageData: Data?) -> Task {
        let task = createTask(
            title: (step.title ?? ""),
            description: step.stepDescription,
            imageData: imageData,
            date: date,
            time: time,
            difficulty: difficulty,
            hasReminder: hasReminder,
            user: step.goal!.user!
        )
        
        step.task = task
        task.goalStep = step
        
        
        
        saveContext()
        return task
    }
    
    func getCompletedTasksCount(for period: StatisticsPeriod, user: User) -> Int {
        let request: NSFetchRequest<Task> = Task.fetchRequest()
        
        let calendar = Calendar.current
        let now = Date()
        var startDate: Date
        var endDate: Date
        
        switch period {
        case .day:
            startDate = calendar.startOfDay(for: now)
            endDate = calendar.date(byAdding: .day, value: 1, to: startDate)!
        case .month:
            startDate = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
            endDate = calendar.date(byAdding: .month, value: 1, to: startDate)!
        case .year:
            startDate = calendar.date(from: calendar.dateComponents([.year], from: now))!
            endDate = calendar.date(byAdding: .year, value: 1, to: startDate)!
        }
        
        request.predicate = NSPredicate(
            format: "user == %@ AND isCompleted == YES AND date >= %@ AND date < %@",
            user, startDate as NSDate, endDate as NSDate
        )
        
        do {
            return try viewContext.count(for: request)
        } catch {
            print(" \(error)")
            return 0
        }
    }
    
    func getTaskCountByDifficulty(for period: StatisticsPeriod, user: User) -> [Int16: Int] {
        let request: NSFetchRequest<Task> = Task.fetchRequest()
        
        let calendar = Calendar.current
        let now = Date()
        var startDate: Date
        var endDate: Date
        
        switch period {
        case .day:
            startDate = calendar.startOfDay(for: now)
            endDate = calendar.date(byAdding: .day, value: 1, to: startDate)!
        case .month:
            startDate = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
            endDate = calendar.date(byAdding: .month, value: 1, to: startDate)!
        case .year:
            startDate = calendar.date(from: calendar.dateComponents([.year], from: now))!
            endDate = calendar.date(byAdding: .year, value: 1, to: startDate)!
        }
        
        request.predicate = NSPredicate(
            format: "user == %@ AND date >= %@ AND date < %@",
            user, startDate as NSDate, endDate as NSDate
        )
        
        do {
            let tasks = try viewContext.fetch(request)
            var counts: [Int16: Int] = [:]
            
            for difficulty in 1...5 {
                counts[Int16(difficulty)] = tasks.filter { $0.difficulty == difficulty }.count
            }
            
            return counts
        } catch {
            print("\(error)")
            return [:]
        }
    }
    
    func getGoalProgress(for user: User) -> [(goal: Goal, progress: Double)] {
        let goals = getGoals(for: user)
        var result: [(goal: Goal, progress: Double)] = []
        
        for goal in goals {
            if let steps = goal.steps?.array as? [GoalStep] {
                let totalSteps = steps.count
                let completedSteps = steps.filter { $0.isCompleted }.count
                let progress = totalSteps > 0 ? Double(completedSteps) / Double(totalSteps) : 0
                result.append((goal, progress))
            }
        }
        
        return result
    }
    
}

enum StatisticsPeriod {
    case day, month, year
}
