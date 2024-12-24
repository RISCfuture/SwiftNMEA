import Foundation

// swiftlint:disable:next missing_docs
public struct MSK {
    private init() {}

    /**
     MSK beacon frequency or bit rate, auto or manual mode.
     */
    public enum AutoMeasurement<Unit: Dimension>: Sendable, Codable, Equatable where Unit: Sendable {

        /// Frequency or bit rate is automatically determined.
        case auto(_ value: Measurement<Unit>)

        /// Frequency or bit rate is manually determined.
        case manual(_ value: Measurement<Unit>)

        init(isAuto: Bool, value: () throws -> Measurement<Unit>) throws {
            if isAuto { self = .auto(try value()) }
            else { self = .manual(try value()) }
        }
    }
}
