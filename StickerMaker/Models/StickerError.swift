//
//  StickerError.swift
//  StickerMaker
//

import Foundation

enum StickerError: LocalizedError {
    case invalidImage
    case backgroundRemovalFailed
    case frameworkNotAvailable
    case effectApplicationFailed
    case exportFailed
    case noFaceDetected

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "The selected image could not be processed."
        case .backgroundRemovalFailed:
            return "Failed to remove the background from the image."
        case .frameworkNotAvailable:
            return "Sticker effects are not available on this device."
        case .effectApplicationFailed:
            return "Failed to apply the sticker effect."
        case .exportFailed:
            return "Failed to export the sticker."
        case .noFaceDetected:
            return "No face detected."
        }
    }
}
