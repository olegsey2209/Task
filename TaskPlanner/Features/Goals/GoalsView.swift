//
//  GoalsView.swift
//  TaskPlanner
//
//  Created by Лия Форрат on 13.12.25.
//

import Foundation
import SwiftUI

struct GoalsView: View {
    @StateObject private var viewModel = GoalsViewModel()
    @State private var showingTaskForm = false
    @State private var selectedStepForTask: GoalStep?
    
    
    var body: some View {
        NavigationStack {
            ZStack (alignment: .bottomTrailing){
                VStack {
                    if viewModel.goals.isEmpty {
                        emptyStateView
                    } else {
                        goalsListView
                    }
                    
                   
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AppColors.background)
                addButtonView
                                   .padding(.trailing, 20)
                                   .padding(.bottom, 24)
            }
            .sheet(isPresented: $viewModel.showingGoalForm) {
                GoalFormView(viewModel: viewModel)
            }
            .sheet(isPresented: $viewModel.showingStepForm) {
                if let goal = viewModel.selectedGoalForStep {
                    StepFormView(goal: goal, viewModel: viewModel)
                }
            }
            .sheet(item: $selectedStepForTask) { step in
                StepToTaskFormView(step: step, viewModel: viewModel)
            }
            .navigationTitle("Цели")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "target")
                .font(.system(size: 70))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.gray.opacity(0.3), .gray.opacity(0.1)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            
            VStack(spacing: 8) {
                Text("Здесь пока пусто :(")
                    .font(.headline)
                    .foregroundColor(.gray)
                
                Text("Нажмите на + как только у вас появится цель")
                    .font(.caption)
                    .foregroundColor(.gray.opacity(0.7))
            }
        }
        .frame(maxHeight: .infinity)
    }
    
    private var goalsListView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.goals, id: \.id) { goal in
                    GoalCardView(
                        goal: goal,
                        viewModel: viewModel,
                        isExpanded: viewModel.expandedGoal == goal,
                        onToggleExpand: {
                            withAnimation(.spring()) {
                                if viewModel.expandedGoal == goal {
                                    viewModel.expandedGoal = nil
                                } else {
                                    viewModel.expandedGoal = goal
                                }
                            }
                        },
                        onCreateTaskFromStep: { step in
                            selectedStepForTask = step
                            showingTaskForm = true
                        }
                    )
                }
            }
            .padding()
        }
    }
    
    private var addButtonView: some View {
        Button(action: {
                    viewModel.editingGoal = nil
                    viewModel.showingGoalForm = true
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 56, height: 56)
                        .background(
                            LinearGradient(
                                colors: [AppColors.primary, AppColors.secondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(Circle())
                        .shadow(color: AppColors.primary.opacity(0.35), radius: 10, y: 5) 
                }
    }
}
