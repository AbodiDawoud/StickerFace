//
//  StickerEffect.swift
//  StickerMaker
//

import Foundation

enum StickerEffectType: String, CaseIterable, Identifiable {
    case none
    case stroke
    case puffy
    case comic
    case iridescent

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .none: return "None"
        case .stroke: return "Stroke"
        case .puffy: return "Puffy"
        case .comic: return "Comic"
        case .iridescent: return "Iridescent"
        }
    }

    var iconName: String {
        switch self {
        case .none: return "circle.dashed"
        case .stroke: return "scribble"
        case .puffy: return "cloud.fill"
        case .comic: return "camera.filters"
        case .iridescent: return "sparkle"
        }
    }

    /// The class method name on VKCStickerEffect
    var className: String {
        switch self {
        case .none: return "noneEffect"
        case .stroke: return "strokeEffect"
        case .puffy: return "puffyEffect"
        case .comic: return "comicEffect"
        case .iridescent: return "iridescentEffect"
        }
    }
}
