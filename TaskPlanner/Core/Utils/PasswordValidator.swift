//
//  PasswordValidator.swift
//  TaskPlanner
//
//  Created by Лия Форрат on 21.01.26.
//

import Foundation

struct PasswordValidator {

    static func isValidPassword(_ password: String) -> (isValid: Bool, message: String) {
        if password.count < 8 {
            return (false, "Пароль должен содержать минимум 8 символов")
        }
        
        let hasNumber = password.rangeOfCharacter(from: .decimalDigits) != nil
        if !hasNumber {
            return (false, "Добавьте хотя бы одну цифру (0-9)")
        }

        let hasLowercase = password.rangeOfCharacter(from: .lowercaseLetters) != nil
        if !hasLowercase {
            return (false, "Добавьте хотя бы одну строчную букву (a-z)")
        }

        let hasUppercase = password.rangeOfCharacter(from: .uppercaseLetters) != nil
        if !hasUppercase {
            return (false, "Добавьте хотя бы одну заглавную букву (A-Z)")
        }

        let specialCharacters = CharacterSet(charactersIn: "!@#$%^&*()_+-=[]{}|;:,.<>?")
        let hasSpecial = password.rangeOfCharacter(from: specialCharacters) != nil
        if !hasSpecial {
            return (false, "Добавьте хотя бы один спецсимвол (!@#$%^&* и т.д.)")
        }

        if password.contains(" ") {
            return (false, "Пароль не должен содержать пробелы")
        }
        
        return (true, "Пароль надёжный")
    }

    static func passwordsMatch(_ password1: String, _ password2: String) -> Bool {
        return !password1.isEmpty && !password2.isEmpty && password1 == password2
    }
}
