import Foundation

func logInterval<T>(_ label: String, action: () -> T) -> T{
    let ts = Date.timeIntervalSinceReferenceDate
    defer {
        let te = Date.timeIntervalSinceReferenceDate
        print(">>> \(label): \(String(format: "%.2f", (te - ts) * 1000)) msec")
    }
    return action()
}
