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
            
            if step.task == nil {
                Menu {
                    Button(action: onCreateTask) {
                        Label("Добавить на день", systemImage: "calendar.badge.plus")
                    }
                    
                    Button(action: { showingEditSheet = true }) {
                        Label("Редактировать", systemImage: "pencil")
                    }
                    
                    Button(role: .destructive, action: { showingDeleteAlert = true }) {
                        Label("Удалить", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(.gray)
                }
            } else {
                Image(systemName: "calendar.circle.fill")
                    .foregroundColor(.blue)
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
}
