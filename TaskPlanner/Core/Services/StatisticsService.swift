//
//  StatisticsService.swift
//  TaskPlanner
//
//  Created by Лия Форрат on 21.01.26.
//



import Foundation
import CoreData

class StatisticsService {
    static let shared = StatisticsService()
    private let manager = CoreDataManager.shared
    
    private init() {}
    
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
            return try manager.viewContext.count(for: request)
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
            let tasks = try manager.viewContext.fetch(request)
            var counts: [Int16: Int] = [:]
            
            for difficulty in 1...5 {
                counts[Int16(difficulty)] = tasks.filter { $0.difficulty == difficulty }.count
            }
            
            return counts
        } catch {
            print(" \(error)")
            return [:]
        }
    }
    
    func getGoalProgress(for user: User) -> [(goal: Goal, progress: Double)] {
        let goals = manager.getGoals(for: user)
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
