//
//  TaskRowView.swift
//  TaskPlanner
//
//  Created by Лия Форрат on 13.12.25.
//

import Foundation
import SwiftUI

struct TaskRowView: View {
    let task: Task
    let viewModel: TasksViewModel

    @State private var scaleEffect: CGFloat = 1.0

    var body: some View {
        HStack(spacing: 16) {

        
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    scaleEffect = 0.85
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                    scaleEffect = 1.0
                    viewModel.toggleTaskCompletion(task)
                }
            } label: {
                ZStack {
                    Circle()
                        .stroke(
                            task.isCompleted ? Color.green : Color.gray.opacity(0.6),
                            lineWidth: 2
                        )
                        .frame(width: 26, height: 26)
                        .background(
                            Circle()
                                .fill(task.isCompleted ? Color.green.opacity(0.15) : Color.clear)
                        )

                    if task.isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.green)
                    }
                }
                .scaleEffect(scaleEffect)
                .padding(8) 
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)


            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(task.title ?? "")
                        .font(.headline)
                        .strikethrough(task.isCompleted)
                        .foregroundColor(task.isCompleted ? .gray : .primary)

                    if task.goalStep != nil {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundColor(.yellow)
                    }
                }

                if let time = task.time {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption2)
                        Text(time.formattedTime())
                            .font(.caption)
                    }
                    .foregroundColor(.gray)
                }
            }
            .onTapGesture {
                viewModel.showDetail(for: task)
            }

            Spacer()

            Circle()
                .fill(Color.forDifficulty(task.difficulty))
                .frame(width: 12, height: 12)

            if task.hasReminder {
                Image(systemName: "bell.fill")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    Color.forDifficulty(task.difficulty)
                        .opacity(task.isCompleted ? 0.10 : 0.18)
                )
        )
    }
}
