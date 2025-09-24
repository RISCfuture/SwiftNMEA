import NMEACommon

// swiftlint:disable:next missing_docs
public struct AISLongRange {
  private init() {}

  /**
   AIS unit reply logic.
  
   - SeeAlso: ``Message/Payload-swift.enum/AISLongRangeInterrogation(replyLogic:requestorMMSI:requestorName:destination:functions:)``
   */
  public enum ReplyLogic: Int, Sendable, Codable, Equatable {

    /**
     Normal AIS unit reply logic.
    
     Under “normal” operation, the AIS unit responds if either:
    
     * the AIS unit is within the geographic rectangle provided, and
     * the AIS unit has not responded to the requesting MMSI in the last 24 hours, and
     * the MMSI “destination” field is null.
    
     or
    
     * The AIS unit’s MMSI appears in the MMSI “destination” field in the LRI sentence.
     */
    case normal = 0

    /**
     Geographic AIS unit reply logic.
    
     the AIS unit responds if:
    
     * the AIS unit is within the geographic rectangle provided.
     */
    case geographic = 1
  }

  /**
   AIS request destinations.
  
   - SeeAlso: ``Message/Payload-swift.enum/AISLongRangeInterrogation(replyLogic:requestorMMSI:requestorName:destination:functions:)``
   */
  public enum Destination: Sendable, Codable, Equatable {

    /// Request for a single ship.
    case MMSI(_ MMSI: Int)

    /// Request for all ships in a geographic area.
    case area(_ area: GeoArea)
  }

  /**
   AIS function request items.
  
   See IMO Resolution A.851(20).
  
   - SeeAlso: ``Message/Payload-swift.enum/AISLongRangeInterrogation(replyLogic:requestorMMSI:requestorName:destination:functions:)``
   - SeeAlso: ``Message/Payload-swift.enum/AISLongRangeReply(requestorMMSI:requestorName:replyStatuses:time:shipName:shipCallsign:shipIMO:position:course:speed:destination:ETA:shipType:shipType2:length:breadth:draught:soulsOnboard:)``
   */
  public enum Function: Character, Sendable, Codable, Equatable {

    /// Ship’s name, call sign, and IMO number (`LR1`)
    case shipID = "A"

    /// Date and time of message composition (`LR2`)
    case dateTime = "B"

    /// Position (`LR2`)
    case position = "C"

    /// Course over ground (`LR2`)
    case course = "E"

    /// Speed over ground (`LR2`)
    case speed = "F"

    /// Destination and Estimated Time of Arrival (ETA) (`LR3`)
    case destination = "I"

    /// Draught (`LR3`)
    case draught = "O"

    /// Ship/cargo (`LR3`)
    case cargo = "P"

    /// Ship’s: length, breadth, type (`LR3`)
    case shipDimensions = "U"

    /// Persons on board (`LR3`)
    case soulsOnboard = "W"
  }

  /**
   Function reply statuses.
  
   - SeeAlso: ``Message/Payload-swift.enum/AISLongRangeReply(requestorMMSI:requestorName:replyStatuses:time:shipName:shipCallsign:shipIMO:position:course:speed:destination:ETA:shipType:shipType2:length:breadth:draught:soulsOnboard:)``
   */
  public enum FunctionStatus: Int, Sendable, Codable, Equatable {

    /// Information available and provided in the following `LR1`, `LR2` or
    /// `LR3` sentence
    case available = 2

    /// Information not available from AIS unit
    case unavailable = 3

    /// Information is available but not provided (i.e. restricted access
    /// determined by the ship’s master)
    case restricted = 4
  }

  /**
   Identifiers to be used by ships to report their type, as defined in
   ITU-R M.1371-5, table 53.
  
   - SeeAlso: ``Message/Payload-swift.enum/AISLongRangeReply(requestorMMSI:requestorName:replyStatuses:time:shipName:shipCallsign:shipIMO:position:course:speed:destination:ETA:shipType:shipType2:length:breadth:draught:soulsOnboard:)``
   */
  public enum ShipType: RawRepresentable, Sendable, Codable, Equatable {
    public typealias RawValue = Int

    /// Pilot vessel
    case pilot

    /// Search and rescue vessels
    case SAR

    /// Tugs
    case tug

    /// Port tenders
    case tender

    /// Vessels with anti-pollution facilities or equipment
    case antiPollution

    /// Law enforcement vessels
    case lawEnforcement

    /// Medical transports (as defined in the 1949 Geneva Conventions and Additional Protocols)
    case medical

    /// Ships and aircraft of States not parties to an armed conflict
    case nonparticipant

    /// Wing In Ground effect (WIG)
    case groundEffect(cargo: CargoType)

    /// Vessel
    case vessel(operation: Operation)

    /// High-speed craft (HSC)
    case highSpeedCraft(cargo: CargoType)

    /// Passenger ships
    case passengerShip(cargo: CargoType)

    /// Cargo ships
    case cargoShip(cargo: CargoType)

