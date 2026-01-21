//
//  RegisterView.swift
//  TaskPlanner
//
//  Created by Лия Форрат on 13.12.25.
//

import Foundation
import SwiftUI

struct RegisterView: View {
    @Binding var isLoggedIn: Bool
    @Environment(\.dismiss) var dismiss
    
    @State private var username = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var errorMessage = ""
    @State private var isLoading = false
    @FocusState private var focusedField: Int?
    
    var body: some View {
        VStack(spacing: 30) {
          
            VStack(spacing: 10) {
                Text("Создание аккаунта")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
              
            }
            .padding(.top, 50)
            
      
            VStack(spacing: 20) {
                TextField("Имя пользователя", text: $username)
                    .focused($focusedField, equals: 0)
                    .textFieldStyle(ModernTextFieldStyle())
                    .submitLabel(.next)
                    .onSubmit {
                        focusedField = 1
                    }
                
                SecureField("Пароль", text: $password)
                    .focused($focusedField, equals: 1)
                    .textFieldStyle(ModernTextFieldStyle())
                    .submitLabel(.next)
                    .onSubmit {
                        DispatchQueue.main.async { 
                                   focusedField = 2
                               }
                    }
                
                SecureField("Повторите пароль", text: $confirmPassword)
                    .focused($focusedField, equals: 2)
                    .textFieldStyle(ModernTextFieldStyle())
                    .submitLabel(.done)
                    .onSubmit {
                        register()
                    }
            }
            .padding(.horizontal, 40)
            if !password.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Требования к паролю:")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.gray)
                        .padding(.bottom, 2)
                    
                    RequirementRow(met: password.count >= 8, text: "Минимум 8 символов")
                    RequirementRow(met: password.rangeOfCharacter(from: .decimalDigits) != nil, text: "Хотя бы одна цифра (0-9)")
                    RequirementRow(met: password.rangeOfCharacter(from: .lowercaseLetters) != nil, text: "Хотя бы одна строчная буква (a-z)")
                    RequirementRow(met: password.rangeOfCharacter(from: .uppercaseLetters) != nil, text: "Хотя бы одна заглавная буква (A-Z)")
                    
                    let specialChars = CharacterSet(charactersIn: "!@#$%^&*()_+-=[]{}|;:,.<>?")
                    RequirementRow(met: password.rangeOfCharacter(from: specialChars) != nil, text: "Хотя бы один спецсимвол (!@#$%^&*)")
                    RequirementRow(met: !password.contains(" "), text: "Без пробелов")
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.secondarySystemBackground).opacity(0.5))
                )
                .padding(.horizontal, 40)
                .padding(.top, 8)
            }
      
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
   
            Button(action: register) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Зарегистрироваться")
                        .fontWeight(.semibold)
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(isLoading)
            
            Spacer()
        }
        .background(
            LinearGradient(
                colors: [Color(.systemBackground), Color(.secondarySystemBackground)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.headline)
                    Text("Назад")
                }
                .foregroundColor(.blue)
            }
        }
    }
    
    private func register() {

        guard !username.isEmpty, !password.isEmpty, !confirmPassword.isEmpty else {
            errorMessage = "Заполните все поля"
            return
        }

        guard password == confirmPassword else {
            errorMessage = "Пароли не совпадают"
            return
        }

        let validation = PasswordValidator.isValidPassword(password)
        guard validation.isValid else {
            errorMessage = validation.message
            return
        }

        let manager = CoreDataManager.shared
        guard !manager.userExists(username: username) else {
            errorMessage = "Пользователь с таким именем уже существует"
            return
        }

        isLoading = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if let user = manager.createUser(username: username, password: password) {
                UserDefaults.standard.set(user.id?.uuidString, forKey: "currentUserId")
                isLoggedIn = true
            } else {
                errorMessage = "Ошибка при создании аккаунта"
            }
            
            isLoading = false
        }
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
