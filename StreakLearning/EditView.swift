//
//  EditView.swift
//  LearnByStreak
//

import SwiftUI

struct EditView: View {
    @State private var learningTopic = ""
    @State private var selectedDuration = "Week"
    @State private var showConfirmation = false
    @State private var navigateToMain = false
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    // Keep a baseline to detect changes without juggling separate fields
    @State private var baseline: LearningGoal? = nil

    private var hasChanges: Bool {
        let trimmed = learningTopic.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let base = baseline else {
            return !trimmed.isEmpty || selectedDuration != "Week"
        }
        return trimmed != base.topic || selectedDuration != base.duration
    }

    var body: some View {
        ZStack {
            VStack(spacing: 30) {
                // Programmatic navigation trigger
                NavigationLink(
                    destination: MainView(
                        learningTopic: learningTopic.isEmpty ? "Swift" : learningTopic,
                        selectedDuration: selectedDuration
                    ),
                    isActive: $navigateToMain
                ) { EmptyView() }

                // Topic
                VStack(alignment: .leading, spacing: 10) {
                    Text("I want to learn")
                        .font(.system(size: 24, weight: .semibold))

                    TextField("Swift", text: $learningTopic)
                        .padding(.vertical, 6)
                        .overlay(
                            Rectangle()
                                .frame(height: 1)
                                .glassEffect(.clear)
                                .padding(.top, 30),
                            alignment: .bottom
                        )
                }
                .padding(.horizontal, 20)

                // Duration
                VStack(alignment: .leading, spacing: 10) {
                    Text("I want to learn it in a")
                        .font(.system(size: 24, weight: .semibold))

                    HStack(spacing: 12) {
                        ForEach(["Week", "Month", "Year"], id: \.self) { duration in
                            Button(duration) {
                                selectedDuration = duration
                            }
                            .buttonStyle(SelectableCapsuleChipStyle(isSelected: selectedDuration == duration))
                        }
                        Spacer()
                    }
                }
                .padding(.horizontal, 20)

                Spacer()
            }

            // Confirmation
            if showConfirmation {
                let dimOpacity: Double = (colorScheme == .dark) ? 0.6 : 0.35
                Color.black.opacity(dimOpacity)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .zIndex(1)

                UpdateGoalPopup(
                    onDismiss: { withAnimation(.easeInOut) { showConfirmation = false } },
                    onUpdate: {
                        // Archive finished goal if needed
                        if let current = GoalManager.shared.loadCurrentGoal(), current.isFinished {
                            GoalManager.shared.completeCurrentGoal(current)
                        }

                        // Save new goal
                        let newGoal = LearningGoal(
                            topic: learningTopic.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Swift" : learningTopic,
                            duration: selectedDuration,
                            startDate: Date(),
                            streakDays: 0,
                            freezesUsed: 0,
                            lastLoggedDate: nil
                        )
                        GoalManager.shared.saveCurrentGoal(newGoal)

                        withAnimation(.easeInOut) {
                            showConfirmation = false
                            navigateToMain = true
                        }
                    }
                )
                .zIndex(2)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                ZStack {
                    Circle()
                        .fill(ThemeColors.brandOrange.opacity(0.8))
                        .frame(width: 40, height: 40)
                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                        .onTapGesture {
                            guard hasChanges else { return }
                            withAnimation(.easeInOut) { showConfirmation = true }
                        }
                        .opacity(hasChanges ? 1.0 : 0.5)

                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
            }
        }
        .navigationTitle("Learning Goal")
        .toolbarBackground(.automatic, for: .navigationBar)
        .onAppear {
            if let goal = GoalManager.shared.loadCurrentGoal() {
                learningTopic = goal.topic
                selectedDuration = goal.duration
                baseline = goal
            } else {
                baseline = LearningGoal(topic: "", duration: "Week", startDate: Date(), streakDays: 0, freezesUsed: 0, lastLoggedDate: nil)
            }
        }
    }
}

struct UpdateGoalPopup: View {
    var onDismiss: () -> Void
    var onUpdate: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Update Learning goal")
                .foregroundColor(.primary)
                .font(.system(size: 18, weight: .semibold))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 12)
                .padding(.leading,12)

            Text("If you update now, your streak will start over.")
                .foregroundColor(.secondary)
                .font(.system(size: 14))
                .multilineTextAlignment(.leading)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 12)
            
            HStack(spacing: 12) {
                Button(action: onDismiss) {
                    Text("Dismiss")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color(.tertiarySystemFill))
                        .foregroundColor(.primary)
                        .clipShape(Capsule())
                }

                Button(action: onUpdate) {
                    Text("Update")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.orange)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                        .clipShape(Capsule())
                }
            }
            .padding(.bottom, 8)
        }
        .padding()
        .frame(width: 302, height: 170)
        .background(
            RoundedRectangle(cornerRadius: 25, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.5 : 0.15), radius: 20, x: 0, y: 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 25, style: .continuous)
                .stroke(Color(.separator).opacity(colorScheme == .dark ? 0.9 : 0.2), lineWidth: 1)
        )
        .glassEffect(.clear)
        .clipShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
    }
}

#Preview { NavigationStack { EditView() } }

