//
//  StatisticsViewModel.swift
//  TaskPlanner
//
//  Created by Лия Форрат on 13.12.25.
//

import Foundation
import SwiftUI
import CoreData
import Combine

class StatisticsViewModel: ObservableObject {
    @Published var selectedPeriod: StatisticsPeriod = .day
    @Published var statistics = StatisticsData()
    @Published var isLoading = false
    
    private let manager = CoreDataManager.shared
    private let refreshManager = RefreshManager.shared
    private var currentUser: User?
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadCurrentUser()
        loadStatistics()
        
        refreshManager.$refreshTasksID
            .sink { [weak self] _ in
                self?.loadStatistics()
            }
            .store(in: &cancellables)
        
        refreshManager.$refreshGoalsID
            .sink { [weak self] _ in
                self?.loadStatistics()
            }
            .store(in: &cancellables)
    
        $selectedPeriod
            .dropFirst()
            .sink { [weak self] _ in
                self?.loadStatistics()
            }
            .store(in: &cancellables)
    }
    
    private func loadCurrentUser() {
        currentUser = manager.getCurrentUser()
    }
    
    func loadStatistics() {
        guard let user = currentUser else { return }
        
        isLoading = true

        DispatchQueue.main.async {
            self.statistics = StatisticsData()

            self.statistics.totalTasks = self.manager.getCompletedTasksCount(for: self.selectedPeriod, user: user)

            let difficultyCounts = self.manager.getTaskCountByDifficulty(for: self.selectedPeriod, user: user)
            self.statistics.difficultyDistribution = difficultyCounts

            let goalProgress = self.manager.getGoalProgress(for: user)
            self.statistics.goalProgress = goalProgress
            self.statistics.completedGoals = goalProgress.filter { $0.progress == 1.0 }.count
            self.statistics.totalGoals = goalProgress.count
            
            let totalTasks = difficultyCounts.values.reduce(0, +)
            if totalTasks > 0 {
                let weightedSum = difficultyCounts.reduce(0) { $0 + Double($1.key) * Double($1.value) }
                self.statistics.averageDifficulty = weightedSum / Double(totalTasks)
            }
            
            self.isLoading = false
        }
    }
    
    func refresh() {
        loadStatistics()
    }
}

struct StatisticsData {
    var totalTasks = 0
    var completedGoals = 0
    var totalGoals = 0
    var averageDifficulty: Double = 0
    var difficultyDistribution: [Int16: Int] = [:]
    var goalProgress: [(goal: Goal, progress: Double)] = []
}
