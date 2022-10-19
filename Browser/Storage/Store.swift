// Copyright 2022 Darin Fisher. All rights reserved.

import CoreData
import Foundation

class Store {
    let container: NSPersistentContainer

    init() {
        container = .init(name: "StorageModel")
        container.loadPersistentStores() { description, error in
            if let error = error {
                print(">>> Error loading StorageModel: \(error.localizedDescription)")
            }
        }
    }

    func fetchStoredCards() -> [StoredCard] {
        let managedContext = container.viewContext

        let fetchRequest = NSFetchRequest<StoredCard>(entityName: "StoredCard")

        var storedCards: [StoredCard]
        do {
            storedCards = try managedContext.fetch(fetchRequest)
        } catch let error as NSError {
            print(">>> Fetch failed: \(error.localizedDescription)")
            storedCards = []
        }
        return storedCards
    }

    func save() {
        let managedContext = container.viewContext
        do {
            try managedContext.save()
        } catch let error as NSError {
            print(">>> Save failed: \(error.localizedDescription)")
        }
    }
}

extension StoredCard {
    convenience init(store: Store) {
        self.init(context: store.container.viewContext)
    }
}
