//
//  GlassButton.swift
//  StickerMaker
//
//  Dark control button with multiple style variants.
//

import SwiftUI

enum GlassButtonStyle {
    case primary
    case glass
    case subtle
}

struct GlassButton: View {
    let title: String
    let icon: String
    let style: GlassButtonStyle
    @State private var isPressed = false
    @State private var appeared = false

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .symbolEffect(.bounce, value: isPressed)

            Text(title)
                .font(.system(size: 15, weight: .semibold))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 15)
        .foregroundStyle(foregroundColor)
        .background(backgroundView)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(overlayBorder)
        .shadow(color: shadowColor, radius: 16, y: 8)
        .scaleEffect(isPressed ? 0.96 : 1.0)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 12)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                appeared = true
            }
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.spring(response: 0.2)) { isPressed = true }
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { isPressed = false }
                }
        )
    }

    private var shadowColor: Color {
        switch style {
        case .primary: return .black.opacity(0.38)
        case .glass: return .black.opacity(0.24)
        case .subtle: return .clear
        }
    }

    @ViewBuilder
    private var backgroundView: some View {
        switch style {
        case .primary:
            LinearGradient(
                colors: [
                    Color(red: 0.25, green: 0.25, blue: 0.27),
                    Color(red: 0.18, green: 0.18, blue: 0.20)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        case .glass:
            Rectangle().fill(Color(red: 0.12, green: 0.12, blue: 0.13))
        case .subtle:
            Rectangle().fill(Color(red: 0.085, green: 0.085, blue: 0.092))
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .primary: return Color(red: 0.94, green: 0.94, blue: 0.96)
        case .glass: return Color(red: 0.90, green: 0.90, blue: 0.92)
        case .subtle: return Color(red: 0.62, green: 0.62, blue: 0.66)
        }
    }

    private var overlayBorder: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .strokeBorder(
                style == .primary
                    ? .white.opacity(0.14)
                    : .white.opacity(0.08),
                lineWidth: 1
            )
    }
}
