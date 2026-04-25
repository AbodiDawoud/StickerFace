//
//  StickerViewModel.swift
//  StickerMaker
//

import SwiftUI
import PhotosUI
import Toasts

@MainActor
@Observable
final class StickerViewModel {
    var state: State = .idle
    var originalImage: UIImage?       // Imported image, we should keep it unmodified
    var subjectImage: UIImage?       // Background removed
    var stickerImage: UIImage?        // Final sticker with effect
    var selectedEffect: StickerEffect = .none
    var isCombiningEffects = false
    private(set) var combinedEffects: [StickerEffect] = []
    var selectedPhotoItem: PhotosPickerItem?
    
    private(set) var effectPreviewImages: [StickerEffect: UIImage] = [:]

    
    // MARK: - Photo Selection

    func handlePhotoSelection(_ item: PhotosPickerItem?) async {
        guard let item else { return }

        state = .imageSelected

        do {
            guard let data = try await item.loadTransferable(type: Data.self) else {
                state = .error("Could not load the selected image.")
                return
            }

            await handleImageData(data)
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    func handleImageData(_ data: Data) async {
        state = .imageSelected

        guard let image = UIImage(data: data) else {
            state = .error("Could not load the selected image.")
            return
        }

        originalImage = image
        subjectImage = nil
        stickerImage = nil
        effectPreviewImages = [:]

        await removeBackground()
    }

    // MARK: - Background Removal

    func removeBackground() async {
        guard let originalImage else { return }

        state = .removingBackground

        do {
            // Try Vision-based segmentation first (more reliable)
            subjectImage = try await BackgroundRemover.removeBackgroundWithVision(from: originalImage)
            if let subjectImage {
                effectPreviewImages = [.none: subjectImage]
            }
            state = .backgroundRemoved

            Task { await generateEffectPreviews() }

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
            stickerImage = try await StickerEffectApplier.applyEffects(selectedEffects, to: subjectImage)
            state = .effectApplied
        } catch {
            // If private API fails, fall back to the subject image without effect
            stickerImage = subjectImage
            state = .effectApplied
        }
    }

    
    func changeEffect(_ effect: StickerEffect) async {
        var transaction = Transaction()
        transaction.disablesAnimations = true

        withTransaction(transaction) {
            updateSelection(with: effect)
        }

        await applyEffect()
    }

    func isEffectSelected(_ effect: StickerEffect) -> Bool {
        if isCombiningEffects && combinedEffects.isEmpty {
            return effect == .none
        }

        return selectedEffects.contains(effect)
    }

    func setCombiningEffects(_ isEnabled: Bool) async {
        var transaction = Transaction()
        transaction.disablesAnimations = true

        withTransaction(transaction) {
            isCombiningEffects = isEnabled

            if isEnabled {
                combinedEffects = selectedEffect == .none ? [] : [selectedEffect]
            } else {
                selectedEffect = combinedEffects.last ?? selectedEffect
                combinedEffects = []
            }
        }

        await applyEffect()
    }

    func previewImage(for effect: StickerEffect) -> UIImage? {
        effectPreviewImages[effect] ?? subjectImage
    }

    
    private func generateEffectPreviews() async {
        guard let subjectImage else { return }

        for effect in StickerEffect.allCases where effectPreviewImages[effect] == nil {
            do {
                let preview = try await StickerEffectApplier.applyEffect(effect, to: subjectImage)
                effectPreviewImages[effect] = preview
            } catch {
                effectPreviewImages[effect] = subjectImage
            }
        }
    }

    
    func saveToPhotos() async -> Bool {
        guard let stickerImage else { return false }
        state = .exporting
        
        do {
            try await StickerExporter.saveToPhotos(stickerImage)
            state = .effectApplied
            return true
        } catch {
            state = .error(error.localizedDescription)
            return false
        }
    }

    func reset() {
        state = .idle
        originalImage = nil
        subjectImage = nil
        stickerImage = nil
        selectedPhotoItem = nil
        selectedEffect = .none
        isCombiningEffects = false
        combinedEffects = []
        effectPreviewImages = [:]
    }

    private var selectedEffects: [StickerEffect] {
        isCombiningEffects ? combinedEffects : [selectedEffect]
    }

    private func updateSelection(with effect: StickerEffect) {
        guard isCombiningEffects else {
            selectedEffect = effect
            return
        }

        if effect == .none {
            combinedEffects = []
            selectedEffect = .none
            return
        }

        combinedEffects.removeAll { $0 == .none }

        if combinedEffects.contains(effect) {
            combinedEffects.removeAll { $0 == effect }
        } else {
            if combinedEffects.count == 2 {
                combinedEffects.removeFirst()
            }
            combinedEffects.append(effect)
        }

        selectedEffect = combinedEffects.last ?? .none
    }
}

extension StickerViewModel {
    /// The state of the view model currently running
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
}
