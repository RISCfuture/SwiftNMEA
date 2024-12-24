// swiftlint:disable:next missing_docs
public struct EngineTelegraph {
    private init() {}

    /**
     Possible `ETL` message types.

     - SeeAlso: ``Message/Payload-swift.enum/engineTelegraph(time:type:position:subPosition:location:number:)``
     */
    public enum MessageType: Character, Sendable, Codable, Equatable {

        /// Order
        case order = "O"

        /// Answer-back
        case answerBack = "A"
    }

    /**
     Possible engine telegraph positions.

     - SeeAlso: ``Message/Payload-swift.enum/engineTelegraph(time:type:position:subPosition:location:number:)``
     */
    public enum Position: String, Sendable, Codable, Equatable {

        /// Stop engine
        case stop = "00"

        /// [AH] Dead slow
        case aheadDeadSlow = "01"

        /// [AH] Slow
        case aheadSlow = "02"

        /// [AH] Half
        case aheadHalf = "03"

        /// [AH] Full
        case aheadFull = "04"

        /// [AH] Nav. Full
        case aheadNavFull = "05"

        /// [AS] Dead slow
        case asternDeadSlow = "11"

        /// [AS] Slow
        case asternSlow = "12"

        /// [AS] Half
        case asternHalf = "13"

        /// [AS] Full
        case asternFull = "14"

        /// [AS] Crash astern
        case asternCrash = "15"

        /// The commanded direction of the engine telegraph position.
        public var direction: Direction {
            switch self {
                case .stop:
                    .stop
                case .aheadDeadSlow, .aheadSlow, .aheadHalf, .aheadFull, .aheadNavFull:
                    .ahead
                case .asternDeadSlow, .asternSlow, .asternHalf, .asternFull, .asternCrash:
                    .astern
            }
        }

        /// Possible telegraph position direction commands.
        public enum Direction {
            case ahead, astern, stop
        }
    }

    /**
     Possible engine sub-telegraph positions.

     - SeeAlso: ``Message/Payload-swift.enum/engineTelegraph(time:type:position:subPosition:location:number:)``
     */
    public enum SubPosition: String, Sendable, Codable, Equatable {

        /// S/B (Stand-by engine)
        case standby = "20"

        /// F/A (Full away – Navigation full)
        case fullAway = "30"

        /// F/E (Finish with engine)
        case finish = "40"
    }
}
