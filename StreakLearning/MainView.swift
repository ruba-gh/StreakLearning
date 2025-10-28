//
//  MainView.swift
//  LearnByStreak
//

import SwiftUI
import Combine

struct MainView: View {
    // Inputs from Edit/Onboarding
    init(learningTopic: String = "Swift", selectedDuration: String = "Week") {
        _dashboardViewModel = StateObject(wrappedValue: MainViewModel(learningTopic: learningTopic, selectedDuration: selectedDuration))
    }

    // State
    @StateObject private var dashboardViewModel: MainViewModel
    @StateObject private var calendarVM = CalendarViewModel()

    // Periodic refresh
    private let minuteTick = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    // Month/Year picker state
    @State private var isShowingMonthYearPicker = false
    @State private var selectedDate = Calendar.current.startOfDay(for: Date())

    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 12) {
                    headerToolbar

                    WeeklyProgressCardView(
                        streakCount: calendarVM.learnedDates.count,
                        freezesUsedCount: calendarVM.freezedDates.count,
                        topic: dashboardViewModel.learningTopic,
                        learnedDates: calendarVM.learnedDates,
                        freezedDates: calendarVM.freezedDates,
                        externalSelectedDate: $selectedDate,
                        isShowingPicker: $isShowingMonthYearPicker
                    )
                    .frame(maxWidth: 340)

                    if dashboardViewModel.isGoalCompleted {
                        celebrationSection
                            .padding(.top, 28)
                    } else {
                        Button(action: dashboardViewModel.handleCircleTap) {
                            ZStack {
                                Circle()
                                    .fill(primaryActionCircleFill(for: dashboardViewModel.learnedState))
                                    .overlay(Circle().stroke(primaryActionCircleStroke(for: dashboardViewModel.learnedState), lineWidth: 1.5))
                                    .frame(width: 270, height: 270)

                                Text(primaryActionCircleTitle(for: dashboardViewModel.learnedState))
                                    .font(.system(size: 35, weight: .bold))
                                    .foregroundColor(primaryActionCircleTextColor(for: dashboardViewModel.learnedState))
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 64)

                        Button {
                            withAnimation(.easeInOut(duration: 0.15)) { dashboardViewModel.isFreezeButtonPressed = true }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                                dashboardViewModel.isFreezeButtonPressed = false
                                dashboardViewModel.toggleFreeze()
                                calendarVM.load()
                            }
                        } label: {
                            Text("Log as Freezed")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(
                            FreezeActionButtonStyle(
                                isPressedExternally: dashboardViewModel.isFreezeButtonPressed,
                                isSelected: dashboardViewModel.isTodayFreezed,
                                isDisabled: (dashboardViewModel.isFreezeDisabled && !dashboardViewModel.isTodayFreezed)
                            )
                        )
                        .disabled(dashboardViewModel.isFreezeDisabled && !dashboardViewModel.isTodayFreezed)
                        .opacity((dashboardViewModel.isFreezeDisabled && !dashboardViewModel.isTodayFreezed) ? 0.5 : 1)
                        .padding(.horizontal, 28)
                        .padding(.top, 8)

                        Text("\(dashboardViewModel.freezesUsed) out of \(dashboardViewModel.maxFreezes) Freezes used")
                            .font(.system(size: 13))
                            .foregroundColor(.gray)
                            .padding(.bottom, 6)
                    }

                    Spacer(minLength: 0)
                }
                .padding(.top, 0)
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            dashboardViewModel.onAppear()
            calendarVM.load()
            selectedDate = Calendar.current.startOfDay(for: Date())
        }
        .onReceive(minuteTick) { _ in
            dashboardViewModel.onTick()
            calendarVM.load()
        }
    }

    // MARK: Celebration
    private var celebrationSection: some View {
        VStack(spacing: 22) {
            Image(systemName: "hands.clap.fill")
                .foregroundStyle(.orange)
                .font(.system(size: 36, weight: .bold))
                .padding(.top,50)

            Text("Well done!")
                .font(.system(size: 32, weight: .bold))

            Text("Goal completed! start learning again or set new learning goal")
                .font(.system(size: 18, weight: .regular))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 28)

            NavigationLink(destination: EditView()) {
                Text("Set new learning goal")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: 300)
                    .padding(.vertical, 14)
                    .background(
                        ZStack {
                            Capsule().fill(Color(red: 208/255, green: 90/255, blue: 20/255))
                            Capsule().stroke(ThemeGradients.orangeCapsuleStroke, lineWidth: 1)
                        }
                    )
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .padding(.top, 30)

            Button {
                dashboardViewModel.restartSameGoal()
            } label: {
                Text("Set same learning goal and duration")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.orange)
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
            .padding(.bottom, 20)
        }
    }

    // MARK: Header
    private var headerToolbar: some View {
        HStack(spacing: 16) {
            Text("Activity")
                .font(.system(size: 40, weight: .bold))

            Spacer()

            NavigationLink(destination: CalendarView()) { ToolbarCircleIcon(systemName: "calendar") }
            NavigationLink(destination: EditView()) { ToolbarCircleIcon(systemName: "pencil.and.outline") }
        }
        .padding(.bottom, 20)
        .padding(.top, 24)
    }

    // MARK: Primary Action Circle
    private func primaryActionCircleFill(for state: MainViewModel.LearnedState) -> LinearGradient {
        switch state {
        case .notLearned: return DashboardGradients.learnDefault
        case .learned:    return DashboardGradients.learned
        case .freezed:    return DashboardGradients.freezed
        }
    }

    private func primaryActionCircleStroke(for state: MainViewModel.LearnedState) -> LinearGradient {
        switch state {
        case .notLearned: return DashboardGradients.strokeDefault
        case .learned:    return DashboardGradients.strokeLearned
        case .freezed:    return DashboardGradients.strokeFreezed
        }
    }

    private func primaryActionCircleTextColor(for state: MainViewModel.LearnedState) -> Color {
        switch state {
        case .notLearned: return .white
        case .learned:    return .orange
        case .freezed:    return Color(red: 15/255, green: 239/255, blue: 255/255)
        }
    }

    private func primaryActionCircleTitle(for state: MainViewModel.LearnedState) -> String {
        switch state {
        case .notLearned: return "Log as\nLearned"
        case .learned:    return "Learned\nToday"
        case .freezed:    return "Day\nFreezed"
        }
    }
}

