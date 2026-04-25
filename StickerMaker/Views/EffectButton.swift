//
//  EffectButton.swift
//  StickerMaker
//

import SwiftUI
import UIKit

struct EffectButton: View {
    let effect: StickerEffect
    let isSelected: Bool
    let previewImage: UIImage?
    let width: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 9) {
                thumbnail

                Text(effect.displayName)
                    .font(.system(size: 13, weight: isSelected ? .medium : .regular))
                    .foregroundStyle(isSelected ? Color.primary : Color.secondary.opacity(0.78))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
            .frame(width: width, height: 76, alignment: .top)
        }
        .buttonStyle(.plain)
        .transaction { transaction in
            transaction.animation = nil
        }
    }

    private var thumbnail: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .fill(isSelected ? Color(.tertiarySystemFill) : Color.clear)


            if let previewImage {
                Image(uiImage: previewImage)
                    .resizable()
                    .scaledToFit()
                    .padding(5)
                    .imageScale(.small)
            } else {
                ProgressView()
                    .controlSize(.small)
            }
        }
        .frame(width: thumbnailSize, height: thumbnailSize)
    }

    private var thumbnailSize: CGFloat {
        min(max(width - 4, 46), 54)
    }
}
