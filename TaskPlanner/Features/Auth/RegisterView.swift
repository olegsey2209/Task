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
                        focusedField = 2
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
        
        guard password.count >= 4 else {
            errorMessage = "Пароль должен содержать минимум 4 символа"
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
}
