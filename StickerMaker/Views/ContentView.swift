//
//  ContentView.swift
//  StickerMaker
//

import SwiftUI
import PhotosUI

struct ContentView: View {
    @StateObject private var viewModel = StickerViewModel()
    @State private var cardAppeared = false
    @State private var imageTransitionID = UUID()

    private var hasImage: Bool {
        viewModel.originalImage != nil
    }

    private var isProcessing: Bool {
        viewModel.state == .removingBackground || viewModel.state == .applyingEffect || viewModel.state == .exporting
    }

    var body: some View {
        ZStack {
            DarkPalette.canvas
                .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    stickerPreviewCard

                    if hasImage {
                        effectPicker
                            .transition(
                                .move(edge: .bottom)
                                .combined(with: .opacity)
                                .combined(with: .scale(scale: 0.96))
                            )
                    }

                    actionButtons

                    if case .error(let message) = viewModel.state {
                        statusView(message)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 14)
                .padding(.bottom, 30)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .alert("Saved", isPresented: $viewModel.showSavedAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your sticker has been saved to your photo library.")
        }
        .sheet(item: $viewModel.shareURL) {
            ShareSheet(activityItems: [$0])
        }
        .onChange(of: viewModel.selectedPhotoItem) { _, newValue in
            Task { await viewModel.handlePhotoSelection(newValue) }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.78), value: viewModel.state)
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.72).delay(0.08)) {
                cardAppeared = true
            }
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(DarkPalette.control)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(DarkPalette.hairline, lineWidth: 1)
                    )

                Image(.stickerFilled)
                    .resizable()
                    .renderingMode(.template)
                    .scaledToFit()
                    .frame(width: 21, height: 21)
                    .foregroundStyle(DarkPalette.primaryText)
            }
            .frame(width: 42, height: 42)

            VStack(alignment: .leading, spacing: 3) {
                Text("Sticker Studio")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(DarkPalette.primaryText)

                Text(headerSubtitle)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(DarkPalette.secondaryText)
            }

            Spacer()

            if hasImage {
                Button(action: startOver) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(DarkPalette.secondaryText)
                        .frame(width: 38, height: 38)
                        .background(DarkPalette.control, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .strokeBorder(DarkPalette.hairline, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Start over")
            }
        }
    }

    private var headerSubtitle: String {
        switch viewModel.state {
        case .idle:
            return "Create cutout stickers"
        case .imageSelected, .removingBackground:
            return "Removing background"
        case .backgroundRemoved, .applyingEffect:
            return "Rendering effect"
        case .effectApplied:
            return "Ready to export"
        case .exporting:
            return "Saving sticker"
        case .error:
            return "Needs attention"
        }
    }

    private var stickerPreviewCard: some View {
        VStack(spacing: 0) {
            previewToolbar

            ZStack {
                CheckerboardView()

                RadialGradient(
                    colors: [
                        Color.white.opacity(0.055),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 20,
                    endRadius: 230
                )

                if let image = viewModel.stickerImage ?? viewModel.subjectImage ?? viewModel.originalImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .padding(34)
                        .id(imageTransitionID)
                        .transition(.scale(scale: 0.88).combined(with: .opacity))
                        .shadow(color: .black.opacity(0.55), radius: 26, y: 18)
                } else {
                    emptyState
                }

                if isProcessing {
                    processingOverlay
                        .transition(.opacity)
                }
            }
            .frame(height: 360)
        }
        .background(DarkPalette.panel)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(DarkPalette.hairline, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.36), radius: 24, y: 16)
        .scaleEffect(cardAppeared ? 1.0 : 0.96)
        .opacity(cardAppeared ? 1 : 0)
        .offset(y: cardAppeared ? 0 : 16)
    }

    private var previewToolbar: some View {
        HStack(spacing: 10) {
            statusDot

            Text(previewTitle)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(DarkPalette.primaryText)

            Spacer()

            Text(viewModel.selectedEffect.displayName)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(DarkPalette.mutedText)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(DarkPalette.control, in: Capsule())
                .overlay(
                    Capsule()
                        .strokeBorder(DarkPalette.hairline, lineWidth: 1)
                )
        }
        .padding(.horizontal, 14)
        .frame(height: 48)
        .background(DarkPalette.panelRaised)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(DarkPalette.hairline)
                .frame(height: 1)
        }
    }

    private var statusDot: some View {
        Circle()
            .fill(isProcessing ? Color(red: 0.84, green: 0.84, blue: 0.86) : Color(red: 0.32, green: 0.32, blue: 0.35))
            .frame(width: 8, height: 8)
            .shadow(color: isProcessing ? .white.opacity(0.2) : .clear, radius: 8)
    }

    private var previewTitle: String {
        hasImage ? "Preview" : "New sticker"
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(DarkPalette.control)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(DarkPalette.hairline, lineWidth: 1)
                    )

                Image(.stickerAddFilled)
                    .resizable()
                    .renderingMode(.template)
                    .scaledToFit()
                    .frame(width: 38, height: 38)
                    .foregroundStyle(DarkPalette.primaryText)
            }
            .frame(width: 82, height: 82)

            VStack(spacing: 6) {
                Text("Select an image")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(DarkPalette.primaryText)

                Text("Portrait, object, sketch, or screenshot.")
                    .font(.system(size: 13, weight: .medium))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(DarkPalette.secondaryText)
                    .frame(maxWidth: 250)
            }
        }
        .padding(.horizontal, 24)
    }

    private var processingOverlay: some View {
        ZStack {
            Color.black.opacity(0.42)

            VStack(spacing: 12) {
                ProgressView()
                    .tint(DarkPalette.primaryText)
                    .controlSize(.large)

                Text(headerSubtitle)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(DarkPalette.primaryText)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(DarkPalette.control, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(DarkPalette.hairline, lineWidth: 1)
            )
        }
    }

    private var effectPicker: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Effects", systemImage: "camera.filters")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(DarkPalette.primaryText)

                Spacer()

                Text("\(StickerEffectType.allCases.count) styles")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(DarkPalette.mutedText)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(StickerEffectType.allCases) { effect in
                        EffectButton(
                            effect: effect,
                            isSelected: viewModel.selectedEffect == effect
                        ) {
                            Task { await viewModel.changeEffect(effect) }
                        }
                    }
                }
                .padding(.horizontal, 1)
                .padding(.bottom, 2)
            }
        }
        .padding(14)
        .background(DarkPalette.panel, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(DarkPalette.hairline, lineWidth: 1)
        )
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            if viewModel.state == .idle || viewModel.originalImage == nil {
                PhotosPicker(selection: $viewModel.selectedPhotoItem, matching: .images) {
                    GlassButton(
                        title: "Select Image",
                        icon: "photo.badge.plus",
                        style: .primary
                    )
                }
                .buttonStyle(.plain)
            }

            if viewModel.state == .effectApplied {
                HStack(spacing: 12) {
                    Button(action: viewModel.shareSticker) {
                        GlassButton(
                            title: "Share",
                            icon: "square.and.arrow.up",
                            style: .glass
                        )
                    }

                    Button {
                        Task { await viewModel.saveToPhotos() }
                    } label: {
                        GlassButton(
                            title: "Save",
                            icon: "square.and.arrow.down",
                            style: .primary
                        )
                    }
                }

                PhotosPicker(selection: $viewModel.selectedPhotoItem, matching: .images) {
                    GlassButton(
                        title: "Choose Another",
                        icon: "photo.on.rectangle",
                        style: .subtle
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func statusView(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color(red: 0.92, green: 0.70, blue: 0.38))
                .symbolEffect(.bounce, value: message)

            Text(message)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(DarkPalette.secondaryText)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(DarkPalette.panelRaised, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color(red: 0.92, green: 0.70, blue: 0.38).opacity(0.25), lineWidth: 1)
        )
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private func startOver() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.76)) {
            viewModel.reset()
            cardAppeared = false
            imageTransitionID = UUID()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.74)) {
                cardAppeared = true
            }
        }
    }
}

private enum DarkPalette {
    static let canvas = Color(red: 0.035, green: 0.035, blue: 0.04)
    static let panel = Color(red: 0.075, green: 0.075, blue: 0.082)
    static let panelRaised = Color(red: 0.095, green: 0.095, blue: 0.105)
    static let control = Color(red: 0.13, green: 0.13, blue: 0.145)
    static let hairline = Color.white.opacity(0.075)
    static let primaryText = Color(red: 0.92, green: 0.92, blue: 0.94)
    static let secondaryText = Color(red: 0.60, green: 0.60, blue: 0.64)
    static let mutedText = Color(red: 0.42, green: 0.42, blue: 0.46)
}
