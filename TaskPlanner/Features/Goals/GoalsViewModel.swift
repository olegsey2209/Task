//
//  GoalsViewModel.swift
//  TaskPlanner
//
//  Created by Лия Форрат on 13.12.25.
//

import Foundation
import SwiftUI
import CoreData
import Combine

class GoalsViewModel: ObservableObject {
    @Published var goals: [Goal] = []
    @Published var showingGoalForm = false
    @Published var showingStepForm = false
    @Published var expandedGoal: Goal?
    @Published var editingGoal: Goal?
    @Published var selectedGoalForStep: Goal?
    
    private let manager = CoreDataManager.shared
    private let refreshManager = RefreshManager.shared
    private var currentUser: User?
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadCurrentUser()
        loadGoals()

        refreshManager.$refreshGoalsID
            .sink { [weak self] _ in
                self?.loadGoals()
            }
            .store(in: &cancellables)
    }
    
    private func loadCurrentUser() {
        currentUser = manager.getCurrentUser()
    }
    
    func loadGoals() {
        guard let user = currentUser else { return }
        let goals = manager.getGoals(for: user)
        withAnimation(.spring()) {
            self.goals = goals
        }
    }
    
    func createGoal(title: String, description: String?) {
        guard let user = currentUser else { return }
        
        _ = manager.createGoal(title: title, description: description, user: user)
        refreshManager.refreshGoals()
    }
    
    func updateGoal(_ goal: Goal, title: String, description: String?) {
        manager.updateGoal(goal, title: title, description: description)
        refreshManager.refreshGoals()
    }
    
    func deleteGoal(_ goal: Goal) {
        manager.deleteGoal(goal)
        refreshManager.refreshGoals()
    }
    
    func createStep(for goal: Goal, title: String, description: String?) {
        _ = manager.createGoalStep(title: title, description: description, goal: goal)
        refreshManager.refreshGoals()
    }
    
    func updateStep(_ step: GoalStep, title: String, description: String?) {

        manager.updateGoalStep(step, title: title, description: description)

        if let task = step.task {
            task.title = title
            task.taskDescription = description
            manager.saveContext()
            if task.hasReminder {
                NotificationService.shared.updateNotification(for: task)
            }
        }
        
        refreshManager.refreshGoals()
        refreshManager.refreshTasks()
  
    }
    
    func deleteStep(_ step: GoalStep) {
            let task = step.task
            step.task = nil
            task?.goalStep = nil
            manager.deleteGoalStep(step)
            manager.saveContext()
       
        refreshManager.refreshGoals()
        refreshManager.refreshTasks()
    }
    
    func toggleStepCompletion(_ step: GoalStep) {
        withAnimation(.spring()) {
            step.isCompleted.toggle()
            step.completedAt = step.isCompleted ? Date() : nil

            if let task = step.task {
                task.isCompleted = step.isCompleted
                
            }
            
            manager.saveContext()
            refreshManager.refreshGoals()
            refreshManager.refreshTasks()
        }
    }
    
    func createTaskFromStep(
        _ step: GoalStep,
        description: String?,
        date: Date,
        time: Date?,
        difficulty: Int16,
        hasReminder: Bool,
        imageData: Data?
    ) -> Task {

        let task = manager.createTask(
            title: step.title ?? "",
            description: description, 
            imageData: imageData,
            date: date,
            time: time,
            difficulty: difficulty,
            hasReminder: hasReminder,
            user: step.goal!.user!
        )

        task.goalStep = step
        step.task = task

        manager.saveContext()
        refreshManager.refreshTasks()
        refreshManager.refreshGoals()
      
        

        return task
    }
    func deleteTaskFromStep(_ step: GoalStep) {
        guard let task = step.task else { return }
 
        if task.hasReminder {
            NotificationService.shared.removeNotification(for: task)
        }

        step.task = nil
        task.goalStep = nil

        CoreDataManager.shared.viewContext.delete(task)
        CoreDataManager.shared.saveContext()

        refreshManager.refreshTasks()
        refreshManager.refreshGoals()
    }
    func getProgress(for goal: Goal) -> Double {
        guard let steps = goal.steps?.array as? [GoalStep] else { return 0 }
        let completedSteps = steps.filter { $0.isCompleted }.count
        return steps.isEmpty ? 0 : Double(completedSteps) / Double(steps.count)
    }
   
}
