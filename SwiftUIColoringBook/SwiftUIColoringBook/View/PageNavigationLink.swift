//
//  PageNavigationLink.swift
//  SwiftUIColoringBook
//
//  Created by Nigel Krajewski on 2/16/26.
//

import SwiftUI

struct PageNavigationLink: View {
    let page: Page

    init(_ page: Page) {
        self.page = page
    }

    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            Group {
                if let uiImage = UIImage(named: page.imageName) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .overlay {
                            VStack(spacing: 2) {
                                Image(systemName: "photo")
                                Text(page.imageName)
                                    .font(.caption2)
                            }
                            .foregroundStyle(.gray)
                        }
                }
            }
            .frame(width: 80, height: 60)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)

            VStack(alignment: .leading, spacing: 4) {
                Text("Page \(page.number)")
                    .font(.headline)

                if page.hasProgress {
                    Label("In Progress", systemImage: "paintbrush.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }

            Spacer()

            if page.hasProgress {
                Circle()
                    .fill(.green)
                    .frame(width: 10, height: 10)
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}
