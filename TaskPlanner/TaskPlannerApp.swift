//
//  TaskPlannerApp.swift
//  TaskPlanner
//
//  Created by Лия Форрат on 13.12.25.
//

import SwiftUI

@main
struct TaskPlannerApp: App {

    let coreDataManager = CoreDataManager.shared
    var body: some Scene {
        WindowGroup {
                    ContentView()
                        .environment(\.managedObjectContext, coreDataManager.viewContext)
                }
    }
}
