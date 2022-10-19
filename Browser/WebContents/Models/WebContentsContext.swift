// Copyright 2022 Darin Fisher. All rights reserved.

import Foundation

class WebContentsContext {
    let storageManager: StorageManager

    init(storageManager: StorageManager) {
        self.storageManager = storageManager
    }
}
