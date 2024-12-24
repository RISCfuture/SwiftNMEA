package extension Collection {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

package extension Collection where Element: Equatable {
    func split2(_ element: Element) -> (SubSequence, SubSequence)? {
        let parts = split(separator: element)
        guard parts.count == 2 else { return nil }
        return (parts[0], parts[1])
    }
}

package extension Dictionary where Value: Equatable {
    func key(for value: Value) -> Key? {
        return first { $0.1 == value }?.0
    }
}