// MARK: Freeze button style and Gradients
private struct FreezeActionButtonStyle: ButtonStyle {
    var isPressedExternally: Bool
    var isSelected: Bool
    var isDisabled: Bool

    func makeBody(configuration: Configuration) -> some View {
        let isPressed = configuration.isPressed || isPressedExternally || isSelected
        return configuration.label
            .font(.system(size: 18, weight: .semibold))
            .frame(width: 300)
            .padding(.vertical, 14)
            .background(
                (isPressed ? DashboardGradients.freezePressed : DashboardGradients.freezeNormal)
                    .opacity(isPressed ? 0.8 : 1.0)
            )
            .clipShape(Capsule())
            .overlay(Capsule().stroke(DashboardGradients.capsuleStroke, lineWidth: 1))
            .glassEffect(.clear)
    }
}

private enum DashboardGradients {
    static let learnDefault = LinearGradient(colors: [
        ThemeColors.brandOrange.opacity(0.9),
        ThemeColors.brandOrange.opacity(0.7)
    ], startPoint: .topLeading, endPoint: .bottomTrailing)

    static let learned = LinearGradient(colors: [
        Color(red: 239/255, green: 123/255, blue: 72/255, opacity: 0.05),
        Color(red: 246/255, green: 64/255, blue: 3/255, opacity: 0.06)
    ], startPoint: .topLeading, endPoint: .bottomTrailing)

