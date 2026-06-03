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
   ITU-R M.1371-6, Table 51.

   - SeeAlso: ``Message/Payload-swift.enum/AISLongRangeReply(requestorMMSI:requestorName:replyStatuses:time:shipName:shipCallsign:shipIMO:position:course:speed:destination:ETA:shipType:shipType2:length:breadth:draught:soulsOnboard:)``
   */
  public enum ShipType: RawRepresentable, Sendable, Codable, Equatable {
    public typealias RawValue = Int

    /// Special purpose ship (01–09)
    case specialPurpose(SpecialPurpose)

    /// Support vessel (10–19)
    case supportVessel(SupportVessel)

    /// Wing In Ground effect (WIG)
    case groundEffect(cargo: CargoType)

    /// Special craft / vessel engaged in a particular operation (30–39)
    case vessel(operation: Operation)

    /// High-speed craft (HSC)
    case highSpeedCraft(HSC)

    /// Pilot vessel
    case pilot

    /// Search and rescue vessels
    case SAR

    /// Tugs
    case tug

    /// Port or fish tenders
    case tender

    /// Anti-pollution or firefighting responder
    case antiPollution

    /// Law enforcement vessels
    case lawEnforcement

    /// Spare 1 – for assignments to local vessels
    case localVessel1

    /// Spare 2 – for assignments to local vessels
    case localVessel2

    /// Medical transports (as defined in the 1949 Geneva Conventions and Additional Protocols)
    case medical

    /// Ships of States not parties to an armed conflict
    case nonparticipant

    /// Passenger ships
    case passengerShip(Passenger)

    /// Cargo ships
    case cargoShip(Cargo)

    /// Tanker(s)
    case tanker(Tanker)

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
        case .localVessel1: return 56
        case .localVessel2: return 57
        case .medical: return 58
        case .nonparticipant: return 59

        case .specialPurpose(let type): return type.rawValue
        case .supportVessel(let type): return 10 + type.rawValue
        case .groundEffect(let cargo): return 20 + cargo.rawValue
        case .vessel(let operation): return 30 + operation.rawValue
        case .highSpeedCraft(let type): return 40 + type.rawValue
        case .passengerShip(let type): return 60 + type.rawValue
        case .cargoShip(let type): return 70 + type.rawValue
        case .tanker(let type): return 80 + type.rawValue
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
        case 56: self = .localVessel1
        case 57: self = .localVessel2
        case 58: self = .medical
        case 59: self = .nonparticipant

        case 1...9:
          guard let type = SpecialPurpose(rawValue: rawValue) else { return nil }
          self = .specialPurpose(type)
        case 10...19:
          guard let type = SupportVessel(rawValue: rawValue - 10) else { return nil }
          self = .supportVessel(type)
        case 20...29:
          guard let cargo = CargoType(rawValue: rawValue - 20) else { return nil }
          self = .groundEffect(cargo: cargo)
        case 30...39:
          guard let operation = Operation(rawValue: rawValue - 30) else { return nil }
          self = .vessel(operation: operation)
        case 40...49:
          guard let type = HSC(rawValue: rawValue - 40) else { return nil }
          self = .highSpeedCraft(type)
        case 60...69:
          guard let type = Passenger(rawValue: rawValue - 60) else { return nil }
          self = .passengerShip(type)
        case 70...79:
          guard let type = Cargo(rawValue: rawValue - 70) else { return nil }
          self = .cargoShip(type)
        case 80...89:
          guard let type = Tanker(rawValue: rawValue - 80) else { return nil }
          self = .tanker(type)
        case 90...99:
          guard let cargo = CargoType(rawValue: rawValue - 90) else { return nil }
          self = .other(cargo: cargo)

        default: return nil
      }
    }

    /// Special purpose ships, as defined in ITU-R M.1371-6, Table 51 (01–09).
    public enum SpecialPurpose: Int, Sendable, Codable, Equatable {

      /// Science / Research vessel
      case research = 1

      /// Training vessel
      case training = 2

      /// Ship owned or operated by a government
      case government = 3

      /// Ice breaker
      case iceBreaker = 4

      /// Buoy (Aids to Navigation) tender
      case buoyTender = 5

      /// Cable layer
      case cableLayer = 6

      /// Pipe layer
      case pipeLayer = 7

      /// Special purpose ship, no additional information
      case noInfo = 9
    }

    /// Support vessels, as defined in ITU-R M.1371-6, Table 51 (10–19).
    public enum SupportVessel: Int, Sendable, Codable, Equatable {

      /// FPSO (Floating, Production, Storage, Offloading) vessel
      case FPSO = 1

      /// Fish factory ship
      case fishFactory = 2

      /// Fish farm support vessel
      case fishFarm = 3

      /// Offshore support vessel, etc.
      case offshoreSupport = 4

      /// Construction vessel
      case construction = 7

      /// Crew boat
      case crewBoat = 8

      /// Support vessel, no additional information
      case noInfo = 9
    }

    /// High-speed craft sub-types, as defined in ITU-R M.1371-6, Table 51 (40–49).
    public enum HSC: Int, Sendable, Codable, Equatable {

      /// All ships of this type
      case all = 0

      /// Carrying DG, HS, or MP, IMO hazard or pollutant category X
      case categoryX = 1

      /// Carrying DG, HS, or MP, IMO hazard or pollutant category Y
      case categoryY = 2

      /// Carrying DG, HS, or MP, IMO hazard or pollutant category Z
      case categoryZ = 3

      /// Carrying DG, HS, or MP, IMO hazard or pollutant category OS
      case categoryOS = 4

      /// Carrying passengers
      case passengers = 5

      /// Ro-Ro ship (vehicle / rail)
      case rollOnRollOff = 6

      /// No additional information
      case noInfo = 9
    }

    /// Passenger ship sub-types, as defined in ITU-R M.1371-6, Table 51 (60–69).
    public enum Passenger: Int, Sendable, Codable, Equatable {

      /// All ships of this type
      case all = 0

      /// Carrying DG, HS, or MP, IMO hazard or pollutant category X
      case categoryX = 1

      /// Carrying DG, HS, or MP, IMO hazard or pollutant category Y
      case categoryY = 2

      /// Carrying DG, HS, or MP, IMO hazard or pollutant category Z
      case categoryZ = 3

      /// Carrying DG, HS, or MP, IMO hazard or pollutant category OS
      case categoryOS = 4

      /// Cruise ship
      case cruise = 5

      /// Ferry
      case ferry = 6

      /// Excursion ship (i.e. harbour cruise boat, whale watcher, etc.)
      case excursion = 7

      /// No additional information
      case noInfo = 9
    }

    /// Cargo ship sub-types, as defined in ITU-R M.1371-6, Table 51 (70–79).
    public enum Cargo: Int, Sendable, Codable, Equatable {

      /// All ships of this type
      case all = 0

      /// Carrying DG, HS, or MP, IMO hazard or pollutant category X
      case categoryX = 1

      /// Carrying DG, HS, or MP, IMO hazard or pollutant category Y
      case categoryY = 2

      /// Carrying DG, HS, or MP, IMO hazard or pollutant category Z
      case categoryZ = 3

      /// Carrying DG, HS, or MP, IMO hazard or pollutant category OS
      case categoryOS = 4

      /// Bulk carrier
      case bulkCarrier = 5

      /// Container ship
      case containerShip = 6

      /// Roll-on-roll-off carrier
      case rollOnRollOff = 7

      /// Landing craft
      case landingCraft = 8

      /// No additional information
      case noInfo = 9
    }

    /// Tanker sub-types, as defined in ITU-R M.1371-6, Table 51 (80–89).
    public enum Tanker: Int, Sendable, Codable, Equatable {

      /// All ships of this type
      case all = 0

      /// Carrying DG, HS, or MP, IMO hazard or pollutant category X
      case categoryX = 1

      /// Carrying DG, HS, or MP, IMO hazard or pollutant category Y
      case categoryY = 2

      /// Carrying DG, HS, or MP, IMO hazard or pollutant category Z
      case categoryZ = 3

      /// Carrying DG, HS, or MP, IMO hazard or pollutant category OS
      case categoryOS = 4

      /// Non-hazardous or non-pollutant carrier
      case nonHazardous = 5

      /// Integrated / articulated tug and tank barge (ABCD values should
      /// reflect tug and barge dimensions)
      case integratedTugBarge = 6

      /// No additional information
      case noInfo = 9
    }

    /// Maritime operations / special craft, as defined in ITU-R M.1371-6, Table 51 (30–39).
    public enum Operation: Int, Sendable, Codable, Equatable {

      /// Fishing vessel
      case fishing = 0

      /// Towing
      case towing = 1

      /// Towing and length of the tow exceeds 200 m or breadth exceeds 25 m
      case longTow = 2

      /// Dredger
      case dredging = 3

      /// Diving vessel
      case diving = 4

      /// Warship or naval auxiliary
      case military = 5

      /// Sailing vessel
      case sailing = 6

      /// Pleasure motor craft
      case pleasure = 7

      /// Trawler
      case trawler = 8

      /// Patrol vessel
      case patrol = 9
    }

    /**
     Hazardous cargo categories, as defined in ITU-R M.1371-6, Table 51.

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
