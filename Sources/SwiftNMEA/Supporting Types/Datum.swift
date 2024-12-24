import Foundation

/**
 Datums and earth geoids for latitude, longitude, and altitude values.

 - SeeAlso: ``Message/Payload-swift.enum/datumReference(localDatum:latitudeOffset:longitudeOffset:altitudeOffset:referenceDatum:)``
 */
public enum Datum: Sendable, Codable, Equatable {

    /// WGS-84 (World Geodetic System 1984)
    case WGS84

    /// WGS-72 (World Geodetic System 1972)
    case WGS72

    /// SGS-85 (Soviet Geodetic System 1985)
    case SGS85

    /// Parametry Zemli 1990 goda (Параметры Земли 1990 года)
    case PE90

    /**
     Manually entered or user defined offsets.

     - Parameter subdivision: User defined reference character, if any.
     */
    case userDefined(subdivision: Character?)

    /**
     IHO datum code from International Hydrographic Organisation Publication
     S-60, Appendices B and C

     - Parameter code: The IHO datum code.
     - Parameter subdivision: The subdivision code, if the datum defines
       subdivisions.
     */
    case IHO(code: Int, subdivision: Character?)

    public init?(rawValue: String, subdivision: Character? = nil) {
        switch rawValue {
            case "W84": self = .WGS84
            case "W72": self = .WGS72
            case "S85": self = .SGS85
            case "P90": self = .PE90
            case "999": self = .userDefined(subdivision: subdivision)
            default:
                guard let code = Int(rawValue) else { return nil }
                self = .IHO(code: code, subdivision: subdivision)
        }
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let rawValue = try container.decode(String.self, forKey: .datum)
        guard let subdivision = try container.decode(String.self, forKey: .subdivision).first else {
            throw DecodingError.dataCorruptedError(forKey: .subdivision, in: container, debugDescription: "Empty value for 'subdivision'")
        }

        self.init(rawValue: rawValue, subdivision: subdivision)!
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
            case .WGS84:
                try container.encode("W84", forKey: .datum)
            case .WGS72:
                try container.encode("W72", forKey: .datum)
            case .SGS85:
                try container.encode("S85", forKey: .datum)
            case .PE90:
                try container.encode("P90", forKey: .datum)
            case let .userDefined(subdivision):
                try container.encode("999", forKey: .datum)
                try container.encode((subdivision != nil) ? String(subdivision!) : nil,
                                     forKey: .subdivision)
            case let .IHO(code, subdivision):
                try container.encode(String(code), forKey: .datum)
                try container.encode((subdivision != nil) ? String(subdivision!) : nil,
                                     forKey: .subdivision)
        }
    }

    enum CodingKeys: String, CodingKey {
        case datum, subdivision
    }
}
