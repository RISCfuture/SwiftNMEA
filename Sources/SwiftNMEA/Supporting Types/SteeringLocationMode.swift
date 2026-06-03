// swiftlint:disable:next missing_docs
public struct SteeringLocationMode {
  private init() {}

  /**
   System status reported by the `SLM` sentence, indicating whether the
   steering system is active in control.

   - SeeAlso: ``Message/Payload-swift.enum/steeringLocationMode(systemStatus:location:locationDescription:mode:subMode:)``
   */
  public enum SystemStatus: Int, Sendable, Codable, Equatable {

    /// `0` = not in control (passive)
    case passive = 0

    /// `1` = in control (active)
    case active = 1

    /// `2` = internal failure (unable to be in control)
    case failure = 2
  }

  /**
   Steering location reported by the `SLM` sentence.

   Identifies the physical location from which steering is being performed. In
   the case of ``others``, the steering location description field of the
   `SLM` sentence is to be filled in.

   - SeeAlso: ``Message/Payload-swift.enum/steeringLocationMode(systemStatus:location:locationDescription:mode:subMode:)``
   */
  public enum Location: Character, Sendable, Codable, Equatable {

    /// `B` = Bridge (centre position)
    case bridge = "B"

    /// `P` = Port wing
    case portWing = "P"

    /// `S` = Starboard wing
    case starboardWing = "S"

    /// `A` = Aft bridge
    case aftBridge = "A"

    /// `X` = Aft bridge port wing
    case aftBridgePortWing = "X"

    /// `Y` = Aft bridge starboard wing
    case aftBridgeStarboardWing = "Y"

    /// `F` = Fly bridge
    case flyBridge = "F"

    /// `C` = Engine control room
    case controlRoom = "C"

    /// `E` = Engine side / local
    case engineLocal = "E"

    /// `M` = Emergency steering stand
    case emergencyStand = "M"

    /// `R` = Steering gear room
    case steeringGearRoom = "R"

    /// `O` = Others
    case others = "O"
  }

  /**
   Steering mode reported by the `SLM` sentence.

   The steering mode may be supplemented by free-text describing a sub-mode
   (the SubMode field of the `SLM` sentence), as dynamic positioning and
   joystick systems in particular have a great variety of modes.

   - SeeAlso: ``Message/Payload-swift.enum/steeringLocationMode(systemStatus:location:locationDescription:mode:subMode:)``
   */
  public enum Mode: Character, Sendable, Codable, Equatable {

    /// `D` = Direct (e.g. direct access to valves)
    case direct = "D"

    /// `M` = Manual
    case manual = "M"

    /// `A` = Autopilot
    case autopilot = "A"

    /// `P` = Dynamic positioning
    case dynamicPositioning = "P"

    /// `J` = Joystick
    case joystick = "J"

    /// `E` = Emergency
    case emergency = "E"
  }
}
