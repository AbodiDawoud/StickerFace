//
//  StickerViewModel.swift
//  StickerMaker
//

import SwiftUI
import PhotosUI

@MainActor
final class StickerViewModel: ObservableObject {

    enum State: Equatable {
        case idle
        case imageSelected
        case removingBackground
        case backgroundRemoved
        case applyingEffect
        case effectApplied
        case exporting
        case error(String)
    }

    @Published var state: State = .idle
    @Published var originalImage: UIImage?
    @Published var subjectImage: UIImage?       // Background removed
    @Published var stickerImage: UIImage?        // Final sticker with effect
    @Published var selectedEffect: StickerEffectType = .stroke
    @Published var selectedPhotoItem: PhotosPickerItem?
    @Published var shareURL: URL?
    @Published var showSavedAlert = false

    // MARK: - Photo Selection

    func handlePhotoSelection(_ item: PhotosPickerItem?) async {
        guard let item else { return }

        state = .imageSelected

        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else {
                state = .error("Could not load the selected image.")
                return
            }

            originalImage = image
            subjectImage = nil
            stickerImage = nil

            await removeBackground()
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    // MARK: - Background Removal

    func removeBackground() async {
        guard let originalImage else { return }

        state = .removingBackground

        do {
            // Try Vision-based segmentation first (more reliable)
            subjectImage = try await BackgroundRemover.removeBackgroundWithVision(from: originalImage)
            state = .backgroundRemoved

            // Auto-apply selected effect
            await applyEffect()
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    // MARK: - Effect Application

    func applyEffect() async {
        guard let subjectImage else { return }

        state = .applyingEffect

        do {
            stickerImage = try await StickerEffectApplier.applyEffect(selectedEffect, to: subjectImage)
            state = .effectApplied
        } catch {
            // If private API fails, fall back to the subject image without effect
            stickerImage = subjectImage
            state = .effectApplied
        }
    }

    func changeEffect(_ effect: StickerEffectType) async {
        selectedEffect = effect
        await applyEffect()
    }

    // MARK: - Export

    func saveToPhotos() async {
        guard let stickerImage else { return }

        state = .exporting
        do {
            try await StickerExporter.saveToPhotos(stickerImage)
            showSavedAlert = true
            state = .effectApplied
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    func shareSticker() {
        guard let stickerImage else { return }

        do {
            shareURL = try StickerExporter.temporaryFileURL(for: stickerImage)
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    // MARK: - Reset

    func reset() {
        state = .idle
        originalImage = nil
        subjectImage = nil
        stickerImage = nil
        selectedPhotoItem = nil
        selectedEffect = .stroke
        shareURL = nil
    }
}
