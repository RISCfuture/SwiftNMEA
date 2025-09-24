import Foundation
import NMEACommon

// swiftlint:disable:next missing_docs
public struct DSC {
  private static var calendar: Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = .gmt
    return calendar
  }

  private init() {}

  /**
   Given an ITU-R M.493-16 encoded "Message 3" string, decodes it as a UTC
   hour and minute time string as specified in section 8.1.3.
  
   - Parameter string: The encoded string.
   - Parameter referenceDate: The reference date to use when searching for a
   matching time.
   - Returns: The parsed time. Returns `nil` if the string "8888" (no valid
   time) is provided, or if the value cannot be parsed, or if a valid
   matching date cannot be found (e.g., an hour that is skipped during a DST
   transition).
   - SeeAlso: ``Message/Payload-swift.enum/DSC(format:MMSI:area:category:message1_1:message1_2:message2:message3:distressMMSI:distressMMSINature:acknowledgement:expansion:)``
   */
  public static func time(from string: String, referenceDate: Date = .now) -> Date? {
    if string == "8888" { return nil }
    let hourStr = string.slice(to: 1)
    let minuteStr = string.slice(from: 2, to: 3)
    guard let hour = Int(hourStr),
      let minute = Int(minuteStr)
    else { return nil }
    let components = DateComponents(calendar: calendar, timeZone: .gmt, hour: hour, minute: minute)
    return calendar.nextDate(
      after: referenceDate,
      matching: components,
      matchingPolicy: .strict,
      repeatedTimePolicy: .first,
      direction: .backward
    )
  }

  /**
   Given an ITU-R M.493-16 encoded "Message 3" string, decodes it as a public
   switched network number (e.g. telephone number), including format
   specifier.
  
   - Parameter string: The encoded string.
   - Returns: The parsed network number, or `nil` if an invalid format
   specifier is given.
   - SeeAlso: ``Message/Payload-swift.enum/DSC(format:MMSI:area:category:message1_1:message1_2:message2:message3:distressMMSI:distressMMSINature:acknowledgement:expansion:)``
   */
  public static func networkNumber(from string: String) -> String? {
    switch string.slice(to: 2) {
      case "105":
        let rest = string.slice(from: 4)
        return String(rest)
      case "106":
        let rest = string.slice(from: 3)
        return String(rest)
      default: return nil
    }
  }

  static func geoArea(from string: String) -> GeoArea? {
    guard ("0000000000"..."9999999999").contains(string),
      let first = string.first,
      let quadrant = Quadrant(rawValue: String(first))
    else {
      return nil
    }
    let latStr = string.slice(from: 1, to: 2)
    let lonStr = string.slice(from: 3, to: 5)
    let deltaLatStr = string.slice(from: 6, to: 7)
    let deltaLonStr = string.slice(from: 8, to: 9)
    guard var lat = Int(latStr),
      var lon = Int(lonStr),
      let deltaLat = Int(deltaLatStr),
      let deltaLon = Int(deltaLonStr)
    else { return nil }

    switch quadrant {
      case .northeast:
        break
      case .northwest:
        lon *= -1
      case .southeast:
        lat *= -1
      case .southwest:
        lat *= -1
        lon *= -1
    }

    return .init(
      latitude: Double(lat),
      longitude: Double(lon),
      deltaLat: Double(deltaLat),
      deltaLon: Double(deltaLon)
    )
  }

  /**
   Given an ITU-R M.493-16 encoded "Message 2" string, decodes it as a set of
   coordinates as specified in section 8.1.2.
  
   - Parameter string: The encoded string.
   - Returns: The decoded coordinates, or `nil` if the string could not be
   decoded.
   - SeeAlso: ``Message/Payload-swift.enum/DSC(format:MMSI:area:category:message1_1:message1_2:message2:message3:distressMMSI:distressMMSINature:acknowledgement:expansion:)``
   */
  public static func distressCoordinates(from string: String) -> Position? {
    guard ("0000000000"..."9999999999").contains(string),
      let first = string.first,
      let quadrant = Quadrant(rawValue: String(first))
    else {
      return nil
    }
    let latDegStr = string.slice(from: 1, to: 2)
    let latMinStr = string.slice(from: 3, to: 4)
    let lonDegStr = string.slice(from: 5, to: 7)
    let lonMinStr = string.slice(from: 8, to: 9)
    guard let latDeg = Int(latDegStr),
      let latMin = Int(latMinStr),
      let lonDeg = Int(lonDegStr),
      let lonMin = Int(lonMinStr)
    else { return nil }
    var latValue = Double(latDeg) + Double(latMin) / 60
    var lonValue = Double(lonDeg) + Double(lonMin) / 60

    switch quadrant {
      case .northeast:
        break
      case .northwest:
        lonValue *= -1
      case .southeast:
        latValue *= -1
      case .southwest:
        latValue *= -1
        lonValue *= -1
    }

    return .init(latitude: latValue, longitude: lonValue)
  }

  /**
   DSC acknowledgement type.
  
   - SeeAlso: ``Message/Payload-swift.enum/DSC(format:MMSI:area:category:message1_1:message1_2:message2:message3:distressMMSI:distressMMSINature:acknowledgement:expansion:)``
   */
  public enum Acknowledgement: Character, Sendable, Codable, Equatable {

    /// Acknowledge request
    case request = "R"

    /// Acknowledgement
    case acknowledgement = "B"

    /// Neither (end of sequence)
    case end = "S"
  }

  /**
   Format specifiers from  ITU M.493.
  
   - SeeAlso: ``Message/Payload-swift.enum/DSC(format:MMSI:area:category:message1_1:message1_2:message2:message3:distressMMSI:distressMMSINature:acknowledgement:expansion:)``
   */
  public enum FormatSpecifier: String, Sendable, Codable, Equatable {

    ///  “Distress” alert
    case distress = "12"

    /// “All ships” call
    case allShips = "16"

    /// Selective call to a group of ships having a common interest (e.g.
    /// belonging to one particular country, or to a single ship owner, etc.)
    case commonInterest = "14"

    /// Selective call to a particular individual station
    case individual = "20"

    /// Selective call to a group of ships in a particular geographic area
    case geographic = "02"

    /// Selective call to a particular individual station using the
    /// automatic service
    case individualAuto = "23"
  }

  /**
   DSC call categories, as defined in ITU-R M.493-16 table A1-3.
  
   - SeeAlso: ``Message/Payload-swift.enum/DSC(format:MMSI:area:category:message1_1:message1_2:message2:message3:distressMMSI:distressMMSINature:acknowledgement:expansion:)``
   */
  public enum Category: String, Sendable, Codable, Equatable {
    case routine = "00"
    case safety = "08"
    case urgency = "10"
    case distress = "12"
  }

  /**
   DSC distress natures, as defined in ITU-R M.493-16 table A1-3.
  
   - SeeAlso: ``Message/Payload-swift.enum/DSC(format:MMSI:area:category:message1_1:message1_2:message2:message3:distressMMSI:distressMMSINature:acknowledgement:expansion:)``
   */
  public enum DistressNature: String, Sendable, Codable, Equatable {

    /// Fire, explosion
    case fire = "00"

    /// Flooding
    case flooding = "01"

    /// Collision
    case collision = "02"

    /// Grounding
    case grounding = "03"

    /// Listing, in danger of capsizing
    case listing = "04"

    /// Sinking
    case sinking = "05"

    /// Disabled and adrift
    case adrift = "06"

    /// Undesignated distress
    case undesignated = "07"

    /// Abandoning ship
    case abandoningShip = "08"

    /// Piracy/armed robbery attack
    case piracy = "09"

    /// Man overboard
    case manOverboard = "10"
  }

  /**
   Desired communications method for subsequent messages, from a ship in
   distress. Defined in ITU-R M.493-16 table A1-3.
  
   - SeeAlso: ``Message/Payload-swift.enum/DSC(format:MMSI:area:category:message1_1:message1_2:message2:message3:distressMMSI:distressMMSINature:acknowledgement:expansion:)``
   */
  public enum DistressCommunicationDesired: String, Sendable, Codable, Equatable {
    /// F3E/G3E All modes TP
    case F3E_G3E_allModesTP = "00"

    /// F3E/G3E duplex TP
    case F3E_G3E_duplexTP = "01"

    /// J3E TP
    case J3E_TP = "09"

    /// F1B/J2B TTY-FEC
    case F1B_J2B_TTY_FEC = "13"

    /// F1B/J2B TTY-ARQ
    case F1B_J2B_TTY_ARQ = "15"
  }

  /**
   DSC first telecommand values, as defined in ITU-R M.493-16 table A1-3.
  
   - SeeAlso: ``Message/Payload-swift.enum/DSC(format:MMSI:area:category:message1_1:message1_2:message2:message3:distressMMSI:distressMMSINature:acknowledgement:expansion:)``
   */
  public enum Telecommand1: String, Sendable, Codable, Equatable {

    /// Polling
    case polling = "03"

    /// Unable to comply
    case unableToComply = "04"

    /// End of call. Only used for automatic service.
    case endOfCall = "05"

    /// Data
    case data = "06"

    /// Distress acknowledgement
    case distressAcknowledge = "10"

    /// Distress alert relay
    case distressRelay = "12"

    /// Test
    case test = "18"

    /// Ship position or location registration updating
    case updating = "21"

    /// No information
    case noInfo = "26"
  }

  /**
   DSC second telecommand values, as defined in ITU-R M.493-16 table A1-3.
  
   - SeeAlso: ``Message/Payload-swift.enum/DSC(format:MMSI:area:category:message1_1:message1_2:message2:message3:distressMMSI:distressMMSINature:acknowledgement:expansion:)``
   */
  public enum Telecommand2: RawRepresentable, Sendable, Codable, Equatable {
    public typealias RawValue = String

    /// No reason given (used only with ``DSC/Telecommand1/unableToComply``)
    case noReason

    /// Congestion at maritime switching centre
    case switchingCongestion

    /// Busy (used only with ``DSC/Telecommand1/unableToComply``)
    case busy

    /// Queue indication (used only with
    /// ``DSC/Telecommand1/unableToComply``)
    case queue

    /// Station barred (used only with ``DSC/Telecommand1/unableToComply``)
    case barred

    /// No operator available (used only with
    /// ``DSC/Telecommand1/unableToComply``)
    case noOperator

    /// Operator temporarily unavailable (used only with
    /// ``DSC/Telecommand1/unableToComply``)
    case operatorUnavailable

    /// Equipment disabled (used only with ``DSC/Telecommand1/unableToComply``)
    case disabled

    /// Unable to use proposed channel (used only with
    /// ``DSC/Telecommand1/unableToComply``)
    case unableChannel

    /// Unable to use proposed mode (used only with
    /// ``DSC/Telecommand1/unableToComply``)
    case unableMode

    /// Ships and aircraft of States not parties to an armed conflict (as
    /// specified in Resolution 18 (Rev.WRC-15)
    case nonparticipant

    /// Medical transports (as defined in 1949 Geneva Conventions and
    /// additional Protocols)
    case medical

    /// Pay-phone/public call office
    case payPhone

    /// Facsimile/data according to Rec. ITU-R M.1081
    case facsimile

    /// Number of remaining ACS sequential transmissions
    case remainingTransmissions(_ remaining: Int)

    /// No information
    case noInformation

    public var rawValue: String {
      switch self {
        case .noReason: return "00"
        case .switchingCongestion: return "01"
        case .busy: return "02"
        case .queue: return "03"
        case .barred: return "04"
        case .noOperator: return "05"
        case .operatorUnavailable: return "06"
        case .disabled: return "07"
        case .unableChannel: return "08"
        case .unableMode: return "09"
        case .nonparticipant: return "10"
        case .medical: return "11"
        case .payPhone: return "12"
        case .facsimile: return "13"
        case .noInformation: return "26"
        case .remainingTransmissions(let remaining): return "2\(remaining)"
      }
    }

    public init?(rawValue: String) {
      switch rawValue {
        case "00": self = .noReason
        case "01": self = .switchingCongestion
        case "02": self = .busy
        case "03": self = .queue
        case "04": self = .barred
        case "05": self = .noOperator
        case "06": self = .operatorUnavailable
        case "07": self = .disabled
        case "08": self = .unableChannel
        case "09": self = .unableMode
        case "10": self = .nonparticipant
        case "11": self = .medical
        case "12": self = .payPhone
        case "13": self = .facsimile
        case "20"..."25":
          let remaining = Int(String(rawValue.last!))!
          self = .remainingTransmissions(remaining)
        case "26": self = .noInformation
        default: return nil
      }
    }
  }

  private enum Quadrant: String {
    case northeast = "0"
    case northwest = "1"
    case southeast = "2"
    case southwest = "3"
  }

  /**
   DSC-coded frequency or channel, as defined by ITU-R M.493-16, table A1-5.
  
   - SeeAlso: ``Message/Payload-swift.enum/DSC(format:MMSI:area:category:message1_1:message1_2:message2:message3:distressMMSI:distressMMSINature:acknowledgement:expansion:)``
   */
  public enum FrequencyChannel: RawRepresentable, Sendable, Codable, Equatable {
    public typealias RawValue = String

    /// Frequency value. This should be used for MF, HF equipment except
    /// when using seven-digit frequencies.
    case frequency(_ frequency: Measurement<UnitFrequency>)

    /// The HF/MF working channel number. This should be used for backward
    /// compatibility in receive only mode.
    case channelHF_MF(_ channel: Int)

    /// Only used for Rec. ITU-R M.586 equipment.
    case autoVHF(_ channel: Int)

    /// The VHF working channel number.
    case channelVHF(_ channel: Int)

    public var rawValue: String {
      switch self {
        case .frequency(let frequency):
          let hz = frequency.converted(to: .hertz).value
          if hz <= 2_999_990 {
            return String(format: "4%05.2f", hz / 1000)
          }
          if hz <= 29_999_900 {
            return String(format: "%06.0f", hz / 100)
          }
          fatalError("Frequency uncodable by ITU-R M.493-16")
        case .channelHF_MF(let channel):
          return String(format: "3%05d", channel)
        case .autoVHF(let channel):
          return String(format: "8%05d", channel)
        case .channelVHF(let channel):
          return String(format: "9%05d", channel)
      }
    }

    public init?(rawValue: String) {
      switch rawValue.first {
        case "0", "1", "2":
          guard let freq100 = Int(rawValue) else { return nil }
          let freq = Double(freq100 * 100)
          self = .frequency(.init(value: freq, unit: .hertz))
        case "3":
          guard let chan = Int(rawValue.slice(from: 1)) else {
            return nil
          }
          self = .channelHF_MF(chan)
        case "4":
          guard let freq10 = Double(rawValue.slice(from: 1)) else {
            return nil
          }
          self = .frequency(.init(value: freq10 * 10, unit: .hertz))
        case "8":
          guard let chan = Int(rawValue.slice(from: 1)) else {
            return nil
          }
          self = .autoVHF(chan)
        case "9":
          guard let chan = Int(rawValue.slice(from: 2)) else {
            return nil
          }
          self = .channelVHF(chan)
        default: return nil
      }
    }
  }
}
