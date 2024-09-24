import IdentifiedCollections

extension IdentifiedArray {
    public mutating func move(fromOffset: Int, toOffset: Int) {
        let element = remove(at: fromOffset)
        insert(element, at: toOffset)
    }
}
