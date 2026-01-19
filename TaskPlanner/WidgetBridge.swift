//
//  WidgetBridge.swift
//  TaskPlanner
//
//  Created by Лия Форрат on 12.01.26.
//

import Foundation
import WidgetKit

let appGroupID = "group.com.taskplanner.shared"

struct TodayTask {
    let title: String
}

func saveTodayTasks(_ tasks: [TodayTask]) {
    let defaults = UserDefaults(suiteName: appGroupID)

    let titles = tasks.map { $0.title }
    defaults?.set(titles, forKey: "today_tasks")

    WidgetCenter.shared.reloadTimelines(ofKind: "DailyTasksWidget")
}
