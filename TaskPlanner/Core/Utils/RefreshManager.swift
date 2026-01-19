//
//  RefreshManager.swift
//  TaskPlanner
//
//  Created by Лия Форрат on 13.12.25.
//

import Foundation
import SwiftUI
import Combine

class RefreshManager: ObservableObject {
    static let shared = RefreshManager()
    
    @Published var refreshID = UUID()
    @Published var refreshGoalsID = UUID()
    @Published var refreshTasksID = UUID()
    @Published var refreshStatsID = UUID() 
    
    private init() {}
    
    func refreshAll() {
        DispatchQueue.main.async {
            self.refreshID = UUID()
            self.refreshGoalsID = UUID()
            self.refreshTasksID = UUID()
            self.refreshStatsID = UUID()
        }
    }
    
    func refreshGoals() {
        DispatchQueue.main.async {
            self.refreshGoalsID = UUID()
            self.refreshStatsID = UUID()
        }
    }
    
    func refreshTasks() {
        DispatchQueue.main.async {
            self.refreshTasksID = UUID()
            self.refreshStatsID = UUID()
        }
    }
    
    func refreshStats() {
        DispatchQueue.main.async {
            self.refreshStatsID = UUID()
        }
    }
}
