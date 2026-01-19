//
//  ProfileView.swift
//  TaskPlanner
//
//  Created by Лия Форрат on 13.12.25.
//

import Foundation
import SwiftUI

struct ProfileView: View {
    @Binding var isLoggedIn: Bool
    @StateObject private var viewModel = ProfileViewModel()
    
    var body: some View {
        NavigationStack {
            List {
               
                Section {
                    HStack(spacing: 16) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(viewModel.username)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text(viewModel.joinedDate)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.vertical, 8)
                }

                Section("Настройки") {
                    Button(action: { viewModel.showingChangePassword = true }) {
                        Label("Изменить пароль", systemImage: "key.fill")
                            .foregroundColor(.primary)
                    }
                    
                    Button(action: { viewModel.showingDeleteAccount = true }) {
                        Label("Удалить аккаунт", systemImage: "trash")
                            .foregroundColor(.red)
                    }
                }

                Section {
                    Button(role: .destructive, action: {
                        viewModel.showingLogoutAlert = true
                    }) {
                        HStack {
                            Spacer()
                            Text("Выйти из аккаунта")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Профиль")
            .alert("Выйти из аккаунта?", isPresented: $viewModel.showingLogoutAlert) {
                Button("Отмена", role: .cancel) { }
                Button("Выйти", role: .destructive) {
                    viewModel.logout()
                    isLoggedIn = false
                }
            }
            .alert("Удалить аккаунт?", isPresented: $viewModel.showingDeleteAccount) {
                Button("Отмена", role: .cancel) { }
                Button("Удалить", role: .destructive) {
                    viewModel.deleteAccount()
                    isLoggedIn = false
                }
            } message: {
                Text("Все ваши данные будут удалены без возможности восстановления.")
            }
            .sheet(isPresented: $viewModel.showingChangePassword) {
                ChangePasswordView(viewModel: viewModel)
            }
            .onAppear {
                viewModel.loadUserData()
            }
        }
    }
}

class ProfileViewModel: ObservableObject {
    @Published var username = ""
    @Published var joinedDate = ""
    @Published var showingLogoutAlert = false
    @Published var showingDeleteAccount = false
    @Published var showingChangePassword = false
    
     let manager = CoreDataManager.shared
    
    func loadUserData() {
        if let user = manager.getCurrentUser() {
            username = user.username ?? "Пользователь"
            
            if let createdAt = user.createdAt {
                let formatter = DateFormatter()
                formatter.locale = Locale(identifier: "ru_RU")
                formatter.dateFormat = "d MMMM yyyy"
                joinedDate = "Дата регистрации: \(formatter.string(from: createdAt))"
            } else {
                joinedDate = "Новый пользователь"
            }
        }
    }
    
    func logout() {
        UserDefaults.standard.removeObject(forKey: "currentUserId")
    }
    
    func deleteAccount() {
        if let user = manager.getCurrentUser() {
      
            if let tasks = user.tasks as? Set<Task> {
                for task in tasks {
                    manager.viewContext.delete(task)
                }
            }
            
            if let goals = user.goals as? Set<Goal> {
                for goal in goals {
                    manager.viewContext.delete(goal)
                }
            }
            
            manager.viewContext.delete(user)
            manager.saveContext()
            logout()
        }
    }
}

struct ChangePasswordView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: ProfileViewModel
    
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var errorMessage = ""
    @State private var successMessage = ""
    @State private var isLoading = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Текущий пароль") {
                    SecureField("Введите текущий пароль", text: $currentPassword)
                }
                
                Section("Новый пароль") {
                    SecureField("Введите новый пароль", text: $newPassword)
                    SecureField("Повторите новый пароль", text: $confirmPassword)
                }
                
                if !errorMessage.isEmpty {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                if !successMessage.isEmpty {
                    Section {
                        Text(successMessage)
                            .foregroundColor(.green)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Изменение пароля")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        changePassword()
                    }
                    .disabled(isLoading || currentPassword.isEmpty || newPassword.isEmpty)
                }
            }
        }
    }
    
    private func changePassword() {
        guard let user = viewModel.manager.getCurrentUser() else {
            errorMessage = "Пользователь не найден"
            return
        }

        guard user.password == currentPassword else {
            errorMessage = "Неверный текущий пароль"
            return
        }

        guard newPassword == confirmPassword else {
            errorMessage = "Пароли не совпадают"
            return
        }

        guard newPassword.count >= 4 else {
            errorMessage = "Пароль слишком короткий"
            return
        }

        user.password = newPassword
        viewModel.manager.saveContext()

        successMessage = "Пароль изменён"
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            dismiss()
        }
    }
}
