import Foundation
import Combine

@MainActor
final class ContentViewModel: ObservableObject {
    @Published var learningTopic: String = "Swift"
    @Published var selectedDuration: String = "Week"
    @Published var navigateToMain: Bool = false

    func startLearning() {
        let newGoal = LearningGoal(
            topic: learningTopic.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Swift" : learningTopic,
            duration: selectedDuration,
            startDate: Date(),
            streakDays: 0,
            freezesUsed: 0,
            lastLoggedDate: nil
        )
        GoalManager.shared.saveCurrentGoal(newGoal)
        navigateToMain = true
    }

    func preloadFromCurrentGoalIfAvailable() {
        if let goal = GoalManager.shared.loadCurrentGoal() {
            learningTopic = goal.topic
            selectedDuration = goal.duration
        }
    }
}

