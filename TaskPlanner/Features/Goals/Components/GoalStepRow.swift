//
//  GoalStepRow.swift
//  TaskPlanner
//
//  Created by Лия Форрат on 13.12.25.
//


import Foundation
import SwiftUI

struct GoalStepRow: View {
    let step: GoalStep
    let viewModel: GoalsViewModel
    let onCreateTask: () -> Void
    
    @State private var showingDeleteAlert = false
    @State private var showingEditSheet = false
    @State private var showingDeleteTaskAlert = false 
    
    @State private var editedTitle = ""
    @State private var editedDescription = ""
    
    var body: some View {
        HStack(spacing: 12) {

            Button(action: {
                withAnimation(.spring()) {
                    viewModel.toggleStepCompletion(step)
                }
            }) {
                Image(systemName: step.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(step.isCompleted ? .green : .gray)
            }
            
            Text(step.title ?? "")
                .font(.body)
                .strikethrough(step.isCompleted, color: .gray)
                .foregroundColor(step.isCompleted ? .gray : .primary)
            
            Spacer()
            
  
            Menu {
                if step.task == nil {
                    Button(action: onCreateTask) {
                        Label("Добавить на день", systemImage: "calendar.badge.plus")
                    }
                } else {

                    Button(action: {

                        showingDeleteTaskAlert = true
                    }) {
                        Label("Удалить задачу дня", systemImage: "calendar.badge.minus")
                    }
                }
                

                Button(action: { showingEditSheet = true }) {
                    Label("Редактировать шаг", systemImage: "pencil")
                }

                Button(role: .destructive, action: { showingDeleteAlert = true }) {
                    Label("Удалить шаг", systemImage: "trash")
                }
            } label: {
                Image(systemName: step.task == nil ? "ellipsis.circle" : "calendar.circle.fill")
                    .foregroundColor(step.task == nil ? .gray : .blue)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )

        .alert("Удалить шаг?", isPresented: $showingDeleteAlert) {
            Button("Отмена", role: .cancel) { }
            Button("Удалить", role: .destructive) {
                viewModel.deleteStep(step)
            }
        }message: {
            Text("Задача на день останется, но шаг цели удалится.")
        }

        .alert("Удалить задачу дня?", isPresented: $showingDeleteTaskAlert) {
            Button("Отмена", role: .cancel) { }
            Button("Удалить", role: .destructive) {
                deleteTaskFromStep()
            }
        } message: {
            Text("Задача будет удалена из дня, но шаг цели останется.")
        }

        .sheet(isPresented: $showingEditSheet) {
            NavigationStack {
                Form {
                    Section("Название") {
                        TextField("Название шага", text: $editedTitle)
                    }

                    Section("Описание") {
                        TextEditor(text: $editedDescription)
                            .frame(height: 120)
                            .scrollContentBackground(.hidden)
                    }
                }
                .navigationTitle("Редактировать шаг")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Готово") {
                            viewModel.updateStep(
                                step,
                                title: editedTitle,
                                description: editedDescription.isEmpty ? nil : editedDescription
                            )
                            showingEditSheet = false
                        }
                    }
                }
                .onAppear {
                    editedTitle = step.title ?? ""
                    editedDescription = step.stepDescription ?? ""
                }
            }
            .presentationDetents([.medium])
        }
    }
    

    private func deleteTaskFromStep() {
        viewModel.deleteTaskFromStep(step)
    }
}
