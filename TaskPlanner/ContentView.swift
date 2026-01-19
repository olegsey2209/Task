//
//  ContentView.swift
//  TaskPlanner
//
//  Created by Лия Форрат on 13.12.25.
//

import SwiftUI
import CoreData

struct ContentView: View {

    @State private var isLoggedIn = false
   
    var body: some View {
        Group {
                   if isLoggedIn {
                       MainTabView(isLoggedIn: $isLoggedIn)
                   } else {
                       LoginView(isLoggedIn: $isLoggedIn)
                   }
               }
               .animation(.easeInOut, value: isLoggedIn)
           }
    }

