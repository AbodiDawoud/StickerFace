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
        var lastError: Error?

        for attempt in 1...3 {
            do {
                return try await performForegroundMaskRequest(on: image)
            } catch {
                lastError = error

                guard attempt < 3 else { break }
                try await Task.sleep(for: .milliseconds(180 * attempt))
            }
        }

        throw lastError ?? StickerError.backgroundRemovalFailed
    }

    private static func performForegroundMaskRequest(on image: UIImage) async throws -> UIImage {
        guard let cgImage = image.cgImage else {
            throw StickerError.invalidImage
        }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNGenerateForegroundInstanceMaskRequest()
            let handler = VNImageRequestHandler(
                cgImage: cgImage,
                orientation: image.cgImagePropertyOrientation,
                options: [:]
            )

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
                    let orientedOriginalCI = CIImage(cgImage: cgImage)
                        .oriented(image.cgImagePropertyOrientation)
                    let originalCI = orientedOriginalCI.transformed(
                        by: CGAffineTransform(
                            translationX: -orientedOriginalCI.extent.origin.x,
                            y: -orientedOriginalCI.extent.origin.y
                        )
                    )

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

private extension UIImage {
    var cgImagePropertyOrientation: CGImagePropertyOrientation {
        switch imageOrientation {
        case .up:
            return .up
        case .upMirrored:
            return .upMirrored
        case .down:
            return .down
        case .downMirrored:
            return .downMirrored
        case .left:
            return .left
        case .leftMirrored:
            return .leftMirrored
        case .right:
            return .right
        case .rightMirrored:
            return .rightMirrored
        @unknown default:
            return .up
        }
    }
}
