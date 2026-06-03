import Foundation

/// A single alert entry within an `AGL` (alert group list) message, as
/// described in IEC 61162-1 ed.6.0 (2024) 8.3.9. Each entry identifies one
/// alert that belongs to a functional alert group. The first entry of an
/// `AGL` message is the group header alert (its ``Alert/Identifier/instance``
/// is `0`).
///
/// - SeeAlso: ``Alert/Identifier``
public struct AlertGroupEntry: Sendable, Codable, Equatable {

  /// The System Function ID (SFI) of the alert source, as defined in
  /// IEC 61162-450, used to distinguish alerts from different sources.
  /// `nil` (a null field) when used on a non IEC 61162-450 interface, in
  /// which case the alert is from the `AGL` source itself.
  public let systemFunctionID: String?

  /// The identification of the alert (manufacturer's mnemonic code, alert
  /// identifier, and alert instance). For the group header entry the
  /// ``Alert/Identifier/instance`` is `0`.
  public let alert: Alert.Identifier

  public init(systemFunctionID: String?, alert: Alert.Identifier) {
    self.systemFunctionID = systemFunctionID
    self.alert = alert
  }
}
