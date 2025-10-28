import Foundation
import SwiftUI
import Combine

@MainActor
final class MainViewModel: ObservableObject {
    // MARK: - Goal Context
    let learningTopic: String
    let selectedDuration: String

    // MARK: - UI State
    enum LearnedState { case notLearned, learned, freezed }
    @Published var learnedState: LearnedState = .notLearned
    @Published var streakDays: Int = 0
    @Published var freezesUsed: Int = 0
    @Published var lastLoggedDate: Date? = nil
    @Published var learnedDates: Set<Date> = []
    @Published var freezedDates: Set<Date> = []
    @Published var isFreezeButtonPressed: Bool = false

    private var keys: GoalManager.ProgressKeys {
        GoalManager.ProgressKeys.forGoal(topic: learningTopic, duration: selectedDuration)
    }

    var maxFreezes: Int {
        switch selectedDuration {
        case "Week":  return 2
        case "Month": return 8
        case "Year":  return 96
        default:      return 2
        }
    }

    private var totalDays: Int {
        switch selectedDuration {
        case "Week":  return 7
        case "Month": return 30
        case "Year":  return 365
        default:      return 7
        }
    }

    var isGoalCompleted: Bool {
        (learnedDates.count + freezedDates.count) >= totalDays
    }

    var isFreezeDisabled: Bool { freezesUsed >= maxFreezes }
    var today: Date { Calendar.current.startOfDay(for: .now) }
    var isTodayLearned: Bool { learnedDates.contains(today) }
    var isTodayFreezed: Bool { freezedDates.contains(today) }

    init(learningTopic: String, selectedDuration: String) {
        self.learningTopic = learningTopic
        self.selectedDuration = selectedDuration
    }

    // MARK: Lifecycle
    func onAppear() {
        loadData()
        checkStreakExpiration()
    }

    func onTick() {
        checkStreakExpiration()
    }

    // MARK: Actions
    func handleCircleTap() {
        switch learnedState {
        case .notLearned: markAsLearned()
        case .learned:    unmarkLearned()
        case .freezed:    unfreezeDay()
        }
    }

    func markAsLearned() {
        let t = today
        if learnedDates.contains(t) {
            learnedState = .learned
            lastLoggedDate = Date()
            saveData()
            return
        }
        learnedState = .learned
        learnedDates.insert(t)

        if freezedDates.remove(t) != nil, freezesUsed > 0 {
            freezesUsed -= 1
        }

        lastLoggedDate = Date()
        saveData()
        recomputeStreak()
    }

    func unmarkLearned() {
        let t = today
        if learnedDates.remove(t) != nil {
            learnedState = .notLearned
            saveData()
            recomputeStreak()
        } else {
            learnedState = .notLearned
        }
    }

    func toggleFreeze() {
        let t = today
        if freezedDates.contains(t) {
            learnedState = .freezed
            return
        }
        guard !isFreezeDisabled else { return }

        if learnedDates.remove(t) != nil {
            recomputeStreak()
        }

        freezedDates.insert(t)
        freezesUsed += 1
        learnedState = .freezed
        lastLoggedDate = Date()
        saveData()
    }

    func unfreezeDay() {
        let t = today
        if freezedDates.remove(t) != nil, freezesUsed > 0 {
            freezesUsed -= 1
        }
        learnedState = .notLearned
        saveData()
        recomputeStreak()
    }

    func restartSameGoal() {
        let finished = LearningGoal(
            topic: learningTopic,
            duration: selectedDuration,
            startDate: Date().addingTimeInterval(-Double(totalDays) * 24 * 3600),
            streakDays: streakDays,
            freezesUsed: freezesUsed,
            lastLoggedDate: lastLoggedDate
        )
        GoalManager.shared.completeCurrentGoal(finished)

        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: keys.learned)
        defaults.removeObject(forKey: keys.freezed)
        defaults.removeObject(forKey: keys.streak)
        defaults.removeObject(forKey: keys.used)
        defaults.removeObject(forKey: keys.last)

        let newGoal = LearningGoal(
            topic: learningTopic,
            duration: selectedDuration,
            startDate: Date(),
            streakDays: 0,
            freezesUsed: 0,
            lastLoggedDate: nil
        )
        GoalManager.shared.saveCurrentGoal(newGoal)

        learnedDates = []
        freezedDates = []
        streakDays = 0
        freezesUsed = 0
        lastLoggedDate = nil
        learnedState = .notLearned
        saveData()
    }

    // MARK: Persistence
    private func saveData() {
        let defaults = UserDefaults.standard
        GoalManager.shared.saveDates(learnedDates, forKey: keys.learned)
        GoalManager.shared.saveDates(freezedDates, forKey: keys.freezed)
        defaults.set(streakDays, forKey: keys.streak)
        defaults.set(freezesUsed, forKey: keys.used)
        if let lastLoggedDate { defaults.set(lastLoggedDate, forKey: keys.last) }
    }

    private func loadData() {
        let defaults = UserDefaults.standard
        learnedDates = GoalManager.shared.loadDates(forKey: keys.learned)
        freezedDates = GoalManager.shared.loadDates(forKey: keys.freezed)
        streakDays = defaults.integer(forKey: keys.streak)
        freezesUsed = defaults.integer(forKey: keys.used)
        lastLoggedDate = defaults.object(forKey: keys.last) as? Date

        if learnedDates.contains(today) {
            learnedState = .learned
        } else if freezedDates.contains(today) {
            learnedState = .freezed
        } else {
            learnedState = .notLearned
        }

        recomputeStreak()
    }

    // MARK: Streak
    private func recomputeStreak() {
        let dates = learnedDates.map { Calendar.current.startOfDay(for: $0) }.sorted()
        guard !dates.isEmpty else { streakDays = 0; return }
        var count = 1
        for i in 1..<dates.count {
            let gap = Calendar.current.dateComponents([.day], from: dates[i - 1], to: dates[i]).day ?? 0
            count = (gap == 1) ? (count + 1) : 1
        }
        streakDays = count
    }

    private func checkStreakExpiration() {
        let cal = Calendar.current
        guard let last = lastLoggedDate else { return }

        // Allow grace period; then account for missed days
        let elapsed = Date().timeIntervalSince(last)
        guard elapsed > 32 * 3600 else { return }

        let lastDay = cal.startOfDay(for: last)
        let todayDay = today
        let daysMissed = cal.dateComponents([.day], from: lastDay, to: todayDay).day ?? 0
        guard daysMissed > 0 else { return }

        var remainingFreezes = max(0, maxFreezes - freezesUsed)
        var changed = false

        for offset in 1...daysMissed {
            guard let missedDay = cal.date(byAdding: .day, value: offset, to: lastDay) else { continue }
            let missedStart = cal.startOfDay(for: missedDay)
            if missedStart >= todayDay { break }

            if !learnedDates.contains(missedStart) && !freezedDates.contains(missedStart) {
                if remainingFreezes > 0 {
                    freezedDates.insert(missedStart)
                    remainingFreezes -= 1
                    freezesUsed += 1
                    changed = true
                } else {
                    streakDays = 0
                    changed = true
                    break
                }
            }
        }

        if changed {
            saveData()
        }
    }
}

