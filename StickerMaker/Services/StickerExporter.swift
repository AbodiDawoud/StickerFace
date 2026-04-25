//
//  StickerExporter.swift
//  StickerMaker
//

import UIKit
import Photos

final class StickerExporter {

    /// Exports the sticker as a transparent PNG to the photo library.
    static func saveToPhotos(_ image: UIImage) async throws {
        let photoUrl = try temporaryFileURL(for: image)
        
        PHPhotoLibrary.shared().performChanges {
            let request = PHAssetCreationRequest.forAsset()
            request.addResource(with: .photo, fileURL: photoUrl, options: nil)
        } completionHandler: { success, _ in
            if success { cleanTemporaryFiles() }
        }
    }


    /// Returns a temporary file URL for sharing.
    static func temporaryFileURL(for image: UIImage) throws -> URL {
        guard let data = image.pngData() else {
            throw StickerError.exportFailed
        }

        
        let fileName = "sticker_\(UUID().uuidString).png"
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
        try data.write(to: tempURL)
        return tempURL
    }
    
    
    private static func cleanTemporaryFiles() {
        let location = URL(fileURLWithPath: NSTemporaryDirectory())
        
        do {
            let content = try FileManager.default.contentsOfDirectory(at: location, includingPropertiesForKeys: nil)
            
            try content.forEach { fileURL in
                try FileManager.default.removeItem(at: fileURL)
            }
        } catch {
            print("Error cleaning temporary files:\n \(error)")
        }
    }
}
