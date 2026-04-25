//
//  StickerEffect.swift
//  StickerMaker

import Foundation

enum StickerEffect: String, CaseIterable, Identifiable {
    case none
    case stroke
    case comic
    case puffy
    case iridescent

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .none: return "Original"
        case .stroke: return "Outline"
        case .comic: return "Comic"
        case .puffy: return "Puffy"
        case .iridescent: return "Shiny"
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
