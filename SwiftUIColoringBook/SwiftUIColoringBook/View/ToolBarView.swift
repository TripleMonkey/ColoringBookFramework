//
//  ToolBarView.swift
//  SwiftUIColoringBook
//
//  Created by Nigel Krajewski on 2/16/26.
//

import SwiftUI

struct ToolBarView: View {
    @Binding var selectedToolType: ToolType
    @Binding var selectedColor: Color
    @Binding var brushSize: CGFloat
    let onToolChanged: () -> Void

    private let colors: [Color] = [
        .red, .orange, .yellow, .green, .mint,
        .cyan, .blue, .indigo, .purple, .pink,
        .brown, .black, .gray, .white
    ]

    var body: some View {
        VStack(spacing: 12) {
            // Tools row
            HStack(spacing: 12) {
                ForEach(ToolType.allCases) { tool in
                    Button {
                        selectedToolType = tool
                        onToolChanged()
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: tool.icon)
                                .font(.title2)
                                .frame(width: 44, height: 44)
                                .background(selectedToolType == tool ? Color.accentColor : Color.clear)
                                .foregroundStyle(
                                    selectedToolType == tool ? .white :
                                        (tool == .eraser ? .primary : selectedColor)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 10))

                            Text(tool.name)
                                .font(.caption2)
                                .foregroundStyle(selectedToolType == tool ? .primary : .secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }

                Divider()
                    .frame(height: 30)

                // Brush size
                if selectedToolType != .eraser {
                    HStack(spacing: 6) {
                        Circle()
                            .frame(width: 6, height: 6)
                            .foregroundStyle(.secondary)

                        Slider(value: $brushSize, in: 3...30)
                            .frame(width: 80)
                            .onChange(of: brushSize) { _, _ in
                                onToolChanged()
                            }

                        Circle()
                            .frame(width: 14, height: 14)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal)

            // Zoom hint
            Text("Pinch to zoom • Two-finger drag to pan • Double-tap to reset")
                .font(.caption2)
                .foregroundStyle(.secondary)

            // Color palette
            if selectedToolType != .eraser {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(colors, id: \.self) { color in
                            Button {
                                selectedColor = color
                                onToolChanged()
                            } label: {
                                Circle()
                                    .fill(color)
                                    .frame(width: 36, height: 36)
                                    .overlay {
                                        Circle()
                                            .strokeBorder(.white, lineWidth: selectedColor == color ? 3 : 0)
                                    }
                                    .overlay {
                                        Circle()
                                            .strokeBorder(.black.opacity(0.2), lineWidth: 1)
                                    }
                                    .scaleEffect(selectedColor == color ? 1.15 : 1)
                                    .animation(.easeInOut(duration: 0.15), value: selectedColor == color)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }
}
