// Copyright 2022 Darin Fisher. All rights reserved.

import Foundation

enum PrefStringKey: String {
    case TBD
}

enum PrefUUIDKey: String {
    case selectedCardId
}

enum Prefs {
    static subscript(key: PrefStringKey) -> String? {
        get {
            UserDefaults.standard.string(forKey: key.rawValue)
        }
        set(newValue) {
            UserDefaults.standard.set(newValue, forKey: key.rawValue)
        }
    }

    static subscript(key: PrefUUIDKey) -> UUID? {
        get {
            guard let value = UserDefaults.standard.string(forKey: key.rawValue) else {
                return nil
            }
            return UUID(uuidString: value)
        }
        set(newValue) {
            UserDefaults.standard.set(newValue?.uuidString, forKey: key.rawValue)
        }
    }

}
