//
//  ContentView.swift
//  SwiftUIColoringBook
//
//  Created by Nigel Krajewski on 2/16/26.
//

import PencilKit
import SwiftUI

struct ContentView: View {

    @EnvironmentObject var library: LibraryViewModel

    @State var visibility: NavigationSplitViewVisibility = .all
    @State var selectedPage: Page? = nil

    var body: some View {
        // Main Menu - Book list
        NavigationSplitView(columnVisibility: $visibility) {
            List(library.allBooks, selection: $library.currentBook) { book in
                NavigationLink(book.title, value: book)
                    .disabled(book.purchaseDate == nil)
            }
            .navigationSplitViewColumnWidth(CGFloat(200))
            .navigationTitle("Books")
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: library.currentBook) { _, _ in
                selectedPage = nil
                manageColumns()
            }
        }
        // Submenu - Pages list
        content: {
            if let selectedBook = library.currentBook, selectedBook.purchaseDate != nil {
                List(selection: $selectedPage) {
                    ForEach(selectedBook.pages, id: \.self) { page in
                        PageNavigationLink(page)
                            .tag(page)
                            .onTapGesture {
                                selectedPage = page
                            }
                    }
                }
                .navigationTitle(selectedBook.title)
                .onChange(of: selectedPage) {
                    manageColumns()
                }
            } else if library.currentBook != nil {
                Text("Purchase Required")
                    .navigationTitle(library.currentBook?.title ?? "")
            }
        }
        // Detail view - Coloring page
        detail: {
            if let thisPage = selectedPage,
               let _ = thisPage.book?.purchaseDate {
                CanvasView(page: thisPage)
                    .onAppear {
                        manageColumns()
                    }
            } else if library.currentBook?.purchaseDate == nil {
                Text("Purchase Required")
            }
        }
        .navigationSplitViewStyle(.balanced)
    }

    func manageColumns() {
        if library.currentBook != nil && selectedPage != nil {
            visibility = .detailOnly
        } else if library.currentBook != nil && library.currentBook?.purchaseDate != nil {
            visibility = .doubleColumn
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(
            LibraryViewModel(context: PersistenceController.preview.viewContext)
        )
}
