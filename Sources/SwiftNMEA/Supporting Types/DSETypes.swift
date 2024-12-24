// swiftlint:disable:next missing_docs
public struct DSE {
    private init() {}

    /**
     Possible message types for a `DSE` message.

     - SeeAlso: ``Message/Payload-swift.enum/DSE(type:MMSI:data:)``
     */
    public enum MessageType: Character, Sendable, Codable, Equatable {
        /// A device is requesting expanded data. Code fields filled as desired, all
        /// data fields null.
        case query = "Q"

        /// A device is responding with selected expanded data, in response to a
        /// query.
        case reply = "R"

        /// A device is transmitting data automatically, not in response to a query
        /// request.
        case automatic = "A"
    }
}
