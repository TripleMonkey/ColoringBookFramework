//
//  Book+CoreDataProperties.swift
//  SwiftUIColoringBook
//
//  Created by Nigel Krajewski on 2/16/26.
//
//

public import Foundation
public import CoreData


public typealias BookCoreDataPropertiesSet = NSSet

extension Book {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Book> {
        let request = NSFetchRequest<Book>(entityName: "Book")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Book.cdSortOrder, ascending: true)]
        return request
    }
    // Private CoreData attributes
    @NSManaged private var cdDescription: String?
    @NSManaged private var cdSortOrder: Int16
    @NSManaged private var cdPurchaseDate: Date?
    @NSManaged private var cdProductID: String?
    @NSManaged private var cdID: UUID?
    @NSManaged private var cdCoverImageName: String?
    @NSManaged private var cdTitle: String?
    @NSManaged private var cdPages: NSSet?

}

extension Book : Identifiable {

}

// MARK: - Unwrapped Public Attributes
extension Book {

    var ID: UUID {
        set { cdID = newValue }
        get { cdID ?? UUID() }
    }

    var title: String {
        set { cdTitle = newValue }
        get { cdTitle ?? "Untitled" }
    }

    var bookDescription: String {
        set { cdDescription = newValue }
        get { cdDescription ?? "" }
    }

    var coverImageName: String {
        set { cdCoverImageName = newValue }
        get { cdCoverImageName ?? "" }
    }

    var pages: [Page] {
        let set = cdPages as? Set<Page> ?? []
        return set.sorted { $0.number < $1.number }
    }

    var sortOrder: Int16 {
        set { cdSortOrder = newValue }
        get { cdSortOrder }
    }

    var purchaseDate: Date? {
        set { cdPurchaseDate = newValue }
        get { cdPurchaseDate ?? nil }
    }

    var productID: String? {
        set { cdProductID = newValue }
        get { cdProductID ?? nil }
    }
    
    var isUnlocked: Bool {
        cdPurchaseDate != nil
    }

    var assetPrefix: String {
        title.replacingOccurrences(of: " ", with: "")
    }
}

// MARK: - Generated Accessors for Pages
extension Book {

    @objc(addPagesSetObject:)
    @NSManaged public func addToPages(_ value: Page)

    @objc(removePagesSetObject:)
    @NSManaged public func removeFromPages(_ value: Page)

    @objc(addPagesSet:)
    @NSManaged public func addToPages(_ values: NSSet)

    @objc(removePagesSet:)
    @NSManaged public func removeFromPages(_ values: NSSet)
}

