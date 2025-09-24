// swiftlint:disable:next missing_docs
public struct Steering {
  private init() {}

  /**
   Possible values for selected steering mode.
  
   All steering modes represent steering as selected by a steering selector
   switch or by a preceding `HTC` sentence. Priority levels of these inputs
   and usage/acceptance of related fields are to be defined and documented
   by the manufacturer.
   */
  public enum Mode: Character, Sendable, Codable, Equatable {

    /// Manual steering. The main steering system is in use.
    case manual = "M"

    /// Stand-alone (heading control). The system works as a stand-alone
    /// heading controller. Field ”commanded heading to steer” is not
    /// accepted as an input.
    case standalone = "S"

    /// Heading control. Input of commanded heading to steer is from an
    /// external device and the system works as a remotely controlled
    /// heading controller. Field "commanded heading to steer" is accepted
    /// as an input.
    case headingControl = "H"

    /// Track control. The system works as a track controller by correcting
    /// a course received in field “commanded track”. Corrections are made
    /// based on additionally received track errors (e.g. from sentence
    /// `XTE`, `APB`, etc.).
    case trackControl = "T"

    /// Rudder control. Input of commanded rudder angle and direction from
    /// an external device. The system accepts values given in fields
    /// “commanded rudder angle” and “commanded rudder direction” and
    /// controls the steering by the same electronic means as used in
    /// modes ``standalone``, ``headingControl`` or ``trackControl``.
    case rudderControl = "R"
  }

  /**
   Possible values for turn mode.
  
   Turn mode defines how the ship changes heading when in steering modes
   ``Mode/standalone``, ``Mode/headingControl`` or ``Mode/trackControl``
   according to the selected turn mode values given in fields “commanded
   radius of turn” or “commanded rate of turn”. With turn mode set to
   ``uncontrolled``, turns are not controlled but depend upon the ship’s
   manoeuverability and applied rudder angles only.
   */
  public enum TurnControl: Character, Sendable, Codable, Equatable {

    /// Radius controlled
    case radius = "R"

    /// Turn rate controlled
    case rate = "T"

    /// Turn is not controlled
    case uncontrolled = "N"
  }
}
