import IdentifiedCollections

extension IdentifiedArray {
    public mutating func move(fromOffset: Int, toOffset: Int) {
        let element = remove(at: fromOffset)
        insert(element, at: toOffset)
    }

    public mutating func moveSubrange(fromOffset: Int, toOffset: Int, count: Int) where Element: Identifiable, ID == Element.ID {
        let subrange = fromOffset..<(fromOffset + count)
        let extractedElements = self[subrange]

        // Step 2: Remove the elements in the subrange from the original array
        removeSubrange(subrange)

        // Step 3: Adjust the destination index if the removal of elements affects it
        let adjustedDestinationIndex = toOffset - (subrange.lowerBound < toOffset ? subrange.count : 0)

        // Step 4: Insert the extracted elements at the new location
        insert(contentsOf: extractedElements, at: adjustedDestinationIndex)
    }
}
