import Foundation

extension StringProtocol {
  package func slice(from start: Int, to end: Int) -> SubSequence {
    let start = index(startIndex, offsetBy: start)
    let end = index(startIndex, offsetBy: end)
    return self[start...end]
  }

  package func slice(from start: Int) -> SubSequence {
    let start = index(startIndex, offsetBy: start)
    return self[start...]
  }

  package func slice(to end: Int) -> SubSequence {
    let end = index(startIndex, offsetBy: end)
    return self[...end]
  }

  package func sslice(from start: Int, to end: Int) -> String {
    String(slice(from: start, to: end))
  }

  package func sslice(from start: Int) -> String {
    String(slice(from: start))
  }

  package func sslice(to end: Int) -> String {
    String(slice(to: end))
  }

  package func char(at: Int) -> Character? {
    self[safe: index(startIndex, offsetBy: at)]
  }
}
