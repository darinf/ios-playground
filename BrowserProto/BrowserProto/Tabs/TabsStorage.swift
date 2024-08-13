import Foundation

final class TabsStorage {
    private enum Metrics {
        static let delay: TimeInterval = 0.5
    }

    private struct Update {
        let data: TabsData
        let change: TabsModel.TabsChange
        let section: TabsSection
    }

    private let queue = DispatchQueue(label: "TabsStorage", qos: .background)

    private var pendingUpdates: [Update] = []
    private let pendingUpdatesLock = NSRecursiveLock()

    private var tabsFileURL: URL {
        .documentsDirectory.appending(path: "tabs.json")
    }

    init() {
    }

    func loadTabsData(completion: @escaping (TabsData?) -> Void) {
        queue.async { [self] in
            let result: TabsData?
            if let data = readTabsFile() {
                result = decode(data: data)
            } else {
                result = nil
            }
            DispatchQueue.main.async { completion(result) }
        }
    }

    func persistTabsChange(_ change: TabsModel.TabsChange, in section: TabsSection, for data: TabsData, immediately: Bool = false) {
        pendingUpdatesLock.lock()
        defer { pendingUpdatesLock.unlock() }

        pendingUpdates.append(.init(data: data, change: change, section: section))

        if immediately {
            queue.sync { [self] in
                processPendingUpdates(updates: popPendingUpdates())
            }
        } else if pendingUpdates.count == 1 {
            // Throttle how often we do work.
            queue.asyncAfter(deadline: .now() + Metrics.delay) { [self] in
                processPendingUpdates(updates: popPendingUpdates())
            }
        }
    }

    // Everything below happens only on the TabsStorage thread:

    private func popPendingUpdates() -> [Update] {
        pendingUpdatesLock.lock()
        defer { pendingUpdatesLock.unlock() }

        let updates = pendingUpdates
        pendingUpdates = []

        return updates
    }

    private func processPendingUpdates(updates: [Update]) {
        print(">>> processPendingUpdates")

        guard let mostRecentUpdate = updates.last else { return }

        guard let data = encode(data: mostRecentUpdate.data) else { return }
        do {
            try data.write(to: tabsFileURL, options: [.atomic])
        } catch {
            print(">>> error writing tabs data: \(error)")
        }
    }

    private func readTabsFile() -> Data? {
        do {
            return try Data(contentsOf: tabsFileURL)
        } catch {
            print(">>> error reading tabs data")
            return nil
        }
    }

    private func encode(data: TabsData) -> Data? {
        let jsonEncoder = JSONEncoder()
        do {
            return try jsonEncoder.encode(data)
        } catch {
            print(">>> error encoding tabs data: \(error)")
            return nil
        }
    }

    private func decode(data: Data) -> TabsData? {
        let jsonDecoder = JSONDecoder()
        do {
            return try jsonDecoder.decode(TabsData.self, from: data)
        } catch {
            print(">>> error decoding tabs data: \(error)")
            return nil
        }
    }
}

extension Favicon: Codable {
    struct DecodingError: Error {}

    func encode(to encoder: any Encoder) throws {
    }
    
    init(from decoder: any Decoder) throws {
        throw DecodingError()
    }
}

extension Thumbnail: Codable {
    struct DecodingError: Error {}

    func encode(to encoder: any Encoder) throws {
    }
    
    init(from decoder: any Decoder) throws {
        throw DecodingError()
    }
}
