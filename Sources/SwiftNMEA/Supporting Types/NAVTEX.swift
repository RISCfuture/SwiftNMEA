import Collections
import Foundation

// swiftlint:disable:next missing_docs
public struct NAVTEX {
  private init() {}

  /**
   Possible function codes. The function code is used to further identify the
   purpose of the `NRM` sentence.
  
   - SeeAlso: ``Message/Payload-swift.enum/NAVTEXReceiverMask(function:frequency:coverageAreaMask:messageTypeMask:status:)``
   */
  public enum FunctionCode: Int, Sendable, Codable, Equatable {

    /// Request messages for the given mask
    case request = 0

    /// Set/report the storage mask
    case storage = 1

    /// Set/report the printer mask
    case printer = 2

    /// Set/report the INS mask
    case INS = 3
  }

  /**
   A frequency that a NAVTEX message was received on.
  
   - SeeAlso: ``Message/Payload-swift.enum/NAVTEXReceiverMask(function:frequency:coverageAreaMask:messageTypeMask:status:)``
   - SeeAlso: ``Message/Payload-swift.enum/NAVTEXMessage(_:id:frequency:code:time:totalCharacters:badCharacters:isValid:)``
   */
  public enum Frequency: Int, Sendable, Codable, Equatable {

    /// 490 kHz
    case freq490 = 1

    /// 518 kHz
    case freq518 = 2

    /// 4 209,5 kHz
    case freq4209_5 = 3

    /// The frequency, as a measurement.
    public var measurement: Measurement<UnitFrequency> {
      switch self {
        case .freq490: return .init(value: 490, unit: .kilohertz)
        case .freq518: return .init(value: 518, unit: .kilohertz)
        case .freq4209_5: return .init(value: 4209.5, unit: .kilohertz)
      }
    }
  }

  /**
   A coverage area or message type mask, with boolean values in slots named
   `A` through `Z`.
  
   - SeeAlso: ``Message/Payload-swift.enum/NAVTEXReceiverMask(function:frequency:coverageAreaMask:messageTypeMask:status:)``
   */
  public struct Mask: RawRepresentable, Sendable, Codable, Equatable {
    public typealias RawValue = String

    private var coverage: BitArray

    /// The mask, represented as a hexadecimal string.
    public var rawValue: String {
      String(format: "%X", coverage.int32Value)
    }

    init() {
      coverage = BitArray(repeating: false, count: 26)
    }

    /**
     Creates a mask from a hexadecimal string.
    
     - Parameter rawValue: The hexadecimal string.
     */
    public init?(rawValue: String) {
      guard let intValue = UInt32(rawValue, radix: 16) else { return nil }
      coverage = BitArray(int32Value: intValue)
    }

    private func offset(for character: Character) -> Int? {
      guard ("A"..."Z").contains(character) else { return nil }
      return Int(character.asciiValue! - Character("A").asciiValue!)
    }

    /**
     Gets a mask element by its slot name.
    
     - Parameter index: The named slot, `A` to `Z`.
     */
    public subscript(index: Character) -> Bool {
      get { coverage[offset(for: index)!] }
      set { coverage[offset(for: index)!] = newValue }
    }

    /**
     Gets a mask element by its index.
    
     - Parameter index: The slot index, 0 through 25.
     */
    public subscript(index: Int) -> Bool {
      get { coverage[index] }
      set { coverage[index] = newValue }
    }
  }
}
