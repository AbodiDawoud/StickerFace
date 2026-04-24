//
//  EffectButton.swift
//  StickerMaker
//

import SwiftUI

struct EffectButton: View {
    let effect: StickerEffectType
    let isSelected: Bool
    let action: () -> Void
    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 9) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(isSelected ? Color(red: 0.20, green: 0.20, blue: 0.22) : Color(red: 0.105, green: 0.105, blue: 0.115))

                    Image(systemName: effect.iconName)
                        .font(.system(size: 21, weight: .semibold))
                        .foregroundStyle(isSelected ? Color.white : Color(red: 0.52, green: 0.52, blue: 0.56))
                        .symbolEffect(.bounce, value: isSelected)
                }
                .frame(width: 60, height: 54)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(
                            isSelected ? Color.white.opacity(0.22) : Color.white.opacity(0.06),
                            lineWidth: 1
                        )
                )
                .shadow(color: isSelected ? .black.opacity(0.36) : .clear, radius: 14, y: 8)

                Text(effect.displayName)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
                    .foregroundStyle(isSelected ? Color.white : Color(red: 0.48, green: 0.48, blue: 0.52))
            }
            .frame(width: 72)
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.96 : 1.0)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.spring(response: 0.2)) { isPressed = true }
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.5)) { isPressed = false }
                }
        )
        .animation(.spring(response: 0.4, dampingFraction: 0.65), value: isSelected)
    }
}