    /// Tanker(s)
    case tanker(cargo: CargoType)

    /// Other types of ship
    case other(cargo: CargoType)

    public var rawValue: Int {
      switch self {
        case .pilot: return 50
        case .SAR: return 51
        case .tug: return 52
        case .tender: return 53
        case .antiPollution: return 54
        case .lawEnforcement: return 55
        case .medical: return 58
        case .nonparticipant: return 59

        case .groundEffect(let cargo): return 20 + cargo.rawValue
        case .vessel(let operation): return 30 + operation.rawValue
        case .highSpeedCraft(let cargo): return 40 + cargo.rawValue
        case .passengerShip(let cargo): return 60 + cargo.rawValue
        case .cargoShip(let cargo): return 70 + cargo.rawValue
        case .tanker(let cargo): return 80 + cargo.rawValue
        case .other(let cargo): return 90 + cargo.rawValue
      }
    }

    public init?(rawValue: Int) {
      switch rawValue {
        case 50: self = .pilot
        case 51: self = .SAR
        case 52: self = .tug
        case 53: self = .tender
        case 54: self = .antiPollution
        case 55: self = .lawEnforcement
        case 58: self = .medical
        case 59: self = .nonparticipant

        case 20...29:
          guard let cargo = CargoType(rawValue: rawValue - 20) else { return nil }
          self = .groundEffect(cargo: cargo)
        case 30...39:
          guard let operation = Operation(rawValue: rawValue - 30) else { return nil }
          self = .vessel(operation: operation)
        case 40...59:
          guard let cargo = CargoType(rawValue: rawValue - 40) else { return nil }
          self = .highSpeedCraft(cargo: cargo)
        case 60...69:
          guard let cargo = CargoType(rawValue: rawValue - 60) else { return nil }
          self = .passengerShip(cargo: cargo)
        case 70...79:
          guard let cargo = CargoType(rawValue: rawValue - 70) else { return nil }
          self = .cargoShip(cargo: cargo)
        case 80...89:
          guard let cargo = CargoType(rawValue: rawValue - 80) else { return nil }
          self = .tanker(cargo: cargo)
        case 90...99:
          guard let cargo = CargoType(rawValue: rawValue - 90) else { return nil }
          self = .other(cargo: cargo)

        default: return nil
      }
    }

    /// Maritime operations, as defined in ITU-R M.1371-5, table 53
    public enum Operation: Int, Sendable, Codable, Equatable {

      /// Fishing
      case fishing = 0

      /// Towing
      case towing = 1

      /// Towing and length of the tow exceeds 200 m or breadth exceeds 25 m
      case longTow = 2

      /// Engaged in dredging or underwater operations
      case dredging = 3

      /// Engaged in diving operations
      case diving = 4

      /// Engaged in military operations
      case military = 5

      /// Sailing
      case sailing = 6

      /// Pleasure craft
      case pleasure = 7
    }

    /**
     Hazardous cargo categories, as defined in ITU-R M.1371-5, table 53.
    
     DG: dangerous goods, HS: harmful substances, MP: marine pollutants
     */
    public enum CargoType: Int, Sendable, Codable, Equatable {

      /// All ships of this type
      case all = 0

      /**
       Carrying DG, HS, or MP, IMO hazard or pollutant category X.
      
       Category X: Noxious Liquid Substances which, if discharged into the
       sea from tank cleaning or deballasting operations, are deemed to
       present a major hazard to either marine resources or human health
       and, therefore, justify the prohibition of the discharge into the
       marine environment.
       */
      case categoryX = 1

      /**
       Carrying DG, HS, or MP, IMO hazard or pollutant category Y.
      
       Category Y: Noxious Liquid Substances which, if discharged into the
       sea from tank cleaning or deballasting operations, are deemed to
       present a hazard to either marine resources or human health or
       cause harm to amenities or other legitimate uses of the sea and
       therefore justify a limitation on the quality and quantity of the
       discharge into the marine environment.
       */
      case categoryY = 2

      /**
       Carrying DG, HS, or MP, IMO hazard or pollutant category Z.
      
       Category Z: Noxious Liquid Substances which, if discharged into the
       sea from tank cleaning or deballasting operations, are deemed to
       present a minor hazard to either marine resources or human health
       and therefore justify less stringent restrictions on the quality
       and quantity of the discharge into the marine environment.
       */
      case categoryZ = 3

      /**
       Carrying DG, HS, or MP, IMO hazard or pollutant category OS (other
       substances).
      
       Other Substances: substances which have been evaluated and found to
       fall outside Category X, Y or Z because they are considered to
       present no harm to marine resources, human health, amenities or
       other legitimate uses of the sea when discharged into the sea from
       tank cleaning of deballasting operations. The discharge of bilge or
       ballast water or other residues or mixtures containing these
       substances are not subject to any requirements of MARPOL Annex II.
       */
      case categoryOS = 4

      /// No additional information
      case noInfo = 9
    }
  }
}