    static let freezed = LinearGradient(colors: [
        Color(red: 32/255, green: 142/255, blue: 163/255, opacity: 0.05),
        Color(red: 0/255, green: 97/255, blue: 106/255, opacity: 0.06)
    ], startPoint: .topLeading, endPoint: .bottomTrailing)

    static let strokeDefault = LinearGradient(colors: [
        Color.white.opacity(0.6),
        Color(red: 174/255, green: 98/255, blue: 31/255).opacity(0.2),
        Color.white.opacity(0.5)
    ], startPoint: .topLeading, endPoint: .bottomTrailing)

    static let strokeLearned = ThemeGradients.orangeCapsuleStroke

    static let strokeFreezed = LinearGradient(colors: [
        Color.cyan.opacity(0.6),
        Color(red: 45/255, green: 154/255, blue: 201/255).opacity(0.1),
        Color(red: 45/255, green: 154/255, blue: 201/255).opacity(0.6)
    ], startPoint: .topLeading, endPoint: .bottomTrailing)

    static let freezeNormal = LinearGradient(colors: [
        Color.cyan.opacity(0.7),
        Color.cyan.opacity(0.5),
        Color.cyan.opacity(0.6),
    ], startPoint: .topLeading, endPoint: .bottomTrailing)

    static let freezePressed = LinearGradient(colors: [
        Color(red: 32/255, green: 142/255, blue: 163/255, opacity: 0.05),
        Color(red: 32/255, green: 142/255, blue: 163/255, opacity: 0.05),
        Color(red: 32/255, green: 142/255, blue: 163/255, opacity: 0.05)
    ], startPoint: .topLeading, endPoint: .bottomTrailing)

    static let capsuleStroke = ThemeGradients.neutralCapsuleStroke

    static let cardStrokeGrayBlack = LinearGradient(
        gradient: Gradient(stops: [
            .init(color: Color.white.opacity(0.3), location: 0.0),
            .init(color: Color.black.opacity(0.4), location: 0.5),
            .init(color: Color.white.opacity(0.2), location: 1.0)
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: Toolbar Icon
struct ToolbarCircleIcon: View {
    var systemName: String
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.06))
                .frame(width: 40, height: 40)
                .glassEffect(.clear)
                .overlay(
                    Circle()
                        .stroke(DashboardGradients.cardStrokeGrayBlack, lineWidth: 0.7)
                )
            Image(systemName: systemName)
                .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
                .font(.system(size: 18, weight: .medium))
        }
    }
}

// MARK: Weekly Progress Card
struct WeeklyProgressCardView: View {
    var streakCount: Int
    var freezesUsedCount: Int
    var topic: String
    var learnedDates: Set<Date>
    var freezedDates: Set<Date>

    @Binding var externalSelectedDate: Date
    @Binding var isShowingPicker: Bool

    private let calendar = Calendar.current
    @State private var visibleWeekAnchorDate = Date()
    @Environment(\.colorScheme) private var colorScheme

    private static let dayNumberFormatter: DateFormatter = { let f = DateFormatter(); f.dateFormat = "d"; return f }()
    private static let weekdayFormatter: DateFormatter = { let f = DateFormatter(); f.dateFormat = "EEE"; return f }()
    private static let monthYearFormatter: DateFormatter = { let f = DateFormatter(); f.dateFormat = "LLLL yyyy"; return f }()

