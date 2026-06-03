// swiftlint:disable:next missing_docs
public struct SecurityPassword {
  private init() {}

  /**
   Password level reported by the `SPW` sentence.

   An integer number identifying the privilege level associated with the
   password. Values `3` through `9` are reserved.

   - SeeAlso: ``Message/Payload-swift.enum/securityPassword(protectedSentence:uniqueID:level:password:)``
   */
  public enum Level: Int, Sendable, Codable, Equatable {

    /// `1` = User level password
    case user = 1

    /// `2` = Administrator level password
    case administrator = 2
  }
}
