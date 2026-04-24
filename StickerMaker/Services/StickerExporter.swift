//
//  StickerExporter.swift
//  StickerMaker
//

import UIKit

final class StickerExporter {

    /// Exports the sticker as a transparent PNG to the photo library.
    static func saveToPhotos(_ image: UIImage) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
            continuation.resume()
        }
    }


    /// Returns a temporary file URL for sharing.
    static func temporaryFileURL(for image: UIImage) throws -> URL {
        guard let data = image.pngData() else {
            throw StickerError.exportFailed
        }

        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "sticker_\(UUID().uuidString).png"
        let fileURL = tempDir.appendingPathComponent(fileName)

        try data.write(to: fileURL)
        return fileURL
    }
}
