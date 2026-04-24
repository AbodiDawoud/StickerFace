//
//  BackgroundRemover.swift
//  StickerMaker
//
//  Uses VisionKit's subject lifting API to remove background.
//

import UIKit
import VisionKit
@preconcurrency import Vision

@MainActor
final class BackgroundRemover {

    /// Uses Vision's person/subject segmentation as a fallback approach.
    static func removeBackgroundWithVision(from image: UIImage) async throws -> UIImage {
        guard let cgImage = image.cgImage else {
            throw StickerError.invalidImage
        }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNGenerateForegroundInstanceMaskRequest()
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try handler.perform([request])

                    guard let result = request.results?.first else {
                        continuation.resume(throwing: StickerError.backgroundRemovalFailed)
                        return
                    }

                    let maskPixelBuffer = try result.generateScaledMaskForImage(
                        forInstances: result.allInstances,
                        from: handler
                    )

                    let ciImage = CIImage(cvPixelBuffer: maskPixelBuffer)
                    let originalCI = CIImage(cgImage: cgImage)

                    let filter = CIFilter(name: "CIBlendWithMask")!
                    filter.setValue(originalCI, forKey: kCIInputImageKey)
                    filter.setValue(ciImage, forKey: kCIInputMaskImageKey)
                    filter.setValue(CIImage.empty(), forKey: kCIInputBackgroundImageKey)

                    let context = CIContext()
                    guard let outputCG = context.createCGImage(filter.outputImage!, from: originalCI.extent) else {
                        continuation.resume(throwing: StickerError.backgroundRemovalFailed)
                        return
                    }

                    continuation.resume(returning: UIImage(cgImage: outputCG))
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
