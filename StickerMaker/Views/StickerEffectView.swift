//
//  StickerEffectView.swift
//  StickerMaker
    

import SwiftUI

struct StickerEffectView: UIViewRepresentable {
    var image: UIImage
    var effect: StickerEffect = .comic

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    func makeUIView(context: Context) -> UIView {
        let controller = NSClassFromString("VKCStickerEffectView") as! UIView.Type
        let view = controller.init()
        view.setValue(false, forKey: "paused")
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        let VKCStickerEffect = NSClassFromString("VKCStickerEffect") as! NSObject.Type
        let stickerEffect = VKCStickerEffect.value(forKey: effect.className) as! NSObject

        if context.coordinator.lastEffect != effect {
            uiView.setValue(stickerEffect, forKey: "effect")
            context.coordinator.lastEffect = effect
        }

        if context.coordinator.lastImage !== image {
            uiView.setValue(image, forKey: "image")
            context.coordinator.lastImage = image
        }

        uiView.setValue(false, forKey: "paused")
        uiView.setNeedsLayout()
    }

    final class Coordinator {
        var lastImage: UIImage?
        var lastEffect: StickerEffect?
    }
}

