//
//  Persistence.swift
//  SwiftUIColoringBook
//
//  Created by Nigel Krajewski on 2/16/26.
//

import CoreData
import CloudKit
import Combine

class PersistenceController {

    static let shared = PersistenceController()

    let container: NSPersistentCloudKitContainer

    var viewContext: NSManagedObjectContext {
        container.viewContext
    }

    // Debounce saves
    private var saveSubject = PassthroughSubject<Void, Never>()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Book for Preview Support

    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let context = controller.viewContext

        let book = Book(context: context)
        book.ID = UUID()
        book.title = "Shapes"
        book.bookDescription = "A preview book"
        book.coverImageName = "Shapes_cover"
        book.sortOrder = 1
        book.purchaseDate = Date()

        for i in 1...5 {
            let page = Page(context: context)
            page.ID = UUID()
            page.number = Int16(i)
            page.book = book
        }

        try? context.save()
        return controller
    }()

    // MARK: - Initialization

    init(inMemory: Bool = false) {
        // This must match the core data file name (excluding .xcdatamodeld) 
        let modelName = "SwiftUIColoringBook"

        guard let modelURL = Bundle.main.url(forResource: modelName, withExtension: "momd"),
              let model = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("❌ Could not find CoreData model '\(modelName)'")
        }

        container = NSPersistentCloudKitContainer(name: modelName, managedObjectModel: model)

        guard let description = container.persistentStoreDescriptions.first else {
            let storeURL = Self.defaultStoreURL(for: modelName)
            let description = NSPersistentStoreDescription(url: storeURL)
            container.persistentStoreDescriptions = [description]
            configureAndLoad(description: description, inMemory: inMemory)
            setupDebouncedSave()
            return
        }

        configureAndLoad(description: description, inMemory: inMemory)
        setupDebouncedSave()
    }

    // MARK: - Debounced Save

    private func setupDebouncedSave() {
        saveSubject
            .debounce(for: .seconds(1.0), scheduler: DispatchQueue.main)
            .sink { [weak self] in
                self?.performSave()
            }
            .store(in: &cancellables)
    }

    /// Debounced save - safe to call frequently (e.g., every stroke)
    func save() {
        saveSubject.send()
    }

    /// Immediate save - use for critical saves (e.g., before app goes to background)
    func saveImmediately() {
        performSave()
    }

    private func performSave() {
        let context = viewContext

        // Must save on the context's queue
        context.perform {
            guard context.hasChanges else { return }

            do {
                try context.save()
                print("💾 Saved successfully")
            } catch {
                print("❌ Save failed: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Configuration

    private func configureAndLoad(description: NSPersistentStoreDescription, inMemory: Bool) {

        if inMemory {
            description.url = URL(fileURLWithPath: "/dev/null")
        }

        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

        if !inMemory {
            description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
                containerIdentifier: "iCloud.com.yourcompany.DuchessKittyColoring"
            )
        }

        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                print("❌ Core Data failed to load: \(error), \(error.userInfo)")
            } else {
                print("✅ Core Data loaded successfully")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRemoteChange),
            name: .NSPersistentStoreRemoteChange,
            object: container.persistentStoreCoordinator
        )
    }

    @objc private func handleRemoteChange(_ notification: Notification) {
        print("☁️ Remote change received")
    }

    // MARK: - Helpers

    private static func defaultStoreURL(for modelName: String) -> URL {
        let urls = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let appSupport = urls[0]
        try? FileManager.default.createDirectory(at: appSupport, withIntermediateDirectories: true)
        return appSupport.appendingPathComponent("\(modelName).sqlite")
    }
}
