//
//  SwiftUIColoringBookApp.swift
//  SwiftUIColoringBook
//
//  Created by Nigel Krajewski on 2/16/26.
//

import SwiftUI
import CoreData

@main
struct SwiftUIColoringBookApp: App {

    let persistence = PersistenceController.shared
    @StateObject private var library: LibraryViewModel
    @StateObject private var storeManager = StoreManager()
    @Environment(\.scenePhase) private var scenePhase

    init() {
        let context = PersistenceController.shared.viewContext
        _library = StateObject(wrappedValue: LibraryViewModel(context: context))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistence.viewContext)
                .environmentObject(library)
                .environmentObject(storeManager)
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .background, .inactive:
                // Save immediately when leaving app
                PersistenceController.shared.saveImmediately()
                print("💾 Saved on app background/inactive")
            default:
                break
            }
        }
    }
}
