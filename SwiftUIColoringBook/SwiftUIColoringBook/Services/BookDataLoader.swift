//
//  BookDataLoader.swift
//  SwiftUIColoringBook
//
//  Created by Nigel Krajewski on 2/16/26.
//

import Foundation
import CoreData

struct BookDataLoader {

    static func loadDefaultBooks(into context: NSManagedObjectContext) {

        createBook(
            in: context,
            title: "Shapes",
            description: "Some basic shapes to test your drawing skills!",
            coverImage: "Shapes_cover",
            productID: nil,
            purchaseDate: Date(),
            sortOrder: 0,
            pageCount: 5
        )
    }

    private static func createBook(
        in context: NSManagedObjectContext,
        title: String,
        description: String,
        coverImage: String,
        productID: String?,
        purchaseDate: Date?,
        sortOrder: Int,
        pageCount: Int
    ) {
        let book = Book(context: context)
        book.ID = UUID()
        book.title = title
        book.bookDescription = description
        book.coverImageName = coverImage
        book.productID = productID
        book.purchaseDate = purchaseDate
        book.sortOrder = Int16(sortOrder)

        for i in 1...pageCount {
            let page = Page(context: context)
            page.ID = UUID()
            page.number = Int16(i)
            page.book = book
        }

        print("✅ Created book: \(title) with \(pageCount) pages")
    }
}

