//
//  TasksView.swift
//  TaskPlanner
//
//  Created by Лия Форрат on 13.12.25.
//

import Foundation
import SwiftUI

struct TasksView: View {
    @StateObject private var viewModel = TasksViewModel()
    @State private var showingDatePicker = false
    @State private var dragTask: Task?
    @StateObject private var refreshManager = RefreshManager.shared
    
    var body: some View {
           NavigationStack {
               ZStack (alignment: .bottomTrailing){
                   VStack(spacing: 0) {
                       headerView
                       tasksListView
                      
                   }
                   .background(AppColors.background)
                   addButtonView
                                      .padding(.trailing, 20)
                                      .padding(.bottom, 24)
                                    

                
                   if viewModel.showingTaskDetail, let task = viewModel.selectedTask {
                       TaskDetailView(task: task, viewModel: viewModel)
                           .zIndex(999)
                   }
               }
               .sheet(isPresented: $viewModel.showingTaskForm) {
                   TaskFormView(viewModel: viewModel)
               }
               .sheet(isPresented: $viewModel.showingCalendar) {
                   CalendarView(selectedDate: $viewModel.selectedDate, onDateSelected: viewModel.selectDate)
               }
               .navigationTitle("Задачи")
               .navigationBarTitleDisplayMode(.inline)
               .toolbarBackground(.visible, for: .navigationBar)
               .id(refreshManager.refreshTasksID) 
           }
       }
    
    private var headerView: some View {
        HStack {
            Button(action: {
                withAnimation {
                    let newDate = Calendar.current.date(byAdding: .day, value: -1, to: viewModel.selectedDate)!
                    viewModel.selectedDate = newDate
                    viewModel.loadTasks()
                }
            }) {
                Image(systemName: "chevron.left")
                    .font(.headline)
                    .foregroundColor(.blue)
            }
            
            Button(action: { viewModel.showingCalendar = true }) {
                Text(viewModel.selectedDate.formattedDate())
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            .buttonStyle(PlainButtonStyle())
            
            Button(action: {
                withAnimation {
                    let newDate = Calendar.current.date(byAdding: .day, value: 1, to: viewModel.selectedDate)!
                    viewModel.selectedDate = newDate
                    viewModel.loadTasks()
                }
            }) {
                Image(systemName: "chevron.right")
                    .font(.headline)
                    .foregroundColor(.blue)
            }
            
            Spacer()
            
            Button(action: {
                withAnimation {
                    viewModel.selectedDate = Date()
                    viewModel.loadTasks()
                }
            }) {
                Text("Сегодня")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(Color(.systemBackground))
    }
    
    private var tasksListView: some View {
        Group {
            if viewModel.tasks.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.tasks, id: \.id) { task in
                            TaskRowView(task: task, viewModel: viewModel)
                                .onTapGesture {
                                    viewModel.showDetail(for: task)
                                }
                                .onLongPressGesture {
                                    dragTask = task
                                }
                        }
                    }
                    .padding()
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checklist")
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
                
                Text("Но вы можете добавить задачу, нажав на +")
                    .font(.caption)
                    .foregroundColor(.gray.opacity(0.7))
            }
        }
        .frame(maxHeight: .infinity)
    }
    
    private var addButtonView: some View {
        Button {
               viewModel.editingTask = nil
               viewModel.showingTaskForm = true
           } label: {
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
