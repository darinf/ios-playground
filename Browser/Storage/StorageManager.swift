// Copyright 2022 Darin Fisher. All rights reserved.

import CoreData
import Foundation

class StorageManager {
    let container: NSPersistentContainer

    var storedCards: [StoredCard] = []

    init() {
        container = .init(name: "StorageModel")
    }

    func fetch() {
        let managedContext = container.viewContext

        let fetchRequest = NSFetchRequest<StoredCard>(entityName: "StoredCard")

        do {
            storedCards = try managedContext.fetch(fetchRequest)
        } catch let error as NSError {
            print(">>> Fetch failed: \(error.localizedDescription)")
        }
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
