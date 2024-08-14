import Foundation
import SDWebImage

final class TabsStorage {
    static let faviconStoreUserInfoKey = CodingUserInfoKey(rawValue: "FaviconStoreUserInfoKey")!
    static let thumbnailStoreUserInfoKey = CodingUserInfoKey(rawValue: "ThumbnailStoreUserInfoKey")!

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

    private let faviconStore: SDImageCache
    private let thumbnailStore: SDImageCache

    private var tabsFileURL: URL {
        .documentsDirectory.appending(path: "Tabs.json")
    }

    init() {
        faviconStore = .init(namespace: "FaviconStore", diskCacheDirectory: URL.documentsDirectory.path(), config: .default)
        thumbnailStore = .init(namespace: "ThumbnailStore", diskCacheDirectory: URL.documentsDirectory.path(), config: .default)
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
        // TODO: Optimize thumbnail and favicon updates.
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
        jsonEncoder.userInfo = [
            Self.faviconStoreUserInfoKey: faviconStore,
            Self.thumbnailStoreUserInfoKey: thumbnailStore
        ]
        do {
            return try jsonEncoder.encode(data)
        } catch {
            print(">>> error encoding tabs data: \(error)")
            return nil
        }
    }

    private func decode(data: Data) -> TabsData? {
        let jsonDecoder = JSONDecoder()
        jsonDecoder.userInfo = [
            Self.faviconStoreUserInfoKey: faviconStore,
            Self.thumbnailStoreUserInfoKey: thumbnailStore
        ]
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

    enum CodingKeys: String, CodingKey {
        case url
    }

    func encode(to encoder: any Encoder) throws {
        let faviconStore = encoder.userInfo[TabsStorage.faviconStoreUserInfoKey] as! SDImageCache
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(url, forKey: .url)
        faviconStore.store(image, forKey: url.absoluteString, toDisk: true)
    }

    init(from decoder: any Decoder) throws {
        let faviconStore = decoder.userInfo[TabsStorage.faviconStoreUserInfoKey] as! SDImageCache
        let container = try decoder.container(keyedBy: CodingKeys.self)

        url = try container.decode(URL.self, forKey: .url)
        image = faviconStore.imageFromCache(forKey: url.absoluteString)
    }
}

extension Thumbnail: Codable {
    struct DecodingError: Error {}

    enum CodingKeys: String, CodingKey {
        case id
    }

    func encode(to encoder: any Encoder) throws {
        let thumbnailStore = encoder.userInfo[TabsStorage.thumbnailStoreUserInfoKey] as! SDImageCache
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        thumbnailStore.store(image, forKey: id.uuidString, toDisk: true)
    }
    
    init(from decoder: any Decoder) throws {
        let thumbnailStore = decoder.userInfo[TabsStorage.thumbnailStoreUserInfoKey] as! SDImageCache
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        image = thumbnailStore.imageFromCache(forKey: id.uuidString)
    }
}
