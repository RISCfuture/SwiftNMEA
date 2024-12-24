import Collections
import Foundation
import NMEAUnits

class ZDAParser: MessageFormat {
    func canParse(sentence: ParametricSentence) throws -> Bool {
        sentence.delimiter == .parametric && sentence.format == .dateTime
    }

    func parse(sentence: ParametricSentence) throws -> Message.Payload? {
        let tzHours = try sentence.fields.int(at: 4)!,
            tzMinutes = try sentence.fields.int(at: 5)!,
            tzSeconds = (abs(tzHours) * 60 * 60 + tzMinutes * 60) * tzHours.signum()
        guard let timeZone = TimeZone(secondsFromGMT: -tzSeconds) else {
            throw sentence.fields.fieldError(type: .badValue, index: 4)
        }

        let date = try sentence.fields.datetime(ymdIndex: (3, 2, 1), hmsDecimalIndex: 0)!

        return .dateTime(date, timeZone: timeZone)
    }
}
