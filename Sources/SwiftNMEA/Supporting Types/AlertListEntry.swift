import Foundation

extension Alert {

  /// A single entry in an `ALC` cyclic alert list. Each entry pairs the shared
  /// alert ``Identifier`` with the alert's revision counter, providing the
  /// condensed `ALF` information needed to detect whether an `ALF` sentence was
  /// missed (see IEC 61162-1 ed.6.0, 8.3.13).
  public struct ListEntry: Sendable, Codable, Equatable {

    /// The alert this entry describes (manufacturer's mnemonic code, alert
    /// identifier, and alert instance).
    public let identifier: Identifier

    /// The revision counter, the main method to follow an alert's up-to-date
    /// status. It is unique for each alert instance, starts at `1`, increments
    /// by `1` on each change of any field of the alert, and resets to `1` after
    /// `99`. Range `1`–`99`.
    public let revisionCounter: UInt

    public init(identifier: Identifier, revisionCounter: UInt) {
      self.identifier = identifier
      self.revisionCounter = revisionCounter
    }
  }
}
