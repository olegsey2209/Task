//
//  GoalFormView.swift
//  TaskPlanner
//
//  Created by Лия Форрат on 13.12.25.
//

import Foundation
import SwiftUI

struct GoalFormView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: GoalsViewModel
    
    @State private var title = ""
    @State private var description = ""
    
    init(viewModel: GoalsViewModel) {
        self.viewModel = viewModel
        
        if let goal = viewModel.editingGoal {
            _title = State(initialValue: goal.title ?? "")
            _description = State(initialValue: goal.goalDescription ?? "")
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Название цели", text: $title)
                }
                
                Section {
                    TextEditor(text: $description)
                        .frame(minHeight: 100)
                } header: {
                    Text("Описание")
                }
            }
            .navigationTitle(viewModel.editingGoal != nil ? "Редактировать цель" : "Новая цель")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        saveGoal()
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
    
    private func saveGoal() {
        if let goal = viewModel.editingGoal {
            viewModel.updateGoal(goal, title: title, description: description.isEmpty ? nil : description)
        } else {
            viewModel.createGoal(title: title, description: description.isEmpty ? nil : description)
        }
    }
}
