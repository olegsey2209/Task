//
//  TaskFormView.swift
//  TaskPlanner
//
//  Created by Лия Форрат on 13.12.25.
//

import Foundation
import SwiftUI


struct TaskFormView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: TasksViewModel
    
    @State private var title = ""
    @State private var selectedDate = Date()
    @State private var selectedTime: Date?
    @State private var difficulty: Int16 = 1
    @State private var hasReminder = false
    @State private var showingTimePicker = false
    
    @State private var description = ""
    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false
    
    init(viewModel: TasksViewModel) {
        self.viewModel = viewModel
        
        if let task = viewModel.editingTask {
            _title = State(initialValue: task.title ?? "")
            _description = State(initialValue: task.taskDescription ?? "")
            _selectedDate = State(initialValue: task.date ?? Date())
            _selectedTime = State(initialValue: task.time)
            _difficulty = State(initialValue: task.difficulty)
            _hasReminder = State(initialValue: task.hasReminder)
            _showingTimePicker = State(initialValue: task.time != nil)
            if let data = task.imageData,
                      let image = UIImage(data: data) {
                       _selectedImage = State(initialValue: image)
                   }
        } else {
            _selectedDate = State(initialValue: viewModel.selectedDate)
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Название задачи", text: $title)
                }
                Section("Описание") {
                    TextEditor(text: $description)
                        .frame(height: 120)
                        .scrollContentBackground(.hidden)
                }
                Section("Дата") {
                    DatePicker("Дата выполнения",
                             selection: $selectedDate,
                             in: Date()...,
                             displayedComponents: .date)
                }
                
                Section("Время") {
                    Toggle("Добавить время", isOn: $showingTimePicker.animation())
                    
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
            .navigationTitle(viewModel.editingTask != nil ? "Редактировать" : "Новая задача")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        saveTask()
                      
                    }
                    .disabled(title.isEmpty)
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
    
    private func saveTask() {
        let imageData = selectedImage?.jpegData(compressionQuality: 0.8)

        if let task = viewModel.editingTask {
            viewModel.updateTask(
                task,
                title: title,
                description: description.isEmpty ? nil : description,
                imageData: imageData,
                date: selectedDate,
                time: showingTimePicker ? selectedTime : nil,
                difficulty: difficulty,
                hasReminder: hasReminder && showingTimePicker
            )
        } else {
            viewModel.createTask(
                title: title,
                description: description.isEmpty ? nil : description,
                imageData: imageData,
                date: selectedDate,
                time: showingTimePicker ? selectedTime : nil,
                difficulty: difficulty,
                hasReminder: hasReminder && showingTimePicker
            )
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.viewModel.loadTasks()
        }
        
        dismiss()
    }
}
