import Foundation

extension Array where Element == Data {
  func combined() -> Data {
    self.reduce(into: Data()) { $0.append($1) }
  }
}
