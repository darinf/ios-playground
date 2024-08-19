/// Holds a weak reference to an object.
final class WeakBox<T: AnyObject> {
    weak var object: T?

    init(_ object: T) {
        self.object = object
    }
}
