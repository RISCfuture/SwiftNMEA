import Foundation

// swiftlint:disable:next missing_docs
public struct Comm {
  private init() {}

  /**
   A frequency used a communications set.
  
   - SeeAlso: ``Message/Payload-swift.enum/frequencySetInfo(transmit:receive:mode:powerLevel:type:)``
   */
  public enum Frequency: RawRepresentable, Sendable, Codable, Equatable {
    public typealias RawValue = String

    /**
     MH/HF transceiver frequency
    
     - Parameter frequency: Frequency, kHz
     */
    case MF_HF(frequency: Measurement<UnitFrequency>)

    /**
     MF/HF telephone channel
    
     - Parameter channel: ITU channel number
     */
    case MF_HF_telephone(channel: Int)

    /**
     MF/HF teletype channel
    
     - Parameter band: Frequency band
     - Parameter channel: ITU channel number
     */
    case MF_HF_teletype(band: Int, channel: Int)

    /**
     VHF channel
    
     - Parameter mode: The simplex/duplex transceiver mode.
     transmit frequency is being used as a simplex channel frequency
     - Parameter channel: VHF channel number
     */
    case VHF(mode: VHFChannelMode, channel: Int)

    public var rawValue: String {
      switch self {
        case .MF_HF(let frequency):
          let kHz = frequency.converted(to: .kilohertz).value
          guard kHz < 30_000 else { fatalError("Cannot represent frequencies ≥ 30,000 kHz") }
          return String(format: "%06d", (kHz * 10).rounded())
        case .MF_HF_telephone(let channel):
          return String(format: "3%04d", channel)
        case .MF_HF_teletype(let band, let channel):
          return String(format: "4%02d%03d", band, channel)
        case .VHF(let mode, let channel):
          let simplexFlag = String(mode.rawValue)
          return String(format: "90%@%03d", simplexFlag, channel)
      }
    }

    public init?(rawValue: String) {
      guard ("000000"..."999999").contains(rawValue) else { return nil }

      switch rawValue.first {
        case "0", "1", "2":
          let kHz = Double(rawValue)! / 10
          self = .MF_HF(frequency: .init(value: kHz, unit: .kilohertz))
        case "3":
          guard let channel = Int(rawValue.slice(from: 1)) else { return nil }
          self = .MF_HF_telephone(channel: channel)
        case "4":
          guard let band = Int(rawValue.slice(from: 1, to: 2)),
            let channel = Int(rawValue.slice(from: 3))
          else { return nil }
          self = .MF_HF_teletype(band: band, channel: channel)
        case "9":
          guard rawValue[rawValue.index(after: rawValue.startIndex)] == "0" else { return nil }
          let modeStr = rawValue[rawValue.index(rawValue.startIndex, offsetBy: 2)]
          guard let mode = VHFChannelMode(rawValue: modeStr) else { return nil }
          guard let channel = Int(rawValue.slice(from: 3)) else { return nil }
          self = .VHF(mode: mode, channel: channel)
        default:
          return nil
      }
    }
  }

  /**
   VHF transmitter simplex/duplex modes.
   */
  public enum VHFChannelMode: Character, Sendable, Codable, Equatable {

    /// Normal channel behavior (simplex or duplex as defined)
    case standard = "0"

    /// Simplex using ship station’s transmit frequency
    case simplexShipTx = "1"

    /// Simplex using coast station’s transmit frequency
    case simplexCoastTx = "2"
  }

  /**
   Comm radio operation modes.
  
   - SeeAlso: ``Message/Payload-swift.enum/frequencySetInfo(transmit:receive:mode:powerLevel:type:)``
   - SeeAlso: ``Message/Payload-swift.enum/scanningFrequencies(_:)``
   */
  public enum OperationMode: Character, Sendable, Codable, Equatable {

    /// F3E/G3E, simplex, telephone
    case F3E_G3E_simplex = "d"

    /// F3E/G3E, duplex, telephone
    case F3E_G3E_duplex = "e"

    /// J3E, telephone
    case J3E = "m"

    /// H3E, telephone
    case H3E = "o"

    /// F1B/J2B FEC NBDP, telex/teleprinter
    case F1B_J2B_FEC_NBDP = "q"

    /// F1B/J2B ARQ NBDP, telex/teleprinter
    case F1B_J2B_ARQ_NBDP = "s"

    /// F1B/J2B, receive only, teleprinter/DSC
    case F1B_J2B_receive = "t"

    /// F1B/J2B, teleprinter/DSC
    case F1B_J2B = "w"

    /// case A1A Morse, tape recorder
    case A1A_recorder = "x"

    /// case A1A Morse, Morse key/head set
    case A1A_key = "{"

    /// case F1C/F2C/F3C, facsimile machine
    case F1C_F2C_F3C = "|"
  }

  /**
   A comm frequency and optional operation mode.
  
   - SeeAlso: ``Message/Payload-swift.enum/scanningFrequencies(_:)``
   */
  public struct FrequencyMode: Sendable, Codable, Equatable {

    /// Frequency or ITU channel
    public let frequency: Frequency

    /// Mode of operation
    public let mode: OperationMode?
  }
}
