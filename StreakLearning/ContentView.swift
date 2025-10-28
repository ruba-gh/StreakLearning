//
//  ContentView.swift
//  LearnByStreak
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ContentViewModel()
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 28) {
                    // App icon
                    ZStack {
                        Circle()
                            .fill(Color.orange.opacity(0.08))
                            .frame(width: 110, height: 110)
                            .glassEffect(.clear)
                            .overlay(
                                Circle()
                                    .stroke(LinearGradient(
                                        colors: [Color.orange, Color.clear, Color.orange.opacity(0.5)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ))
                            )
                            .overlay(
                                Circle()
                                    .stroke(Color.orange, lineWidth: 8)
                                    .blur(radius: 15)
                                    .offset(x: 1, y: 1)
                                    .mask(
                                        Circle().fill(
                                            LinearGradient(
                                                colors: [Color.orange, Color.clear],
                                                startPoint: .bottomTrailing,
                                                endPoint: .topLeading
                                            )
                                        )
                                    )
                                    .opacity(0.1)
                            )

                        Image(systemName: "flame.fill")
                            .foregroundStyle(.orange)
                            .font(.system(size: 36, weight: .bold))
                    }
                    .padding(.top, 24)

                    // Greeting
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Hello Learner")
                            .font(.system(size: 36, weight: .bold))

                        Text("This app will help you learn everyday!")
                            .foregroundColor(.gray)
                            .font(.system(size: 18))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)

                    // Topic
                    VStack(alignment: .leading, spacing: 10) {
                        Text("I want to learn")
                            .font(.system(size: 24))

                        TextField("Swift", text: $viewModel.learningTopic)
                            .foregroundColor(Color.gray.opacity(0.85))
                            .padding(.vertical, 6)
                            .overlay(
                                Rectangle()
                                    .fill(Color.gray.opacity(0.20))
                                    .frame(height: 1)
                                    .padding(.top, 30),
                                alignment: .bottom
                            )
                    }
                    .padding(.horizontal, 20)

                    // Duration chips
                    VStack(alignment: .leading, spacing: 12) {
                        Text("I want to learn it in a")
                            .font(.system(size: 24))

                        HStack(spacing: 12) {
                            ForEach(["Week", "Month", "Year"], id: \.self) { duration in
                                Button(duration) { viewModel.selectedDuration = duration }
                                    .buttonStyle(SelectableCapsuleChipStyle(isSelected: viewModel.selectedDuration == duration))
                            }
                            Spacer()
                        }
                    }
                    .padding(.horizontal, 20)

                    Spacer()

                    // Start button
                    NavigationLink(
                        destination: MainView(learningTopic: viewModel.learningTopic, selectedDuration: viewModel.selectedDuration),
                        isActive: $viewModel.navigateToMain
                    ) {
                        Button {
                            viewModel.startLearning()
                        } label: {
                            Text("Start learning")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                                .frame(maxWidth: 165)
                                .padding(.vertical, 16)
                                .padding(.horizontal, 16)
                                .background(
                                    ZStack {
                                        Capsule().fill(ThemeColors.brandOrange.opacity(0.8))
                                        Capsule().stroke(ThemeGradients.orangeCapsuleStroke, lineWidth: 1)
                                    }
                                )
                                .glassEffect()
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .onAppear {
            if let goal = GoalManager.shared.loadCurrentGoal() {
                viewModel.learningTopic = goal.topic
                viewModel.selectedDuration = goal.duration
                viewModel.navigateToMain = true
            } else {
                viewModel.preloadFromCurrentGoalIfAvailable()
            }
        }
    }
}

#Preview { ContentView() }

