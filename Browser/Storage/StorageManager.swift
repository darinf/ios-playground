// Copyright 2022 Darin Fisher. All rights reserved.

import CoreData
import Foundation

class StorageManager {
    let container: NSPersistentContainer

    init() {
        container = .init(name: "StorageModel")
    }
}