    private var daysInVisibleWeek: [Date] {
        guard let interval = calendar.dateInterval(of: .weekOfYear, for: visibleWeekAnchorDate) else { return [] }
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: interval.start) }
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.06))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(DashboardGradients.cardStrokeGrayBlack, lineWidth: 1))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.gray, lineWidth: 8)
                        .blur(radius: 15)
                        .offset(x: 1, y: 1)
                        .mask(
                            RoundedRectangle(cornerRadius: 18).fill(
                                LinearGradient(
                                    colors: [Color.gray, Color.clear],
                                    startPoint: .bottomTrailing,
                                    endPoint: .topLeading
                                )
                            )
                        )
                        .opacity(0.3)
                )
                .padding(.top, 20)

            VStack(alignment: .leading, spacing: 25) {
                HStack(spacing: 8) {
                    Text(Self.monthYearFormatter.string(from: visibleWeekAnchorDate))
                        .font(.system(size: 16, weight: .semibold))

                    Button {
                        withAnimation(.easeInOut) { isShowingPicker.toggle() }
                    } label: {
                        Image(systemName: "chevron.right")
                            .foregroundColor(.orange)
                            .bold()
                    }

                    Spacer()

                    Button { shiftVisibleWeek(by: -1) } label: {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.orange)
                            .bold()
                    }
                    .padding(.trailing, 27)

                    Button { shiftVisibleWeek(by: +1) } label: {
                        Image(systemName: "chevron.right")
                            .foregroundColor(.orange)
                            .bold()
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 40)
                .disabled(isShowingPicker)
                .opacity(isShowingPicker ? 0.4 : 1)

                HStack(spacing: 12) {
                    ForEach(daysInVisibleWeek, id: \.self) { date in
                        VStack(spacing: 6) {
                            Text(Self.weekdayFormatter.string(from: date).uppercased())
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.gray)

                            let dayStart = calendar.startOfDay(for: date)
                            let didLearn = learnedDates.contains(dayStart)
                            let didFreeze = freezedDates.contains(dayStart)
                            let isToday = calendar.isDateInToday(date)

                            Circle()
                                .fill(isToday ? .orange :
                                        didLearn ? Color.orange.opacity(0.35) :
                                        didFreeze ? Color.cyan.opacity(0.35) : .clear)
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Text(Self.dayNumberFormatter.string(from: date))
                                        .font(.system(size: 24, weight: .semibold))
                                        .foregroundColor(
                                            isToday
                                            ? .white
                                            : didLearn
                                                ? .orange
                                                : didFreeze
                                                    ? .cyan
                                                    : (colorScheme == .light ? .black : .white)
                                        )
                                )
                        }
                    }
                }
                .padding(.horizontal, 15)
                .disabled(isShowingPicker)
                .opacity(isShowingPicker ? 0.4 : 1)

                Divider()
                    .background(Color.white.opacity(0.18))
                    .padding(.horizontal, 20)
                    .opacity(isShowingPicker ? 0.4 : 1)

                Text("Learning " + topic)
                    .padding(.leading)
                    .padding(.vertical,-12)
                    .bold()
                    .opacity(isShowingPicker ? 0.4 : 1)

                HStack(spacing: 20) {
                    buildStatCard(icon: "flame.fill", color: .orange, value: streakCount,
                                  text: streakCount == 1 ? "Day Learned" : "Days Learned")

                    buildStatCard(icon: "cube.fill", color: .cyan, value: freezesUsedCount,
                                  text: freezesUsedCount == 1 ? "Day Freezed" : "Days Freezed", textColor: .white)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
                .opacity(isShowingPicker ? 0.4 : 1)
                .disabled(isShowingPicker)
            }

            if isShowingPicker {
                MonthYearPicker(selected: $externalSelectedDate)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                    .padding(.horizontal, 16)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(height: 212)
        .padding(.horizontal, 16)
        .onAppear {
            visibleWeekAnchorDate = externalSelectedDate
        }
        .onChange(of: externalSelectedDate) { _, newValue in
            if let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: newValue)) {
                visibleWeekAnchorDate = startOfMonth
            } else {
                visibleWeekAnchorDate = newValue
            }
        }
    }

    @ViewBuilder
    private func buildStatCard(icon: String, color: Color, value: Int, text: String, textColor: Color = .white) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 22, weight: .semibold))
            VStack(alignment: .leading, spacing: 2) {
                Text("\(value)")
                    .font(.system(size: 22, weight: .semibold))
                Text(text)
                    .font(.system(size: 12, weight: .medium))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(color.opacity(0.35))
        .clipShape(RoundedRectangle(cornerRadius: 40))
        .overlay(RoundedRectangle(cornerRadius: 40).stroke(Color.white.opacity(0.12), lineWidth: 1))
    }

    private func shiftVisibleWeek(by offset: Int) {
        if let newDate = Calendar.current.date(byAdding: .weekOfYear, value: offset, to: visibleWeekAnchorDate) {
            visibleWeekAnchorDate = newDate
        }
    }
}

