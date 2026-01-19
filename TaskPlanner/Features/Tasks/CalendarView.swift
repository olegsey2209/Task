//
//  CalendarView.swift
//  TaskPlanner
//
//  Created by Лия Форрат on 13.12.25.
//

import Foundation
import SwiftUI
import CoreData

struct CalendarView: View {
    @Binding var selectedDate: Date
    let onDateSelected: (Date) -> Void
    @Environment(\.dismiss) var dismiss
    
    @State private var currentMonth = Date()
    @State private var datesWithTasks: Set<Date> = []
    
    private let manager = CoreDataManager.shared
    
    var body: some View {
        NavigationStack {
            VStack {
         
                monthHeaderView

                daysOfWeekView

                daysGridView
                
                Spacer()
            }
            .padding()
            .navigationTitle("Календарь")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadDatesWithTasks()
            }
            .onChange(of: currentMonth) { _ in
                loadDatesWithTasks()
            }
        }
    }
    
    private var monthHeaderView: some View {
        HStack {
            Button(action: previousMonth) {
                Image(systemName: "chevron.left")
                    .font(.headline)
            }
            
            Spacer()
            
            Text(monthYearString)
                .font(.title2)
                .fontWeight(.bold)
            
            Spacer()
            
            Button(action: nextMonth) {
                Image(systemName: "chevron.right")
                    .font(.headline)
            }
        }
        .padding(.vertical)
    }
    
    private var daysOfWeekView: some View {
        HStack {
            ForEach(["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"], id: \.self) { day in
                Text(day)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity)
            }
        }
    }
    
    private var daysGridView: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
            ForEach(daysInMonth(), id: \.self) { date in
                if let date = date {
                    DayCell(
                        date: date,
                        isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate),
                        hasTasks: datesWithTasks.contains { Calendar.current.isDate($0, inSameDayAs: date) },
                        isToday: Calendar.current.isDateInToday(date),
                        onSelect: { onDateSelected(date) }
                    )
                } else {
                    Color.clear
                }
            }
        }
    }
    
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentMonth).capitalized
    }
    
    private func daysInMonth() -> [Date?] {
        let calendar = Calendar.current
        let month = calendar.dateComponents([.year, .month], from: currentMonth)
        let startOfMonth = calendar.date(from: month)!
        
        let range = calendar.range(of: .day, in: .month, for: startOfMonth)!
        let firstWeekday = calendar.component(.weekday, from: startOfMonth)
        
        var days: [Date?] = []
        

        for _ in 1..<firstWeekday {
            days.append(nil)
        }
        

        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                days.append(date)
            }
        }
        
        return days
    }
    
    private func previousMonth() {
        currentMonth = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth)!
    }
    
    private func nextMonth() {
        currentMonth = Calendar.current.date(byAdding: .month, value: 1, to: currentMonth)!
    }
    
    private func loadDatesWithTasks() {
        guard let user = manager.getCurrentUser() else { return }
        
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth))!
        let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)!
  
        let tasks = manager.getTasksForMonth(startDate: startOfMonth, endDate: endOfMonth, user: user)
        let dates = tasks.compactMap { $0.date }
            .map { calendar.startOfDay(for: $0) }
        
        datesWithTasks = Set(dates)
    }
    struct DayCell: View {
        let date: Date
        let isSelected: Bool
        let hasTasks: Bool
        let isToday: Bool
        let onSelect: () -> Void
        
        var body: some View {
            Button(action: onSelect) {
                VStack(spacing: 4) {
                    ZStack {
                        Circle()
                            .fill(isSelected ? Color.blue : (isToday ? Color.blue.opacity(0.1) : Color.clear))
                            .frame(width: 40, height: 40)
                        
                        Text("\(Calendar.current.component(.day, from: date))")
                            .font(.system(.body, design: .rounded))
                            .fontWeight(isSelected ? .bold : .regular)
                            .foregroundColor(isSelected ? .white : (isToday ? .blue : .primary))
                    }
                    
                    if hasTasks {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 6, height: 6)
                    }
                }
            }
            .frame(height: 60)
        }
    }
}


