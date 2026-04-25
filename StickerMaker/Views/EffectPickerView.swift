//
//  EffectPickerView.swift
//  StickerMaker
//

import SwiftUI

struct EffectPickerView: View {
    @Environment(StickerViewModel.self) private var viewModel

    var body: some View {
        GeometryReader { proxy in
            let spacing: CGFloat = 8
            let horizontalPadding: CGFloat = 16
            let itemWidth = (proxy.size.width - horizontalPadding * 2 - spacing * CGFloat(StickerEffect.allCases.count - 1)) / CGFloat(StickerEffect.allCases.count)

            HStack(alignment: .top, spacing: spacing) {
                ForEach(StickerEffect.allCases) { effect in
                    EffectButton(
                        effect: effect,
                        isSelected: viewModel.isEffectSelected(effect),
                        previewImage: viewModel.previewImage(for: effect),
                        width: itemWidth
                    ) {
                        Task { await viewModel.changeEffect(effect) }
                    }
                }
            }
            .padding(.horizontal, horizontalPadding)
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .center)
        }
        .frame(height: 88)
        .background(Color(.systemBackground))
    }
}
