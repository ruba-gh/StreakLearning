//
//  Theme.swift
//  LearnByStreak
//

import SwiftUI

// MARK: - Design System: Colors
enum ThemeColors {
    // Opaque brand orange; control opacity at call sites to avoid compounded transparency.
    static let brandOrange = Color(red: 255/255, green: 109/255, blue: 32/255)
    static let chipNeutral = Color.clear
}

// MARK: - Design System: Gradients
enum ThemeGradients {
    // Used on selected chips and primary buttons
    static let orangeCapsuleStroke = LinearGradient(
        gradient: Gradient(stops: [
            .init(color: Color(red: 233/255, green: 182/255, blue: 85/255), location: 0.0),
            .init(color: Color(red: 1.0, green: 0.8, blue: 0.2).opacity(0.3), location: 0.5),
            .init(color: Color(red: 233/255, green: 182/255, blue: 85/255).opacity(0.8), location: 1.0)
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Used on unselected chips
    static let neutralCapsuleStroke = LinearGradient(
        gradient: Gradient(stops: [
            .init(color: Color.gray.opacity(0.6), location: 0),
            .init(color: Color.black.opacity(0.3), location: 0.5),
            .init(color: Color.gray.opacity(0.6), location: 1.0)
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Capsule Strokes
struct OrangeCapsuleStroke: ViewModifier {
    var lineWidth: CGFloat = 1
    func body(content: Content) -> some View {
        content.overlay(
            Capsule().stroke(ThemeGradients.orangeCapsuleStroke, lineWidth: lineWidth)
        )
    }
}

struct NeutralCapsuleStroke: ViewModifier {
    var lineWidth: CGFloat = 1
    func body(content: Content) -> some View {
        content.overlay(
            Capsule().stroke(ThemeGradients.neutralCapsuleStroke, lineWidth: lineWidth)
        )
    }
}

extension View {
    func orangeCapsuleStroke(lineWidth: CGFloat = 1) -> some View {
        modifier(OrangeCapsuleStroke(lineWidth: lineWidth))
    }

    func neutralCapsuleStroke(lineWidth: CGFloat = 1) -> some View {
        modifier(NeutralCapsuleStroke(lineWidth: lineWidth))
    }
}

// MARK: - Button Styles
struct FilledOrangeCapsuleButtonStyle: ButtonStyle {
    var width: CGFloat? = nil
    var verticalPadding: CGFloat = 12

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 18, weight: .semibold))
            .padding(.vertical, verticalPadding)
            .padding(.horizontal, 16)
            .frame(width: width)
            .background(
                ZStack {
                    Capsule()
                        .fill(Color(red: 208/255, green: 90/255, blue: 20/255))

                    Capsule()
                        .stroke(
                            LinearGradient(
                                colors: [Color.orange, Color.clear, Color.orange.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )

                    Capsule()
                        .stroke(Color.red, lineWidth: 8)
                        .blur(radius: 15)
                        .offset(x: 1, y: 1)
                        .mask(Capsule().fill(Color.red))
                }
            )
            .clipShape(Capsule())
            .opacity(configuration.isPressed ? 0.96 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.995 : 1.0)
    }
}

struct SelectableCapsuleChipStyle: ButtonStyle {
    var isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        let base = Capsule()
        return configuration.label
            .font(.system(size: 16, weight: .semibold))
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .frame(width: 100, height: 48)
            .background(
                base.fill(isSelected ? ThemeColors.brandOrange.opacity(0.8) : ThemeColors.chipNeutral)
                    .overlay(
                        base.stroke(
                            isSelected ? ThemeGradients.orangeCapsuleStroke
                                       : ThemeGradients.neutralCapsuleStroke,
                            lineWidth: 1
                        )
                    )
            )
            .clipShape(Capsule())
            .glassEffect(.clear.interactive(true))
    }
}

// MARK: - Utility: Conditional modifier
extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition { transform(self) } else { self }
    }
}

