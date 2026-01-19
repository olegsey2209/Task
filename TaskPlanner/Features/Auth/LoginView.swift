//
//  LoginView.swift
//  TaskPlanner
//
//  Created by Лия Форрат on 13.12.25.
//

import Foundation
import SwiftUI

struct LoginView: View {
    @Binding var isLoggedIn: Bool
    @StateObject private var viewModel = LoginViewModel()
    @FocusState private var focusedField: Field?
    
    enum Field {
        case username, password
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 40) {
                Spacer()
                
         
                VStack(spacing: 20) {
                    Image(systemName: "checklist")
                        .font(.system(size: 80))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
        
                }
                .padding(.top, 50)
                
        
                VStack(spacing: 20) {
                    TextField("Имя пользователя", text: $viewModel.username)
                        .focused($focusedField, equals: .username)
                        .textFieldStyle(ModernTextFieldStyle())
                        .submitLabel(.next)
                        .onSubmit {
                            focusedField = .password
                        }
                    
                    SecureField("Пароль", text: $viewModel.password)
                        .focused($focusedField, equals: .password)
                        .textFieldStyle(ModernTextFieldStyle())
                        .submitLabel(.done)
                        .onSubmit {
                            login()
                        }
                }
                .padding(.horizontal, 40)
       
                if !viewModel.errorMessage.isEmpty {
                    Text(viewModel.errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
       
                Button(action: login) {
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Войти")
                            .fontWeight(.semibold)
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(viewModel.isLoading)
                
          
                NavigationLink("Создать аккаунт") {
                    RegisterView(isLoggedIn: $isLoggedIn)
                }
                .font(.headline)
                .foregroundColor(.blue)
                
                Spacer()
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
            .navigationBarHidden(true)
            .onAppear {
                if CoreDataManager.shared.getCurrentUser() != nil {
                    isLoggedIn = true
                }
                NotificationService.shared.requestAuthorization()
            }
        }
    }
    
    private func login() {
        viewModel.login { success in
            if success {
                isLoggedIn = true
            }
        }
    }
}

struct ModernTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
            )
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                LinearGradient(
                    colors: [.blue, .purple],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
            .padding(.horizontal, 40)
    }
}
