//
//  NotificationService.swift
//  TaskPlanner
//
//  Created by Лия Форрат on 13.12.25.
//

import Foundation
import UserNotifications
import SwiftUI

class NotificationService: ObservableObject {
    static let shared = NotificationService()
    
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("чета плохо все")
            } else if let error = error {
                print("еще хуже: \(error)")
            }
        }
    }
    
    func scheduleNotification(for task: Task) {
        // Проверка: напоминание включено и указано время
        guard task.hasReminder, let time = task.time else { return }
        // Формирование содержимого уведомления
        let content = UNMutableNotificationContent()
        content.title = "Напоминание о задаче"
        content.body = task.title ?? "У вас есть задача"
        content.sound = .default
        // Формирование даты и времени срабатывания уведомления
        var dateComponents = Calendar.current.dateComponents([.hour, .minute], from: time)
        if let taskDate = task.date {
            let taskDateComponents = Calendar.current.dateComponents([.year, .month, .day], from: taskDate)
            dateComponents.year = taskDateComponents.year
            dateComponents.month = taskDateComponents.month
            dateComponents.day = taskDateComponents.day
        }
        // Создание триггера уведомления
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        // Формирование запроса с уникальным идентификатором задачи
        let request = UNNotificationRequest(
            identifier: task.id?.uuidString ?? UUID().uuidString,
            content: content,
            trigger: trigger
        )
        // Регистрация уведомления в системе
        UNUserNotificationCenter.current().add(request)
    }
    
    func removeNotification(for task: Task) {
        // Удаление уведомления по идентификатору задачи
        guard let taskId = task.id else { return }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [taskId.uuidString])
    }
    
    func updateNotification(for task: Task) {
        // Переcоздание уведомления при изменении параметров задачи
        removeNotification(for: task)
        scheduleNotification(for: task)
    }
}
