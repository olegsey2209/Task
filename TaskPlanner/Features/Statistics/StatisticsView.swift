//
//  StatisticsView.swift
//  TaskPlanner
//
//  Created by Лия Форрат on 13.12.25.
//

import Foundation
import SwiftUI
import Charts

struct StatisticsView: View {
    @StateObject private var viewModel = StatisticsViewModel()
    @StateObject private var refreshManager = RefreshManager.shared
    
    var body: some View {
          NavigationStack {
              ScrollView {
                  VStack(spacing: 24) {
                      
                      periodSelector
                      
                      if viewModel.isLoading {
                          loadingView
                      } else {
                      
                          mainMetricsView
                          
                        
                          if !viewModel.statistics.difficultyDistribution.isEmpty {
                              difficultyChartView
                          }
                          
                         
                          goalsProgressView
                      }
                  }
                  .padding()
              }
              .background(AppColors.background)
              .navigationTitle("Статистика")
              .navigationBarTitleDisplayMode(.inline)
              .toolbarBackground(.visible, for: .navigationBar)
              .id(refreshManager.refreshID)
              .refreshable {
                  viewModel.refresh()
              }
              .onAppear {
                  viewModel.loadStatistics()
              }
          }
      }
    
    private var periodSelector: some View {
        Picker("Период", selection: $viewModel.selectedPeriod) {
            Text("День").tag(StatisticsPeriod.day)
            Text("Месяц").tag(StatisticsPeriod.month)
            Text("Год").tag(StatisticsPeriod.year)
        }
        .pickerStyle(.segmented)
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Загружаем статистику...")
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
    }
    
    private var mainMetricsView: some View {
        VStack(spacing: 16) {
            Text("Основные показатели")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 16) {
                MetricCard(
                    title: "Задачи",
                    value: "\(viewModel.statistics.totalTasks)",
                    icon: "checklist",
                    color: .blue
                )
                
                MetricCard(
                    title: "Цели",
                    value: "\(viewModel.statistics.completedGoals)/\(viewModel.statistics.totalGoals)",
                    icon: "target",
                    color: .green
                )
            }
            
            MetricCard(
                title: "Ср. сложность",
                value: String(format: "%.1f", viewModel.statistics.averageDifficulty),
                icon: "chart.bar.fill",
                color: .orange,
                subtitle: "из 5"
            )
        }
    }
    
    private var difficultyChartView: some View {
        VStack(spacing: 16) {
            Text("Распределение по сложности")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Chart {
                ForEach(Array(viewModel.statistics.difficultyDistribution.sorted(by: { $0.key < $1.key })), id: \.key) { difficulty, count in
                    BarMark(
                        x: .value("Сложность", "\(difficulty)"),
                        y: .value("Количество", count)
                    )
                    .foregroundStyle(Color.forDifficulty(difficulty).gradient)
                    .annotation(position: .top) {
                        Text("\(count)")
                            .font(.caption)
                            .fontWeight(.bold)
                    }
                }
            }
            .frame(height: 200)
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
            )
        }
    }
    
    private var goalsProgressView: some View {
        VStack(spacing: 16) {
            Text("Прогресс по целям")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if viewModel.statistics.goalProgress.isEmpty {
                emptyGoalsView
            } else {
                ForEach(viewModel.statistics.goalProgress, id: \.goal.id) { item in
                    GoalProgressRow(goal: item.goal, progress: item.progress)
                }
            }
        }
    }
    
    private var emptyGoalsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "target")
                .font(.system(size: 40))
                .foregroundColor(.gray.opacity(0.3))
            
            Text("Нет целей для отображения")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    var subtitle: String? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.gray)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundColor(.gray.opacity(0.7))
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
}

struct GoalProgressRow: View {
    let goal: Goal
    let progress: Double
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(goal.title ?? "")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text("\(Int(progress * 100))% выполнено")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 4)
                    .frame(width: 36, height: 36)
                
                Circle()
                    .trim(from: 0, to: CGFloat(progress))
                    .stroke(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 36, height: 36)
                    .rotationEffect(.degrees(-90))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }
}
