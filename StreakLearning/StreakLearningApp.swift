//
//  StreakLearningApp.swift
//  StreakLearning
//

import SwiftUI

@main
struct StreakLearningApp: App {
    var body: some Scene {
        WindowGroup {
            RootRouterView()
        }
    }
}

private struct RootRouterView: View {
    @State private var currentGoal: LearningGoal? = GoalManager.shared.loadCurrentGoal()

    var body: some View {
        Group {
            if let goal = currentGoal {
                MainView(learningTopic: goal.topic, selectedDuration: goal.duration)
            } else {
                ContentView()
            }
        }
        .onAppear {
            currentGoal = GoalManager.shared.loadCurrentGoal()
        }
    }
}

