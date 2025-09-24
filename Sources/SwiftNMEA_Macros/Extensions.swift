extension String {
  var uppercasedFirstChar: String {
    guard let first else { return self }
    let rest = suffix(from: index(after: startIndex))
    return first.uppercased() + rest
  }
}
