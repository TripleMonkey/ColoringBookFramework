//
//  LibraryViewModel.swift
//  SwiftUIColoringBook
//
//  Created by Nigel Krajewski on 2/16/26.
//

import Foundation
import CoreData
import PencilKit
import Combine

class LibraryViewModel: ObservableObject {

    @Published var allBooks: [Book] = []
    @Published var currentBook: Book? = nil

    private let viewContext: NSManagedObjectContext
    private var cancellables = Set<AnyCancellable>()

    init(context: NSManagedObjectContext = PersistenceController.shared.viewContext) {
        self.viewContext = context

        fetchBooks()
        preloadBooksIfNeeded()
        listenForChanges()
    }

    // MARK: - Fetch

    func fetchBooks() {
        let request = Book.fetchRequest()

        do {
            allBooks = try viewContext.fetch(request)
            print("📚 Fetched \(allBooks.count) books")
        } catch {
            print("❌ Failed to fetch books: \(error)")
        }
    }

    // MARK: - Preload

    private func preloadBooksIfNeeded() {
        guard allBooks.isEmpty else { return }

        print("📚 Preloading default books...")
        BookDataLoader.loadDefaultBooks(into: viewContext)
        PersistenceController.shared.saveImmediately()
        fetchBooks()
    }

    // MARK: - Listen for Changes

    private func listenForChanges() {
        NotificationCenter.default.publisher(for: .NSPersistentStoreRemoteChange)
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.fetchBooks()
            }
            .store(in: &cancellables)
    }

    // MARK: - Drawing Management

    func saveDrawing(_ drawing: PKDrawing, for page: Page) {
        // Update the page on the context's queue
        viewContext.perform { [weak self] in
            page.drawing = drawing
            self?.save()
        }
    }

    func clearPage(_ page: Page) {
        viewContext.perform { [weak self] in
            page.clearProgress()
            self?.save()
        }
    }

    // MARK: - Save

    func save() {
        PersistenceController.shared.save()
    }
}

