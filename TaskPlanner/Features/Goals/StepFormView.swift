//
//  StepFormView.swift
//  TaskPlanner
//
//  Created by Лия Форрат on 13.12.25.
//

import Foundation
import SwiftUI

struct StepFormView: View {
    let goal: Goal
    @ObservedObject var viewModel: GoalsViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var title = ""
    @State private var description: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Название шага", text: $title)
                } header: {
                    Text("Шаг цели: \(goal.title ?? "")")
                }
                Section("Описание шага") {
                       TextEditor(text: $description)
                           .frame(minHeight: 80)
                   }
                
            }
            .navigationTitle("Новый шаг")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Добавить") {
                        viewModel.createStep(for: goal, title: title, description: description.isEmpty ? nil : description)
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
}
