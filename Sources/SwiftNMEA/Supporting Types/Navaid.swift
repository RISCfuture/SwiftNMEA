import Foundation

// swiftlint:disable:next missing_docs
public struct Navaid {
  private init() {}

  /**
   Possible actions for a `CBR` message broadcast configuration.
  
   - SeeAlso: ``Message/Payload-swift.enum/navaidMessageBroadcastRates(MMSI:message:index:channelA:scheduleType:channelB:type:)``
   */
  public enum SlotConfiguration: Sendable, Codable, Equatable {

    /**
     Begin transmitting AIS Class A message 26 on this channel with this
     slot configuration. Nominal start slot for each channel is determined
     by the combination of Start UTC hour, Start UTC minute, and Start slot.
    
     - Parameter start: The hour and minute. All other components are `nil`.
     - Parameter slot: Starting slot. Valid range is 0 to 2249.
     - Parameter interval: Message transmission slot interval. Valid range
       is 0 to 3,240,000 slots (24*60*2 250 = 3,240,000 is once per day).
     */
    case start(start: DateComponents, slot: Change, interval: Change)
    case discontinue

    init(hour: Int, minute: Int, slot slotNum: Int?, interval intervalNum: Int?) {
      if slotNum == -1 {
        self = .discontinue
        return
      }
      let start = DateComponents(hour: hour, minute: minute)
      let slot = (slotNum == nil) ? Change.noChange : Change.set(slotNum!)
      let interval = (intervalNum == nil) ? Change.noChange : Change.set(intervalNum!)
      self = .start(start: start, slot: slot, interval: interval)
    }

    /// A broadcast slot/interval configuration, or response to a broadcast \
    /// slot/interval query.
    public enum Change: Sendable, Codable, Equatable {

      /**
       For configuration sentences: Set the slot or interval to this
       value.
      
       For query responses: The slot or interval is configured to this
       value.
       */
      case set(_ value: Int)

      /**
       For configuration sentences: Do not change the slot or interval.
      
       Not allowed for query responses.
       */
      case noChange

      /**
       For configuration sentences: Clear the slot or interval
       configuration.
      
       For query responses: No slot or interval is configured.
       */
      case clear
    }
  }

  /**
   Whether the CBR is configuring a FATDMA schedule or RATDMA/CSTDMA schedule.
  
   - SeeAlso: ``Message/Payload-swift.enum/navaidMessageBroadcastRates(MMSI:message:index:channelA:scheduleType:channelB:type:)``
   */
  public enum Schedule: Int, Sendable, Codable, Equatable {
    case FATDMA = 0
    case RATDMA = 1
    case CSTDMA = 2
  }

  /**
   The number of the message being scheduled (See ITU-R M.1371).
  
   - SeeAlso: ``Message/Payload-swift.enum/navaidMessageBroadcastRates(MMSI:message:index:channelA:scheduleType:channelB:type:)``
   */
  public enum MessageID: RawRepresentable, Sendable, Codable, Equatable, Hashable {
    public typealias RawValue = Int

    /// A message by ID.
    case messageID(_ id: AIS.MessageID)

    /// The slots being defined will be used for either chaining messages or
    /// MEB single transmissions (See IEC 62320-2).
    case chain

    public var rawValue: Int {
      switch self {
        case .messageID(let id): return id.rawValue
        case .chain: return 0
      }
    }

    public init?(rawValue: Int) {
      switch rawValue {
        case 0: self = .chain
        default:
          guard let id = AIS.MessageID(rawValue: rawValue) else { return nil }
          self = .messageID(id)
      }
    }
  }
}
