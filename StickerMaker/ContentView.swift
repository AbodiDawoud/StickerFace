//
//  ContentView.swift
//  StickerMaker
//

import PhotosUI
import SwiftUI
import Toasts
import UniformTypeIdentifiers

struct ContentView: View {
    @Environment(\.presentToast) private var presentToast
    @State private var viewModel = StickerViewModel()
    @State private var isDropTargeted = false
    @State private var isResettingSticker = false

    
    var body: some View {
        GeometryReader { proxy in
            if let previewImage {
                let previewSide = min(proxy.size.width * 0.82, proxy.size.height * 0.68, 330)

                StickerEffectView(image: previewImage, effect: viewModel.selectedEffect)
                    .frame(width: previewSide, height: previewSide)
                    .scaleEffect(isResettingSticker ? 0.72 : 1)
                    .rotationEffect(.degrees(isResettingSticker ? -5 : 0))
                    .opacity(isResettingSticker ? 0 : 1)
                    .blur(radius: isResettingSticker ? 7 : 0)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.94)),
                        removal: .opacity.combined(with: .scale(scale: 0.72))
                    ))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else {
                emptyPicker
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .padding(.bottom, 100)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 1.04)),
                        removal: .opacity.combined(with: .scale(scale: 0.96))
                    ))
            }

            if isDropTargeted && !hasImage {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .strokeBorder(Color.secondary.opacity(0.35), style: StrokeStyle(lineWidth: 2, dash: [8, 8]))
                    .padding(5)
                    .transition(.opacity)
            }
        }
        .contentShape(Rectangle())
        .overlay(alignment: .topTrailing) {
            if hasImage {
                topActions
                    .padding([.top, .trailing], 18)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if hasImage {
                EffectPickerView()
                    .environment(viewModel)
                    .padding(.bottom, 10)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onChange(of: viewModel.selectedPhotoItem) { _, newValue in
            Task { await viewModel.handlePhotoSelection(newValue) }
        }
        .onChange(of: viewModel.state) { _, newValue in
            if case let .error(message) = newValue {
                presentToast(
                    .init(icon: Image(systemName: "exclamationmark.triangle").foregroundStyle(.red),
                          message: message
                         )
                )
            }
        }
        .animation(.spring(response: 0.42, dampingFraction: 0.82), value: viewModel.state)
        .onDrop(of: [UTType.image.identifier], isTargeted: $isDropTargeted, perform: handleImageDrop)
    }
    


    
    private var emptyPicker: some View {
        VStack(spacing: 0) {
            Image(.mockStickerIcon)
                .resizable()
                .scaledToFit()
                .frame(width: 300, height: 300)

                PhotosPicker(selection: $viewModel.selectedPhotoItem, matching: .images) {
                    Text("Select Image")
                        .font(.system(size: 16.4, weight: .semibold))
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 21)
                        .padding(.vertical, 12)
                        .background(Color(.tertiarySystemFill), in: Capsule())
                }
                .buttonStyle(.plain)
                .offset(y: -25)
        }
    }

    
    private var topActions: some View {
        HStack(spacing: 10) {
            Button("Done", action: finishSticker)
                .buttonStyle(PillButtonStyle())

            Button {
                Task { await saveSticker() }
            } label: {
                Text("Save")
            }
            .buttonStyle(PillButtonStyle())
            .disabled(viewModel.stickerImage == nil || viewModel.state == .exporting)
        }
    }
    

    private func handleImageDrop(_ providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.image.identifier) }) else {
            return false
        }

        provider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { data, _ in
            guard let data else { return }

            Task { @MainActor in
                await viewModel.handleImageData(data)
                presentToast(
                    ToastValue(
                        icon: Image(systemName: "photo"),
                        message: "Image loaded"
                    )
                )
            }
        }

        return true
    }

    private func finishSticker() {
        guard hasImage else { return }

        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        withAnimation(.easeInOut(duration: 0.24)) {
            isResettingSticker = true
        }

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(220))

            withAnimation(.spring(response: 0.44, dampingFraction: 0.86)) {
                viewModel.reset()
                isResettingSticker = false
            }
        }
    }

    private func saveSticker() async {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        let success = await viewModel.saveToPhotos()
        if !success { return }
        presentToast(
            .init(message: "Image saved!")
        )
    }
    
    
    private var hasImage: Bool {
        viewModel.originalImage != nil
    }

    
    private var previewImage: UIImage? {
        viewModel.subjectImage ?? viewModel.originalImage
    }
}

private struct PillButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .bold))
            .foregroundStyle(.primary)
            .padding(.horizontal, 19)
            .padding(.vertical, 10)
            .background(Color(.tertiarySystemFill), in: Capsule())
            .opacity(configuration.isPressed ? 0.72 : 1)
    }
}
