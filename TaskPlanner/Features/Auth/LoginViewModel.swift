//
//  LoginViewModel.swift
//  TaskPlanner
//
//  Created by Лия Форрат on 13.12.25.
//

import Foundation
import SwiftUI
import CoreData

class LoginViewModel: ObservableObject {
    @Published var username = ""
    @Published var password = ""
    @Published var errorMessage = ""
    @Published var isLoading = false
    
    func login(completion: @escaping (Bool) -> Void) {
        guard !username.isEmpty, !password.isEmpty else {
            errorMessage = "Заполните все поля"
            return
        }
        
        isLoading = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let manager = CoreDataManager.shared
            
            if let user = manager.getUser(username: self.username, password: self.password) {
                UserDefaults.standard.set(user.id?.uuidString, forKey: "currentUserId")
                self.errorMessage = ""
                completion(true)
            } else {
                self.errorMessage = "Неверное имя пользователя или пароль"
                completion(false)
            }
            
            self.isLoading = false
        }
        let manager = CoreDataManager.shared
        if let user = manager.getUser(username: self.username, password: self.password) {
               UserDefaults.standard.set(user.id?.uuidString, forKey: "currentUserId")
               

               if let appGroupDefaults = UserDefaults(suiteName: "group.com.taskplanner.shared") {
                   appGroupDefaults.set(user.id?.uuidString, forKey: "currentUserId")
                   appGroupDefaults.synchronize()
               }
               
               self.errorMessage = ""
               completion(true)
           }
    }
}
