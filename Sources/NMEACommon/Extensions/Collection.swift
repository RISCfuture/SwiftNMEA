extension Collection {
  package subscript(safe index: Index) -> Element? {
    return indices.contains(index) ? self[index] : nil
  }
}

extension Collection where Element: Equatable {
  package func split2(_ element: Element) -> (SubSequence, SubSequence)? {
    let parts = split(separator: element)
    guard parts.count == 2 else { return nil }
    return (parts[0], parts[1])
  }
}

extension Dictionary where Value: Equatable {
  package func key(for value: Value) -> Key? {
    return first { $0.1 == value }?.0
  }
}
