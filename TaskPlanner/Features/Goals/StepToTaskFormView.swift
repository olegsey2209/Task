//
//  StepToTaskFormView.swift
//  TaskPlanner
//
//  Created by Лия Форрат on 13.12.25.
//

import Foundation
import SwiftUI




struct StepToTaskFormView: View {
    let step: GoalStep
    @ObservedObject var viewModel: GoalsViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedDate = Date()
    @State private var selectedTime: Date?
    @State private var difficulty: Int16 = 1
    @State private var hasReminder = false
    @State private var showingTimePicker = false
    
    @State private var description: String
    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false
    private var imageData: Data? {
        selectedImage?.jpegData(compressionQuality: 0.8)
    }
    
    init(step: GoalStep, viewModel: GoalsViewModel) {
        self.step = step
        self.viewModel = viewModel
        _description = State(initialValue: step.stepDescription ?? "")
    }
    
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(step.title ?? "")
                        .font(.headline)
                        .padding(.vertical, 8)
                }
                
                Section("Описание задачи") {
                    TextEditor(text: $description)
                        .frame(height: 120)
                        .scrollContentBackground(.hidden)
                }
                
                Section("Дата") {
                    DatePicker("Выберите дату",
                             selection: $selectedDate,
                             in: Date()...,
                             displayedComponents: .date)
                }
                
                Section("Время") {
                    Toggle("Указать время", isOn: $showingTimePicker.animation())
                    
                    if showingTimePicker {
                        DatePicker("Время",
                                 selection: Binding(
                                    get: { selectedTime ?? Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: Date())! },
                                    set: { selectedTime = $0 }
                                 ),
                                 displayedComponents: .hourAndMinute)
                    }
                }
                
                Section("Сложность") {
                    HStack(spacing: 24) {
                        ForEach(1...5, id: \.self) { level in
                            VStack(spacing: 6) {
                                Button(action: {
                                    withAnimation(.spring()) {
                                        difficulty = Int16(level)
                                    }
                                }) {
                                    Circle()
                                        .fill(Color.forDifficulty(Int16(level)))
                                        .opacity(difficulty == level ? 1 : 0.3)
                                        .frame(width: 35, height: 35)
                                        .overlay(
                                            Circle()
                                                .stroke(difficulty == level ? Color.forDifficulty(Int16(level)) : Color.clear,
                                                       lineWidth: 3)
                                        )
                                        .scaleEffect(difficulty == level ? 1.1 : 1)
                                }
                                .buttonStyle(PlainButtonStyle())
                               
                                Text(getDifficultyText(for: level))
                                    .font(.system(size: 11))
                                    .foregroundColor(difficulty == level ? .primary : .gray)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .frame(height: 30)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 80)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section {
                    Toggle("Напоминание", isOn: $hasReminder)
                        .disabled(!showingTimePicker)
                }
                Section("Изображение") {
                    if let image = selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .cornerRadius(12)

                        Button("Удалить изображение", role: .destructive) {
                            selectedImage = nil
                        }
                    }

                    Button("Выбрать изображение") {
                        showImagePicker = true
                    }
                }
            }
            .navigationTitle("Создать задачу")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Создать") {
                        createTask()
                    }
                }
            }.sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $selectedImage)
            }
        }
    }
    
    private func getDifficultyText(for level: Int) -> String {
        switch level {
        case 1: return "Очень легко"
        case 2: return "Легко"
        case 3: return "Средне"
        case 4: return "Сложно"
        case 5: return "Очень сложно"
        default: return ""
        }
    }
    
    private func createTask() {
        _ = viewModel.createTaskFromStep(
            step,
            description: description.isEmpty ? nil : description,
            date: selectedDate,
            time: showingTimePicker ? selectedTime : nil,
            difficulty: difficulty,
            hasReminder: hasReminder && showingTimePicker,
            imageData: imageData
        )
        dismiss()
    }
}
