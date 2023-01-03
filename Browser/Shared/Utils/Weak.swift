// Copyright 2023 Darin Fisher. All rights reserved.

import Foundation

struct Weak<Value> {
    // Rather than constrain `Value` to `AnyObject`, we store the value privately as `AnyObject`.
    // This allows us to hold weak references to class-constrained protocol types,
    // which as types do not themselves conform to `AnyObject`.
    private weak var _value: AnyObject?

    var value: Value? {
        return _value as? Value
    }

    init(_ value: Value) {
        // All Swift values are implicitly convertible to `AnyObject`,
        // so this runtime check is the tradeoff for supporting class-constrained protocol types.
        precondition(Mirror(reflecting: value).displayStyle == .class, "Weak references can only be held of class types.")
        _value = value as AnyObject
    }
}
