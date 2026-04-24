//
//  StickerEffectApplier.swift
//  StickerMaker
//
//  Uses VisionKitCore private framework to apply sticker effects
//  similar to the iOS 17 Messages sticker system.
//

import UIKit

final class StickerEffectApplier {

    /// Applies a sticker effect to the given image using VisionKitCore private APIs.
    static func applyEffect(_ effectType: StickerEffectType, to image: UIImage) async throws -> UIImage {
        guard effectType != .none else { return image }

        return try await withCheckedThrowingContinuation { continuation in
            // Load VisionKitCore private framework
            let frameworkPath = "/System/Library/PrivateFrameworks/VisionKitCore.framework/VisionKitCore"
            guard dlopen(frameworkPath, RTLD_NOW) != nil else {
                continuation.resume(throwing: StickerError.frameworkNotAvailable)
                return
            }

            guard let VKCStickerEffect = NSClassFromString("VKCStickerEffect") as? NSObject.Type else {
                continuation.resume(throwing: StickerError.frameworkNotAvailable)
                return
            }

            // Get the effect instance (e.g., strokeEffect, puffyEffect, etc.)
            let effect = VKCStickerEffect.value(forKey: effectType.className) as! NSObject

            // Apply the effect to the image
            let applySelector = NSSelectorFromString("applyToImage:completion:")
            guard effect.responds(to: applySelector) else {
                continuation.resume(throwing: StickerError.effectApplicationFailed)
                return
            }

            let completionBlock: @convention(block) (AnyObject?) -> Void = { result in
                if let resultImage = result as? UIImage {
                    continuation.resume(returning: resultImage)
                } else if let data = result as? Data, let img = UIImage(data: data) {
                    continuation.resume(returning: img)
                } else {
                    continuation.resume(throwing: StickerError.effectApplicationFailed)
                }
            }

            effect.perform(
                applySelector,
                with: image,
                with: unsafeBitCast(completionBlock, to: AnyObject.self)
            )
        }
    }
}
