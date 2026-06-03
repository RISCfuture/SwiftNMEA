import Foundation

/// Namespace for the equipment-property command/report types shared by the
/// `EPM` (8.3.32) and `EPV` (8.3.33) sentences.
///
/// Both sentences command or report a single equipment setting (a "property")
/// addressed to or originating from a specific piece of equipment. The
/// "Sentence status flag" that distinguishes a command from a report is the
/// existing ``SentenceType`` enumeration, and the "Equipment type" two-character
/// talker ID is the existing ``Talker`` enumeration; neither is redefined here.
public struct EquipmentProperty {
  private init() {}

  /// Identifies the piece of equipment a property command is addressed to, or
  /// that a property report originates from.
  ///
  /// This composite is shared by the `EPM` (8.3.32) and `EPV` (8.3.33)
  /// sentences. It pairs the "Equipment type" field with the "Unique
  /// identifier" field, both of which carry the same meaning regardless of
  /// whether the sentence is a command or a report.
  public struct Reference: Sendable, Codable, Equatable {

    /// The equipment type.
    ///
    /// When the sentence is a command, this is the two-character talker ID of
    /// the destination equipment, identifying the device type for which the
    /// sentence is targeted. When the sentence is a report (for example, in
    /// response to a query), this is the talker ID of the equipment generating
    /// the sentence.
    public let type: Talker

    /// The unique identifier.
    ///
    /// Identifies the same equipment irrespective of command versus response.
    /// For commands, it identifies the equipment intended to receive the
    /// command. For responses, it identifies the equipment that actually
    /// received the command. May be `nil` in `EPM`, where the field is
    /// nullable; required in `EPV`.
    public let uniqueID: String?

    public init(type: Talker, uniqueID: String?) {
      self.type = type
      self.uniqueID = uniqueID
    }
  }

  /// Identifies a settable equipment parameter ("property") within an
  /// equipment-property command or report.
  ///
  /// This is a variable-length, non-negative integer field, defined by an
  /// applicable equipment standard and intended for commissioning settings. It
  /// is shared by the `EPM` (8.3.32) and `EPV` (8.3.33) sentences. The concrete
  /// codes are equipment-specific and therefore not enumerated here.
  public struct Identifier: RawRepresentable, Sendable, Codable, Equatable, Hashable {
    public typealias RawValue = UInt

    public let rawValue: UInt

    public init(rawValue: UInt) {
      self.rawValue = rawValue
    }
  }
}
