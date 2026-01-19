//
//  TaskDetailView.swift
//  TaskPlanner
//
//  Created by Лия Форрат on 13.12.25.
//

import Foundation
import SwiftUI

struct TaskDetailView: View {
    let task: Task
    let viewModel: TasksViewModel

    @State private var offset: CGFloat = 0
    @State private var isVisible = false
    @State private var showingDeleteAlert = false

    private let cardHeight = UIScreen.main.bounds.height * 0.75

    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .opacity(isVisible ? 1 : 0)
                .onTapGesture { closeCard() }
                .animation(.easeInOut(duration: 0.3), value: isVisible)

            VStack {
                Spacer()
                VStack(spacing: 0) {
                    Capsule()
                        .fill(Color.gray.opacity(0.4))
                        .frame(width: 40, height: 5)
                        .padding(.vertical, 8)

                   
                    ScrollView {
                        VStack(spacing: 20) {

                            VStack(spacing: 12) {
                                HStack(spacing: 10) {
                                    if task.goalStep != nil {
                                        Image(systemName: "star.fill")
                                            .font(.caption)
                                            .foregroundColor(.yellow)
                                    }

                                    Text(task.title ?? "Без названия")
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .multilineTextAlignment(.center)
                                }
                            }
                            .padding(.horizontal, 24)

                        
                            if let description = task.taskDescription,
                               !description.isEmpty {

                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Описание")
                                        .font(.caption)
                                        .foregroundColor(.gray)

                                    ScrollView {
                                        Text(description)
                                            .font(.body)
                                            .foregroundColor(.primary)
                                            .multilineTextAlignment(.leading)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    .frame(maxHeight: 160) // ← КЛЮЧЕВО
                                }
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color(.secondarySystemBackground))
                                )
                                .padding(.horizontal, 16)
                            }

                        
                            VStack(spacing: 12) {
                                detailRow(
                                    icon: "calendar",
                                    title: "Дата",
                                    value: task.date?.formattedDate() ?? "Не указана"
                                )

                                if let time = task.time {
                                    detailRow(
                                        icon: "clock",
                                        title: "Время",
                                        value: time.formattedTime()
                                    )
                                }

                                detailRow(
                                    icon: "chart.bar.fill",
                                    title: "Сложность",
                                    value: getDifficultyText(task.difficulty),
                                    color: Color.forDifficulty(task.difficulty)
                                )

                                detailRow(
                                    icon: task.hasReminder ? "bell.fill" : "bell.slash",
                                    title: "Напоминание",
                                    value: task.hasReminder ? "Включено" : "Отключено",
                                    color: task.hasReminder ? .orange : .gray
                                )

                                if let step = task.goalStep,
                                   let goal = step.goal {
                                    detailRow(
                                        icon: "target",
                                        title: "Цель",
                                        value: goal.title ?? "Без названия",
                                        color: .purple
                                    )
                                }
                                if let data = task.imageData,
                                   let image = UIImage(data: data) {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFit()
                                        .cornerRadius(16)
                                        .padding(.horizontal, 16)
                                }

                            }
                            .padding(.horizontal, 16)

                
                            Spacer(minLength: 80)
                        }
                        .padding(.top, 8)
                    }

                    Divider()

                   
                    HStack(spacing: 12) {
                        editButton
                        deleteButton
                    }
                    .padding(16)
                    .background(Color(.systemBackground))
                }
                .frame(height: cardHeight)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.2), radius: 20)
                )
                .offset(y: offset + (isVisible ? 0 : 300))
                .gesture(
                    DragGesture()
                        .onChanged { gesture in
                            if gesture.translation.height > 0 {
                                offset = gesture.translation.height
                            }
                        }
                        .onEnded { gesture in
                            if gesture.translation.height > 120 {
                                closeCard()
                            } else {
                                withAnimation(.spring()) {
                                    offset = 0
                                }
                            }
                        }
                )
                .padding(.horizontal, 8)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                isVisible = true
            }
        }
 
               .alert("Удалить задачу?", isPresented: $showingDeleteAlert) {
                   Button("Отмена", role: .cancel) { }
                   Button("Удалить", role: .destructive) {
                       deleteTask()
                   }
               } message: {
                   Text("Задача будет удалена безвозвратно.")
               }
               .zIndex(999)
    }



    private var editButton: some View {
        Button {
            withAnimation(.spring()) {
                viewModel.startEditing(task)
            }
        } label: {
            HStack {
                Image(systemName: "pencil")
                Text("Редактировать")
            }
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.blue)
            .cornerRadius(12)
            .shadow(color: .blue.opacity(0.3), radius: 4, x: 0, y: 2)
        }
    }

    private var deleteButton: some View {
           Button(role: .destructive) {
              
               showingDeleteAlert = true
           } label: {
               HStack {
                   Image(systemName: "trash")
                   Text("Удалить")
               }
               .font(.subheadline)
               .fontWeight(.semibold)
               .foregroundColor(.white)
               .frame(maxWidth: .infinity)
               .padding(.vertical, 14)
               .background(Color.red)
               .cornerRadius(12)
               .shadow(color: .red.opacity(0.3), radius: 4, x: 0, y: 2)
           }
       }

    

    private func detailRow(
        icon: String,
        title: String,
        value: String,
        color: Color = .blue
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.gray)

                Text(value)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }

    private func getDifficultyText(_ difficulty: Int16) -> String {
        switch difficulty {
        case 1: return "Очень легко"
        case 2: return "Легко"
        case 3: return "Средне"
        case 4: return "Сложно"
        case 5: return "Очень сложно"
        default: return ""
        }
    }

    private func closeCard() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            isVisible = false
            offset = 300
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            viewModel.showingTaskDetail = false
        }
    }
    private func deleteTask() {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isVisible = false
                offset = 300
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                viewModel.deleteTask(task)
                viewModel.showingTaskDetail = false
            }
        }
}