// MARK: Month / Year Picker
struct MonthYearPicker: View {
    @Binding var selected: Date

    @State private var tempMonth: Int = Calendar.current.component(.month, from: Date())
    @State private var tempYear: Int = Calendar.current.component(.year, from: Date())

    private let calendar = Calendar.current
    private let months = Array(1...12)

    private let years: [Int] = {
        let current = Calendar.current.component(.year, from: Date())
        return Array((current - 50)...(current + 50))
    }()

    @State private var rowHeight: CGFloat = 34
    private let selectionCornerRadius: CGFloat = 10
    private let selectionPadding: CGFloat = 6
    private let selectionColor = Color.gray.opacity(1)

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                GeometryReader { proxy in
                    let totalWidth = proxy.size.width
                    let totalHeight = proxy.size.height

                    RoundedRectangle(cornerRadius: selectionCornerRadius, style: .continuous)
                        .fill(selectionColor)
                        .frame(width: totalWidth - selectionPadding * 2, height: 35)
                        .position(x: totalWidth / 2, y: totalHeight / 2)
                        .allowsHitTesting(false)
                }

                HStack(spacing: 0) {
                    WheelColumn(
                        title: "Month",
                        selection: $tempMonth,
                        options: months,
                        label: { month in Text(monthName(for: month)) },
                        rowHeight: $rowHeight
                    )
                    WheelColumn(
                        title: "Year",
                        selection: $tempYear,
                        options: years,
                        label: { year in Text(String(year)) },
                        rowHeight: $rowHeight
                    )
                }
            }
            .frame(height: rowHeight * 5 + 8)
            .padding(.horizontal)
            .padding(.vertical,30)
        }
        .padding(.bottom, 12)
        .background(Color(.secondarySystemBackground))
        .onAppear {
            let comps = calendar.dateComponents([.year, .month], from: selected)
            tempMonth = comps.month ?? tempMonth
            tempYear = comps.year ?? tempYear
        }
        .onChange(of: tempMonth) { _, _ in writeBack() }
        .onChange(of: tempYear) { _, _ in writeBack() }
    }

    private func monthName(for month: Int) -> String {
        let symbols = calendar.monthSymbols
        let idx = max(1, min(12, month)) - 1
        return symbols[idx]
    }

    private func writeBack() {
        var comps = DateComponents()
        comps.year = tempYear
        comps.month = tempMonth
        comps.day = 1
        if let date = calendar.date(from: comps) {
            selected = date
        }
    }
}

private struct WheelColumn<Option: Hashable, Label: View>: View {
    let title: String
    @Binding var selection: Option
    let options: [Option]
    @ViewBuilder var label: (Option) -> Label

    @Binding var rowHeight: CGFloat

    var body: some View {
        Picker(title, selection: $selection) {
            ForEach(options, id: \.self) { option in
                label(option)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .background(
                        GeometryReader { proxy in
                            Color.clear
                                .onAppear {
                                    let h = proxy.size.height
                                    if h > 0, abs(h - rowHeight) > 0.5 {
                                        rowHeight = h
                                    }
                                }
                        }
                    )
            }
        }
        .pickerStyle(.wheel)
        .frame(maxWidth: .infinity)
        .clipped()
        .compositingGroup()
        .labelsHidden()
        .background(Color.clear)
    }
}

#Preview {
    NavigationStack {
        MainView(learningTopic: "Swift", selectedDuration: "Week")
    }
}

