import Collections
import Foundation
import NMEAUnits

class VSDParser: MessageFormat {
    func canParse(sentence: ParametricSentence) throws -> Bool {
        sentence.delimiter == .parametric && sentence.format == .AISVoyageData
    }

    func parse(sentence: ParametricSentence) throws -> Message.Payload? {
        let shipType = try sentence.fields.enumeration(at: 0, ofType: AISLongRange.ShipType.self, optional: true),
            maxDraughtValue = try sentence.fields.measurement(at: 1, valueType: .float, units: UnitLength.meters, optional: true),
            soulsOnboardValue = try sentence.fields.int(at: 2, optional: true),
            destinationValue = try sentence.fields.string(at: 3, optional: true),
            timeStr = try sentence.fields.string(at: 4, optional: true),
            dayValue = try sentence.fields.int(at: 5, optional: true),
            monthValue = try sentence.fields.int(at: 6, optional: true),
            navStatus = try sentence.fields.enumeration(at: 7, ofType: AIS.NavigationalStatus.self, optional: true),
            regionalFlags = try sentence.fields.int(at: 8, optional: true)

        let maxDraught = AIS.Availability(maxDraughtValue) { $0.value == 0 },
            soulsOnboard = AIS.Availability(soulsOnboardValue, placeholder: 0),
            destination = AIS.Availability(destinationValue, placeholder: "@@@@@@@@@@@@@@@@@@@@")

        let month = AIS.Availability(monthValue, placeholder: 0),
            day = AIS.Availability(dayValue, placeholder: 0),
            hourValue = timeStr.flatMap { Int($0.slice(from: 0, to: 1)) },
            minuteValue = timeStr.flatMap { Int($0.slice(from: 2, to: 3)) },
            hour = AIS.Availability(hourValue, placeholder: 24),
            minute = AIS.Availability(minuteValue, placeholder: 60),
            destinationETA = AIS.DateAvailability(month: month, day: day, hour: hour, minute: minute)

        return .AISVoyageData(shipType: shipType,
                              maxDraft: maxDraught,
                              soulsOnboard: soulsOnboard,
                              destination: destination,
                              destinationETA: destinationETA,
                              navStatus: navStatus,
                              regionalFlags: regionalFlags)
    }
}
