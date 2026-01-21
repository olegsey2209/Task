//
//  TasksViewModel.swift
//  TaskPlanner
//
//  Created by Лия Форрат on 13.12.25.
//

import Foundation
import SwiftUI
import CoreData
import Combine
import WidgetKit

struct WidgetTask: Codable {
    let id: UUID
    let title: String
    let difficulty: Int
    let isCompleted: Bool
}

class TasksViewModel: ObservableObject {
    @Published var selectedDate = Date()
    @Published var tasks: [Task] = []
    @Published var showingTaskForm = false
    @Published var showingCalendar = false
    @Published var editingTask: Task?
    @Published var selectedTask: Task?
    @Published var showingTaskDetail = false
    
    private let appGroupID = "group.com.taskplanner.shared"
    struct TodayTask {
        let title: String
    }
    private let manager = CoreDataManager.shared
     private let refreshManager = RefreshManager.shared
     private var currentUser: User?
     private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadCurrentUser()
        loadTasks()
        refreshManager.$refreshTasksID
                  .sink { [weak self] _ in
                      self?.loadTasks()
                  }
                  .store(in: &cancellables)
    }
    
    private func loadCurrentUser() {
        currentUser = manager.getCurrentUser()
    }
    
    func loadTasks() {
           guard let user = currentUser else {
               print("юзер не выбран")
               tasks = []
               return
           }
           
           let calendar = Calendar.current
           let startOfDay = calendar.startOfDay(for: selectedDate)
           let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
           
           let request: NSFetchRequest<Task> = Task.fetchRequest()
           request.predicate = NSPredicate(
               format: "user == %@ AND date >= %@ AND date < %@",
               user, startOfDay as NSDate, endOfDay as NSDate
           )
           request.sortDescriptors = [NSSortDescriptor(key: "time", ascending: true)]
           
           do {
               let fetchedTasks = try manager.viewContext.fetch(request)
               withAnimation(.spring()) {
                   self.tasks = fetchedTasks
               }
           } catch {
               print("\(error)")
               tasks = []
           }
       }
        

    
    func createTask(title: String, description: String?,
                    imageData: Data?, date: Date, time: Date?, difficulty: Int16, hasReminder: Bool) {
           guard let user = currentUser else { return }
           
           let task = manager.createTask(
               title: title,
               description: description,
                      imageData: imageData,
               date: date,
               time: time,
               difficulty: difficulty,
               hasReminder: hasReminder,
               user: user
           )
           
           if hasReminder {
               NotificationService.shared.scheduleNotification(for: task)
           }
           
           refreshManager.refreshTasks()
           refreshManager.refreshGoals()
        updateWidget()
       }
       
    
    func updateTask(_ task: Task, title: String,  description: String?,
                    imageData: Data?,date: Date, time: Date?, difficulty: Int16, hasReminder: Bool) {
        let oldReminder = task.hasReminder
        task.title = title
        task.taskDescription = description
        task.imageData = imageData
        task.date = date
        task.time = time
        task.difficulty = difficulty
        task.hasReminder = hasReminder && (time != nil)

        if oldReminder != task.hasReminder {
            if task.hasReminder {
                NotificationService.shared.scheduleNotification(for: task)
            } else {
                NotificationService.shared.removeNotification(for: task)
            }
        } else if task.hasReminder {
            NotificationService.shared.updateNotification(for: task)
        }
        manager.saveContext()
        updateWidget()
        DispatchQueue.main.async {
            self.refreshManager.refreshTasks()
            self.objectWillChange.send()
        }
    }

    
    func selectToday() {
          selectedDate = Date()
          loadTasks()
      }
      
    func toggleTaskCompletion(_ task: Task) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            task.isCompleted.toggle()
            if let step = task.goalStep {
                step.isCompleted = task.isCompleted
                step.completedAt = task.isCompleted ? Date() : nil
            }
            manager.saveContext()
            updateWidget()
            refreshManager.refreshTasks()
            refreshManager.refreshGoals()
        }
    }
    
    func deleteTask(_ task: Task) {
         if task.hasReminder {
             NotificationService.shared.removeNotification(for: task)
         }
         
         manager.deleteTask(task)
         refreshManager.refreshTasks()
         refreshManager.refreshGoals()
        updateWidget()
     }
    
    func moveTask(_ task: Task, to date: Date) {
        manager.updateTask(task, date: date)
        loadTasks()
    }
    
    func selectDate(_ date: Date) {
        withAnimation(.spring()) {
            selectedDate = date
            loadTasks()
            showingCalendar = false
        }
    }
    
    func startEditing(_ task: Task) {
           editingTask = task
           showingTaskForm = true
           showingTaskDetail = false
       }
    func showDetail(for task: Task) {
        selectedTask = task
        showingTaskDetail = true
    }
    func refreshTask(_ task: Task) {
       
        if let context = task.managedObjectContext {
            context.refresh(task, mergeChanges: true)
        }
        updateWidget()
    }
    private func updateWidget() {
        guard let user = currentUser else { return }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let request: NSFetchRequest<Task> = Task.fetchRequest()
        request.predicate = NSPredicate(
            format: "user == %@ AND date >= %@ AND date < %@",
            user,
            startOfDay as NSDate,
            endOfDay as NSDate
        )
        request.sortDescriptors = [NSSortDescriptor(key: "time", ascending: true)]

        let tasks = (try? manager.viewContext.fetch(request)) ?? []

        let widgetTasks = tasks.map {
            WidgetTask(
                id: $0.id ?? UUID(),
                title: $0.title ?? "",
                difficulty: Int($0.difficulty),
                isCompleted: $0.isCompleted
            )
        }

        let data = try? JSONEncoder().encode(widgetTasks)

        UserDefaults(suiteName: "group.com.taskplanner.shared")?
            .set(data, forKey: "widget_tasks")

        WidgetCenter.shared.reloadTimelines(ofKind: "DailyTasksWidget")
    }
}
