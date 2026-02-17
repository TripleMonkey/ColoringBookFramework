//
//  CanvasView.swift
//  SwiftUIColoringBook
//
//  Created by Nigel Krajewski on 2/16/26.
//

import SwiftUI
import PencilKit

struct CanvasView: View {
    @ObservedObject var page: Page

    @EnvironmentObject var library: LibraryViewModel

    @State private var drawing: PKDrawing
    @State private var currentTool: PKTool = PKInkingTool(.pencil, color: .red, width: 10)
    @State private var selectedToolType: ToolType = .pencil
    @State private var selectedColor: Color = .red
    @State private var brushSize: CGFloat = 10
    @State private var canvasSize: CGSize = .zero

    @State private var showingClearAlert = false
    @State private var showingShareSheet = false
    @State private var exportedImage: UIImage?

    init(page: Page) {
        self.page = page
        _drawing = State(initialValue: page.drawing)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Canvas
            if UIImage(named: page.imageName) != nil {
                CanvasRepresentable(
                    imageName: page.imageName,
                    drawing: $drawing,
                    tool: $currentTool,
                    canvasSize: $canvasSize,
                    onDrawingChanged: saveDrawing
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ContentUnavailableView(
                    "Image Not Found",
                    systemImage: "photo.badge.exclamationmark",
                    description: Text("'\(page.imageName)' not found in assets")
                )
            }

            // Toolbar
            ToolBarView(
                selectedToolType: $selectedToolType,
                selectedColor: $selectedColor,
                brushSize: $brushSize,
                onToolChanged: updateTool
            )
        }
        .navigationTitle("Page \(page.number)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button { shareImage() } label: {
                    Image(systemName: "square.and.arrow.up")
                }

                Menu {
                    Button { undoStroke() } label: {
                        Label("Undo", systemImage: "arrow.uturn.backward")
                    }
                    Button(role: .destructive) { showingClearAlert = true } label: {
                        Label("Clear All", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .alert("Clear Drawing?", isPresented: $showingClearAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) { clearDrawing() }
        } message: {
            Text("This will remove all your coloring. This cannot be undone.")
        }
        .sheet(isPresented: $showingShareSheet) {
            if let image = exportedImage {
                ShareSheet(items: [image])
            }
        }
        .onAppear {
            updateTool()
        }
    }

    // MARK: - Actions

    private func updateTool() {
        let uiColor = UIColor(selectedColor)

        switch selectedToolType {
        case .pencil:
            currentTool = PKInkingTool(.pencil, color: uiColor, width: brushSize)
        case .marker:
            currentTool = PKInkingTool(.marker, color: uiColor.withAlphaComponent(0.7), width: brushSize * 2)
        case .crayon:
            currentTool = PKInkingTool(.crayon, color: uiColor, width: brushSize * 1.5)
        case .eraser:
            currentTool = PKEraserTool(.bitmap, width: brushSize * 2)
        }
    }

    private func saveDrawing(_ newDrawing: PKDrawing) {
        library.saveDrawing(newDrawing, for: page)
    }

    private func clearDrawing() {
        drawing = PKDrawing()
        library.clearPage(page)
    }

    private func undoStroke() {
        var strokes = drawing.strokes
        guard !strokes.isEmpty else { return }
        strokes.removeLast()
        drawing = PKDrawing(strokes: strokes)
        saveDrawing(drawing)
    }

    private func shareImage() {
        guard let baseImage = UIImage(named: page.imageName) else { return }
        guard canvasSize.width > 0, canvasSize.height > 0 else { return }

        let imageSize = baseImage.size
        let imageAspect = imageSize.width / imageSize.height
        let canvasAspect = canvasSize.width / canvasSize.height

        var displayedRect: CGRect

        if imageAspect > canvasAspect {
            let displayedWidth = canvasSize.width
            let displayedHeight = displayedWidth / imageAspect
            let yOffset = (canvasSize.height - displayedHeight) / 2
            displayedRect = CGRect(x: 0, y: yOffset, width: displayedWidth, height: displayedHeight)
        } else {
            let displayedHeight = canvasSize.height
            let displayedWidth = displayedHeight * imageAspect
            let xOffset = (canvasSize.width - displayedWidth) / 2
            displayedRect = CGRect(x: xOffset, y: 0, width: displayedWidth, height: displayedHeight)
        }

        let scaleX = imageSize.width / displayedRect.width
        let scaleY = imageSize.height / displayedRect.height
        let scale = min(scaleX, scaleY)

        let renderer = UIGraphicsImageRenderer(size: imageSize)
        let fullRect = CGRect(origin: .zero, size: imageSize)

        let composited = renderer.image { context in
            let cgContext = context.cgContext

            // Layer 1: White background
            UIColor.white.setFill()
            cgContext.fill(fullRect)

            // Layer 2: User's drawing
            let drawingImage = drawing.image(from: displayedRect, scale: scale)
            drawingImage.draw(in: fullRect)

            // Layer 3: Coloring page lines on top with multiply blend
            cgContext.setBlendMode(.multiply)
            baseImage.draw(in: fullRect)

            // Reset blend mode
            cgContext.setBlendMode(.normal)
        }

        if let jpegData = composited.jpegData(compressionQuality: 0.95),
           let jpegImage = UIImage(data: jpegData) {
            exportedImage = jpegImage
        } else {
            exportedImage = composited
        }

        showingShareSheet = true
    }
}

// MARK: - Tool Type
enum ToolType: String, CaseIterable, Identifiable {
    case pencil, marker, crayon, eraser

    var id: String { rawValue }
    var name: String { rawValue.capitalized }

    var icon: String {
        switch self {
        case .pencil: return "pencil"
        case .marker: return "highlighter"
        case .crayon: return "paintbrush.pointed.fill"
        case .eraser: return "eraser.fill"
        }
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

