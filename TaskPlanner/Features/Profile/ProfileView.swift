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

                    if !newPassword.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Требования к паролю:")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.gray)
                                .padding(.bottom, 2)
                            
                            RequirementRow(met: newPassword.count >= 8, text: "Минимум 8 символов")
                            RequirementRow(met: newPassword.rangeOfCharacter(from: .decimalDigits) != nil, text: "Хотя бы одна цифра (0-9)")
                            RequirementRow(met: newPassword.rangeOfCharacter(from: .lowercaseLetters) != nil, text: "Хотя бы одна строчная буква (a-z)")
                            RequirementRow(met: newPassword.rangeOfCharacter(from: .uppercaseLetters) != nil, text: "Хотя бы одна заглавная буква (A-Z)")
                            
                            let specialChars = CharacterSet(charactersIn: "!@#$%^&*()_+-=[]{}|;:,.<>?")
                            RequirementRow(met: newPassword.rangeOfCharacter(from: specialChars) != nil, text: "Хотя бы один спецсимвол (!@#$%^&*)")
                            RequirementRow(met: !newPassword.contains(" "), text: "Без пробелов")
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.secondarySystemBackground).opacity(0.5))
                        )
                    }
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

        errorMessage = ""
        successMessage = ""

        guard let user = viewModel.manager.getCurrentUser() else {
            errorMessage = "Пользователь не найден"
            return
        }

        print("Текущий пароль пользователя: \(user.password ?? "nil")")
        print("Введённый текущий пароль: \(currentPassword)")

        guard user.password == currentPassword else {
            errorMessage = "Неверный текущий пароль"
            return
        }

        guard newPassword == confirmPassword else {
            errorMessage = "Пароли не совпадают"
            return
        }

        let validation = PasswordValidator.isValidPassword(newPassword)
        guard validation.isValid else {
            errorMessage = validation.message
            return
        }

        isLoading = true

        user.password = newPassword

        do {
            try viewModel.manager.viewContext.save()
            print("Пароль изменён на: \(newPassword)")
            
            successMessage = "Пароль успешно изменён"

            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                dismiss()
            }
        } catch {
            print("Ошибка сохранения пароля: \(error)")
            errorMessage = "Ошибка при сохранении пароля"
        }
        
        isLoading = false
    }
    struct RequirementRow: View {
        let met: Bool
        let text: String
        
        var body: some View {
            HStack(spacing: 8) {
                Image(systemName: met ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(met ? .green : .red)
                    .font(.caption2)
                
                Text(text)
                    .font(.caption)
                    .foregroundColor(met ? .primary : .red)
                    .fontWeight(met ? .regular : .medium)
                
                Spacer()
            }
            .padding(.vertical, 2)
        }
    }
}
