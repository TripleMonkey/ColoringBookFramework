//
//  CanvasRepresentable.swift
//  SwiftUIColoringBook
//
//  Created by Nigel Krajewski on 2/16/26.
//

import SwiftUI
import PencilKit

struct CanvasRepresentable: UIViewRepresentable {
    let imageName: String
    @Binding var drawing: PKDrawing
    @Binding var tool: PKTool
    @Binding var canvasSize: CGSize
    let onDrawingChanged: (PKDrawing) -> Void

    func makeUIView(context: Context) -> ZoomableCanvasView {
        let view = ZoomableCanvasView()
        view.canvasDelegate = context.coordinator
        view.setImage(UIImage(named: imageName))
        view.drawing = drawing
        view.canvasTool = tool
        return view
    }

    func updateUIView(_ uiView: ZoomableCanvasView, context: Context) {
        uiView.canvasTool = tool

        if uiView.bounds.size != .zero {
            DispatchQueue.main.async {
                canvasSize = uiView.bounds.size
            }
        }

        if uiView.drawing.strokes.count != drawing.strokes.count {
            uiView.drawing = drawing
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, CanvasContainerDelegate {
        let parent: CanvasRepresentable

        init(_ parent: CanvasRepresentable) {
            self.parent = parent
        }

        func drawingDidChange(_ drawing: PKDrawing) {
            parent.drawing = drawing
            parent.onDrawingChanged(drawing)
        }

        func canvasSizeDidChange(_ size: CGSize) {
            parent.canvasSize = size
        }
    }
}

// MARK: - Delegate Protocol
protocol CanvasContainerDelegate: AnyObject {
    func drawingDidChange(_ drawing: PKDrawing)
    func canvasSizeDidChange(_ size: CGSize)
}

// MARK: - Multiply Blend Image View
/// UIImageView that uses Multiply blend mode
/// White areas become transparent, black lines show on top
class MultiplyImageView: UIImageView {

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    override init(image: UIImage?) {
        super.init(image: image)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        // Multiply blend: white becomes transparent, dark colors stay
        layer.compositingFilter = "multiplyBlendMode"
        backgroundColor = .clear
        isUserInteractionEnabled = false
    }
}

// MARK: - Zoomable Canvas View
class ZoomableCanvasView: UIView {

    weak var canvasDelegate: CanvasContainerDelegate?

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    // Layer order (bottom to top):
    // 1. White background
    // 2. PencilKit canvas (user drawing)
    // 3. Coloring page image with multiply blend (lines on top)
    private let backgroundView = UIView()
    private let canvasView = PKCanvasView()
    private let lineOverlayView = MultiplyImageView(frame: .zero)

    private var imageSize: CGSize = .zero

    var drawing: PKDrawing {
        get { canvasView.drawing }
        set { canvasView.drawing = newValue }
    }

    var canvasTool: PKTool {
        get { canvasView.tool }
        set { canvasView.tool = newValue }
    }

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        backgroundColor = .systemGray6

        // Scroll view for zoom/pan
        scrollView.delegate = self
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 5.0
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.bouncesZoom = true
        scrollView.bounces = true
        addSubview(scrollView)

        // Require two fingers for panning
        scrollView.panGestureRecognizer.minimumNumberOfTouches = 2

        // Content view
        scrollView.addSubview(contentView)

        // Layer 1: White background
        backgroundView.backgroundColor = .white
        backgroundView.isUserInteractionEnabled = false
        contentView.addSubview(backgroundView)

        // Layer 2: PencilKit canvas (drawing goes here)
        canvasView.backgroundColor = .clear
        canvasView.isOpaque = false
        canvasView.drawingPolicy = .anyInput
        canvasView.delegate = self
        contentView.addSubview(canvasView)

        // Layer 3: Coloring page lines on top (multiply blend)
        lineOverlayView.contentMode = .scaleAspectFit
        lineOverlayView.isUserInteractionEnabled = false
        contentView.addSubview(lineOverlayView)

        // Configure gestures
        configureGestures()

        // Double tap to reset zoom
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        doubleTap.numberOfTouchesRequired = 1
        addGestureRecognizer(doubleTap)
    }

    // MARK: - Gesture Configuration

    private func configureGestures() {
        for gesture in canvasView.gestureRecognizers ?? [] {
            if let panGesture = gesture as? UIPanGestureRecognizer {
                panGesture.maximumNumberOfTouches = 1
            }
        }
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()

        scrollView.frame = bounds

        let contentSize = bounds.size
        contentView.frame = CGRect(origin: .zero, size: contentSize)
        backgroundView.frame = contentView.bounds
        canvasView.frame = contentView.bounds
        lineOverlayView.frame = contentView.bounds

        scrollView.contentSize = contentSize
        centerContent()

        canvasDelegate?.canvasSizeDidChange(bounds.size)
    }

    // MARK: - Image

    func setImage(_ image: UIImage?) {
        lineOverlayView.image = image
        imageSize = image?.size ?? .zero
    }

    // MARK: - Zoom

    @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        if scrollView.zoomScale > scrollView.minimumZoomScale {
            scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
        } else {
            let location = gesture.location(in: contentView)
            let zoomScale: CGFloat = 3.0
            let width = scrollView.bounds.width / zoomScale
            let height = scrollView.bounds.height / zoomScale
            let rect = CGRect(
                x: location.x - width / 2,
                y: location.y - height / 2,
                width: width,
                height: height
            )
            scrollView.zoom(to: rect, animated: true)
        }
    }

    private func centerContent() {
        let scrollSize = scrollView.bounds.size
        let contentSize = scrollView.contentSize

        let hInset = max(0, (scrollSize.width - contentSize.width * scrollView.zoomScale) / 2)
        let vInset = max(0, (scrollSize.height - contentSize.height * scrollView.zoomScale) / 2)

        scrollView.contentInset = UIEdgeInsets(
            top: vInset,
            left: hInset,
            bottom: vInset,
            right: hInset
        )
    }
}

// MARK: - UIScrollViewDelegate
extension ZoomableCanvasView: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        contentView
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        centerContent()
    }
}

// MARK: - PKCanvasViewDelegate
extension ZoomableCanvasView: PKCanvasViewDelegate {
    func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
        canvasDelegate?.drawingDidChange(canvasView.drawing)
    }
}
