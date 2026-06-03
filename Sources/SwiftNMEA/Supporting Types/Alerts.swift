import Foundation

// Namespace for types shared by the Bridge Alert Management (BAM) sentences
// ACN (8.3.7), AGL (8.3.9), ALC (8.3.13), ALF (8.3.14), and ARC (8.3.17),
// as described in IEC 61162-1 ed.6.0 (2024) and IEC 62923-1.
// swiftlint:disable:next missing_docs
public struct Alert {
  private init() {}

  /// The command an `ACN` sentence issues for an alert, or the command an
  /// `ARC` sentence reports as refused.
  ///
  /// - SeeAlso: ``Identifier``
  public enum Command: Character, Sendable, Codable, Equatable {

    /// Acknowledge the alert (`A`). Not permitted for alert instance `0` in
    /// an `ACN` sentence.
    case acknowledge = "A"

    /// Request or repeat alert information (`Q`). In an `ACN` sentence this
    /// requests retransmission of alert details (e.g. a missed `ALF`).
    case requestRepeat = "Q"

    /// Transfer responsibility for the alert (`O`). Not permitted for alert
    /// instance `0` in an `ACN` sentence.
    case responsibilityTransfer = "O"

    /// Temporarily silence the alert (`S`).
    case temporarySilence = "S"
  }

  /// The alert category, in compliance with the INS Performance Standard
  /// (IMO MSC.252(83)) and Bridge Alert Management Performance Standard
  /// (IMO MSC.302(87)). Reported by the `ALF` sentence.
  public enum Category: Character, Sendable, Codable, Equatable {

    /// Category A: alerts where information at the operator unit directly
    /// assigned to the function generating the alert is necessary as decision
    /// support (e.g. graphical danger of collision or grounding).
    case A = "A"

    /// Category B: alerts where no additional information for decision support
    /// is necessary besides the alert source and alert description text.
    case B = "B"

    /// Category C: alerts that cannot be acknowledged on the bridge but for
    /// which status and treatment information is required (e.g. certain engine
    /// alerts).
    case C = "C"
  }

  /// The alert priority, in compliance with the Bridge Alert Management
  /// Performance Standard (IMO MSC.302(87)). Reported by the `ALF` sentence.
  public enum Priority: Character, Sendable, Codable, Equatable {

    /// Emergency alarm (`E`): indicates immediate danger to human life or to
    /// the ship and its machinery exists and requires immediate action.
    case emergencyAlarm = "E"

    /// Alarm (`A`): condition requiring immediate attention and action by the
    /// bridge team to maintain safe navigation and operation of the ship.
    case alarm = "A"

    /// Warning (`W`): condition requiring immediate attention, but no immediate
    /// action by the bridge team.
    case warning = "W"

    /// Caution (`C`): awareness of a condition that does not warrant an alarm
    /// or warning, but still requires attention out of the ordinary.
    case caution = "C"
  }

  /// The alert state, with transitions defined in IEC 62923-1. Reported by the
  /// `ALF` sentence.
  public enum State: Character, Sendable, Codable, Equatable {

    /// Active – unacknowledged (`V`).
    case activeUnacknowledged = "V"

    /// Active – silenced (`S`).
    case activeSilenced = "S"

    /// Active – acknowledged, or active (`A`).
    case activeAcknowledged = "A"

    /// Active – responsibility transferred (`O`).
    case activeResponsibilityTransferred = "O"

    /// Rectified – unacknowledged (`U`).
    case rectifiedUnacknowledged = "U"

    /// Normal (`N`).
    case normal = "N"
  }

  /// Identifies an alert uniquely within an alert source, shared by all five
  /// BAM sentences. An alert is identified by the combination of an optional
  /// manufacturer's mnemonic code, an alert identifier (the type of alert),
  /// and an alert instance (which instance of that type).
  ///
  /// - SeeAlso: ``Command``
  public struct Identifier: Sendable, Codable, Equatable {

    /// The manufacturer's mnemonic code, used for proprietary alerts (see
    /// 7.1.6). `nil` (a null field) for standardized alerts.
    public let manufacturerMnemonic: String?

    /// The alert identifier: a variable-length integer of maximum seven
    /// digits identifying the type of alert (e.g. a "lost target" alert).
    /// Standardized alerts use unique identifiers from equipment standards;
    /// the range `10000`–`9999999` is reserved for proprietary alerts.
    /// The value `0` is reserved for a command request to all alerts
    /// (`ACN` only).
    public let identifier: UInt

    /// The alert instance, distinguishing alerts of the same type from the
    /// same source. A maximum six-digit integer; `nil` (a null field) when
    /// there is only one alert of that type. The value `0` addresses all
    /// instances (`ACN`), or denotes a group/aggregation header alert
    /// (`ALF`, `AGL`).
    public let instance: UInt?

    public init(manufacturerMnemonic: String?, identifier: UInt, instance: UInt?) {
      self.manufacturerMnemonic = manufacturerMnemonic
      self.identifier = identifier
      self.instance = instance
    }
  }
}
