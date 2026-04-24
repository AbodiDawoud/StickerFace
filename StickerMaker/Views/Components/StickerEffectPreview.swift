//
//  StickerEffectPreview.swift
//  StickerMaker
//
//  UIViewRepresentable that wraps VKCStickerEffectView for live animated preview.
//

import SwiftUI
import UIKit

struct StickerEffectPreview: UIViewRepresentable {
    let image: UIImage
    let effect: StickerEffectType

    func makeUIView(context: Context) -> UIView {
        guard let VKCStickerEffect = NSClassFromString("VKCStickerEffect") as? NSObject.Type,
              let VKCStickerEffectView = NSClassFromString("VKCStickerEffectView") as? UIView.Type else {
            // Fallback: just show a plain UIImageView
            let imageView = UIImageView(image: image)
            imageView.contentMode = .scaleAspectFit
            return imageView
        }

        let effect_object = VKCStickerEffect.value(forKey: effect.className) as! NSObject

        let view = VKCStickerEffectView.init()
        view.setValue(image, forKey: "image")
        view.setValue(effect_object, forKey: "effect")
        view.setValue(false, forKey: "paused")

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // Update effect if the view supports it
        if uiView.responds(to: NSSelectorFromString("setEffect:")) {
            let VKCStickerEffect = NSClassFromString("VKCStickerEffect") as! NSObject.Type
            let effectObj = VKCStickerEffect.value(forKey: effect.className) as! NSObject
            uiView.setValue(effectObj, forKey: "effect")
            uiView.setValue(image, forKey: "image")
        }
    }
}
