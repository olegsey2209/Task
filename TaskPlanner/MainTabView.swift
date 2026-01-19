//
//  MainTabView.swift
//  TaskPlanner
//
//  Created by Лия Форрат on 13.12.25.
//

import Foundation
import SwiftUI

struct MainTabView: View {
    @Binding var isLoggedIn: Bool
    
    var body: some View {
        TabView {
            StatisticsView()
                .tabItem {
                    Label("Статистика", systemImage: "chart.bar")
                }
            
            TasksView()
                .tabItem {
                    Label("Задачи", systemImage: "checklist")
                }
            
            GoalsView()
                .tabItem {
                    Label("Цели", systemImage: "target")
                }
            
            ProfileView(isLoggedIn: $isLoggedIn)
                .tabItem {
                    Label("Профиль", systemImage: "person")
                }
        }
        .tint(.blue)
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}
