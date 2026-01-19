//
//  GoalCardView.swift
//  TaskPlanner
//
//  Created by Лия Форрат on 13.12.25.
//

import Foundation
import SwiftUI

struct GoalCardView: View {
    let goal: Goal
    let viewModel: GoalsViewModel
    let isExpanded: Bool
    let onToggleExpand: () -> Void
    let onCreateTaskFromStep: (GoalStep) -> Void
    
    @State private var showingDeleteAlert = false
    @State private var showingEditSheet = false
    
    var progress: Double {
        viewModel.getProgress(for: goal)
    }
    
    var steps: [GoalStep] {
        (goal.steps?.array as? [GoalStep]) ?? []
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
          
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(goal.title ?? "")
                        .font(.headline)
                    
                    if let description = goal.goalDescription, !description.isEmpty {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.gray)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
            
                CircularProgressView(progress: progress)
                    .frame(width: 50, height: 50)
            }
            
        
            ProgressView(value: progress)
                .tint(.blue)
                .scaleEffect(x: 1, y: 1.5, anchor: .center)
            
            if isExpanded {
              
                VStack(alignment: .leading, spacing: 12) {
                    Text("Шаги (\(steps.filter { $0.isCompleted }.count)/\(steps.count))")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    ForEach(steps, id: \.id) { step in
                        GoalStepRow(
                            step: step,
                            viewModel: viewModel,
                            onCreateTask: { onCreateTaskFromStep(step) }
                        )
                    }
                    
                    Button(action: {
                        viewModel.selectedGoalForStep = goal
                        viewModel.showingStepForm = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Добавить шаг")
                        }
                        .font(.subheadline)
                        .foregroundColor(.blue)
                    }
                    .padding(.top, 4)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
            
    
            HStack {
                Button(action: onToggleExpand) {
                    HStack {
                        Text(isExpanded ? "Свернуть" : "Развернуть")
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
                
                Spacer()
                
                Button("Редактировать") {
                    viewModel.editingGoal = goal
                    viewModel.showingGoalForm = true
                }
                .font(.caption)
                .foregroundColor(.blue)
                
                Button("Удалить", role: .destructive) {
                    showingDeleteAlert = true
                }
                .font(.caption)
                .foregroundColor(.red)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
        )
        .alert("Удалить цель?", isPresented: $showingDeleteAlert) {
            Button("Отмена", role: .cancel) { }
            Button("Удалить", role: .destructive) {
                viewModel.deleteGoal(goal)
            }
        } message: {
            Text("Все шаги этой цели также будут удалены, но задачи останутся.")
        }
    }
}

struct CircularProgressView: View {
    let progress: Double
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 6)
            
            Circle()
                .trim(from: 0, to: CGFloat(progress))
                .stroke(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(), value: progress)
            
            Text("\(Int(progress * 100))%")
                .font(.system(.caption, design: .rounded))
                .fontWeight(.bold)
        }
    }
}
