//
//  StickerMakerApp.swift
//  StickerMaker
//

import SwiftUI
import Toasts

@main
struct StickerMakerApp: App {
    init() {
        let frameworkPath = "/System/Library/PrivateFrameworks/VisionKitCore.framework/VisionKitCore"
        dlopen(frameworkPath, RTLD_LAZY)
    }
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                ContentView()
            }
            .installToast(position: .top)
        }
    }
}

extension URL: @retroactive Identifiable {
    public var id: String { absoluteString }
}
