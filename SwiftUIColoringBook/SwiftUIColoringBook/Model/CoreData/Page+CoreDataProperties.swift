//
//  Page+CoreDataProperties.swift
//  SwiftUIColoringBook
//
//  Created by Nigel Krajewski on 2/16/26.
//
//

public import Foundation
public import CoreData
import PencilKit

public typealias PageCoreDataPropertiesSet = NSSet

extension Page {
    // Fetch Request
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Page> {
        let request = NSFetchRequest<Page>(entityName: "Page")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Page.number, ascending: true)]
        return request
    }

    // Private optional CoreData attributes
    @NSManaged private var cdPageNumber: Int16
    @NSManaged private var cdLastModified: Date?
    @NSManaged private var cdID: UUID?
    @NSManaged private var cdDrawingData: Data?
    @NSManaged private var cdBook: Book?

}

extension Page : Identifiable {

}

// MARK: - Unwrapped Public Attributes
extension Page {

    var ID: UUID {
        set { cdID = newValue }
        get { cdID ?? UUID() }
    }

    var number: Int16 {
        set { cdPageNumber = Int16(newValue) }
        get { Int16(cdPageNumber) }
    }

    var book: Book? {
        set { cdBook = newValue }
        get { cdBook ?? Book()}
    }

    var imageName: String {
        guard let cdBook = cdBook else {
            return "page_\(cdPageNumber)"
        }
        return "\(cdBook.assetPrefix)_\(cdPageNumber)"
    }

    var drawing: PKDrawing {
        get {
            guard let data = cdDrawingData else { return PKDrawing() }
            return (try? PKDrawing(data: data)) ?? PKDrawing()
        }
        set {
            cdDrawingData = newValue.dataRepresentation()
            cdLastModified = Date()
        }
    }

    var hasProgress: Bool {
        guard let data = cdDrawingData,
              let drawing = try? PKDrawing(data: data) else {
            return false
        }
        return !drawing.strokes.isEmpty
    }

    func clearProgress() {
        cdDrawingData = nil
        cdLastModified = nil
    }
}
