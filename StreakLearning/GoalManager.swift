//
//  GoalManager.swift
//  StreakLearning
//

import Foundation

// MARK: - Model
struct LearningGoal: Codable, Equatable {
    var topic: String
    var duration: String // Week / Month / Year
    var startDate: Date
    var streakDays: Int
    var freezesUsed: Int
    var lastLoggedDate: Date?

    var totalDays: Int {
        switch duration {
        case "Week":  return 7
        case "Month": return 30
        case "Year":  return 365
        default:      return 7
        }
    }

    var isFinished: Bool {
        guard let endDate = Calendar.current.date(byAdding: .day, value: totalDays, to: startDate) else { return false }
        return Date() >= endDate
    }
}

// MARK: - Persistence
final class GoalManager {
    static let shared = GoalManager()
    private init() {}

    private let currentKey = "currentLearningGoal"
    private let finishedKey = "finishedLearningGoals"

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    // MARK: Current Goal
    func saveCurrentGoal(_ goal: LearningGoal) {
        if let encoded = try? encoder.encode(goal) {
            UserDefaults.standard.set(encoded, forKey: currentKey)
        }
    }

    func loadCurrentGoal() -> LearningGoal? {
        guard let data = UserDefaults.standard.data(forKey: currentKey),
              let goal = try? decoder.decode(LearningGoal.self, from: data) else {
            return nil
        }

        if goal.isFinished {
            completeCurrentGoal(goal)
            return nil
        }
        return goal
    }

    func clearCurrentGoal() {
        UserDefaults.standard.removeObject(forKey: currentKey)
    }

    // MARK: Finished Goals
    func completeCurrentGoal(_ goal: LearningGoal) {
        var finished = loadFinishedGoals()
        finished.append(goal)
        if let encoded = try? encoder.encode(finished) {
            UserDefaults.standard.set(encoded, forKey: finishedKey)
        }
        clearCurrentGoal()
    }

    func loadFinishedGoals() -> [LearningGoal] {
        guard let data = UserDefaults.standard.data(forKey: finishedKey),
              let decoded = try? decoder.decode([LearningGoal].self, from: data) else {
            return []
        }
        return decoded
    }

    func clearAllData() {
        UserDefaults.standard.removeObject(forKey: currentKey)
        UserDefaults.standard.removeObject(forKey: finishedKey)
    }

    // MARK: Per-goal namespaced keys
    struct ProgressKeys {
        let learned: String
        let freezed: String
        let streak: String
        let used: String
        let last: String

        static func forGoal(topic: String, duration: String) -> ProgressKeys {
            let normalized = Self.normalize("\(topic)_\(duration)")
            return ProgressKeys(
                learned: "learnedDates_\(normalized)",
                freezed: "freezedDates_\(normalized)",
                streak: "streakDays_\(normalized)",
                used: "freezesUsed_\(normalized)",
                last: "lastLoggedDate_\(normalized)"
            )
        }

        private static func normalize(_ s: String) -> String {
            s.trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()
                .replacingOccurrences(of: " ", with: "_")
        }
    }

    // MARK: Date set helpers
    func saveDates(_ dates: Set<Date>, forKey key: String) {
        let array = Array(dates)
        if let data = try? encoder.encode(array) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    func loadDates(forKey key: String) -> Set<Date> {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? decoder.decode([Date].self, from: data) else {
            return []
        }
        let cal = Calendar.current
        return Set(decoded.map { cal.startOfDay(for: $0) })
    }
}

