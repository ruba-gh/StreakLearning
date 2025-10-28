//
//  CalendarView.swift
//  LearnByStreak
//

import SwiftUI
import Combine

struct CalendarView: View {
    @StateObject private var viewModel = CalendarViewModel()
    @State private var months: [Date] = []
    private let calendar = Calendar.current
    
    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 32) {
                        ForEach(months, id: \.self) { month in
                            monthSection(for: month)
                                .id(month)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                }
                .onAppear {
                    viewModel.load()
                    if let todayMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: Date())) {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            proxy.scrollTo(todayMonth, anchor: .center)
                        }
                    }
                }
            }
        }
        .navigationTitle("All activities")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            let now = Date()
            months = (0..<12).compactMap { calendar.date(byAdding: .month, value: -$0, to: now) }
                .compactMap { calendar.date(from: calendar.dateComponents([.year, .month], from: $0)) }
                .reversed()
        }
    }
    
    // MARK: Month Section
    private func monthSection(for month: Date) -> some View {
        let monthName = month.formatted(.dateTime.month(.wide).year())
        let days = makeDays(for: month)
        
        return VStack(alignment: .leading, spacing: 8) {
            Text(monthName)
                .foregroundColor(.primary)
                .font(.headline)
                .padding(.leading, 4)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 6) {
                ForEach(["SUN","MON","TUE","WED","THU","FRI","SAT"], id: \.self) { day in
                    Text(day)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                ForEach(days, id: \.self) { date in
                    if let date = date {
                        let day = calendar.startOfDay(for: date)
                        let isLearned = viewModel.learnedDates.contains(day)
                        let isFreezed = viewModel.freezedDates.contains(day)
                        let isToday = calendar.isDateInToday(day)

                        DayCircle(
                            dateText: date.formatted(.dateTime.day()),
                            isToday: isToday,
                            isLearned: isLearned,
                            isFreezed: isFreezed,
                            size: 43
                        )
                        .frame(width: 43, height: 43)
                    } else {
                        Circle()
                            .fill(Color.clear)
                            .frame(width: 43, height: 43)
                    }
                }
            }
            .padding(.vertical, 6)
        }
    }
    
    // MARK: Month Grid Layout
    private func makeDays(for month: Date) -> [Date?] {
        guard let range = calendar.range(of: .day, in: .month, for: month),
              let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: month))
        else { return [] }
        
        let weekdayOffset = calendar.component(.weekday, from: firstDay) - calendar.firstWeekday
        let offset = weekdayOffset >= 0 ? weekdayOffset : 7 + weekdayOffset
        
        return Array(repeating: nil, count: offset)
        + range.compactMap { calendar.date(byAdding: .day, value: $0 - 1, to: firstDay) }
    }
}

#Preview {
    NavigationStack { CalendarView() }
}

