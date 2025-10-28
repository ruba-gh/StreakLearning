import Foundation
import Combine

@MainActor
final class CalendarViewModel: ObservableObject {
    @Published var learnedDates: Set<Date> = []
    @Published var freezedDates: Set<Date> = []

    private let calendar = Calendar.current

    func load() {
        learnedDates.removeAll()
        freezedDates.removeAll()

        if let current = GoalManager.shared.loadCurrentGoal() {
            mergeGoalProgress(current)
        }

        for goal in GoalManager.shared.loadFinishedGoals() {
            mergeGoalProgress(goal)
        }

        learnedDates = Set(learnedDates.map { calendar.startOfDay(for: $0) })
        freezedDates = Set(freezedDates.map { calendar.startOfDay(for: $0) })
    }

    private func mergeGoalProgress(_ goal: LearningGoal) {
        let keys = GoalManager.ProgressKeys.forGoal(topic: goal.topic, duration: goal.duration)
        learnedDates.formUnion(GoalManager.shared.loadDates(forKey: keys.learned))
        freezedDates.formUnion(GoalManager.shared.loadDates(forKey: keys.freezed))
    }
}

