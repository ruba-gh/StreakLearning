import SwiftUI

struct DayCircle: View {
    let dateText: String
    let isToday: Bool
    let isLearned: Bool
    let isFreezed: Bool
    let size: CGFloat

    init(dateText: String, isToday: Bool, isLearned: Bool, isFreezed: Bool, size: CGFloat = 43) {
        self.dateText = dateText
        self.isToday = isToday
        self.isLearned = isLearned
        self.isFreezed = isFreezed
        self.size = size
    }

    var body: some View {
        Circle()
            .fill(
                isToday ? Color.orange :
                isLearned ? Color.orange.opacity(0.35) :
                isFreezed ? Color.cyan.opacity(0.35) :
                Color.clear
            )
            .frame(width: size, height: size)
            .overlay(
                Text(dateText)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(
                        isToday ? .white :
                        isLearned ? .orange :
                        isFreezed ? .cyan :
                        .primary
                    )
            )
    }
}

