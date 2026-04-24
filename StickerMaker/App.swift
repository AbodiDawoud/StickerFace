//
//  StickerMakerApp.swift
//  StickerMaker
//

import SwiftUI

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
            .preferredColorScheme(.dark)
        }
    }
}

extension URL: @retroactive Identifiable {
    public var id: String { absoluteString }
}
