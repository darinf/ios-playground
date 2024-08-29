import Foundation

func logInterval<T>(_ label: String, action: () -> T) -> T{
    let ts = Date.timeIntervalSinceReferenceDate
    defer {
        let te = Date.timeIntervalSinceReferenceDate
        print(">>> \(label) took: \(te - ts)")
    }
    return action()
}
