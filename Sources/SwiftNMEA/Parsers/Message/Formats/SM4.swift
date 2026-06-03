import Foundation

class SM4Parser: MessageFormat {
  private var calendar: Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = .gmt
    return calendar
  }

  func canParse(sentence: ParametricSentence) throws -> Bool {
    sentence.delimiter == .parametric && sentence.format == .safetyNETRectangularArea
  }

  func parse(sentence: ParametricSentence) throws -> Message.Payload? {
    let status = try sentence.fields.enumeration(at: 0, ofType: SafetyNET.MSIStatus.self)!

    let uniqueMessageNumberValue = try sentence.fields.int(at: 1)!
    guard uniqueMessageNumberValue >= 0, uniqueMessageNumberValue <= 999_999 else {
      throw sentence.fields.fieldError(type: .badValue, index: 1)
    }
    let lesSequenceNumberValue = try sentence.fields.int(at: 2, optional: true)
    if let lesSequenceNumberValue, lesSequenceNumberValue < 0 {
      throw sentence.fields.fieldError(type: .badValue, index: 2)
    }
    let lesIDValue = try sentence.fields.int(at: 3, optional: true)
    if let lesIDValue, lesIDValue < 0 {
      throw sentence.fields.fieldError(type: .badValue, index: 3)
    }
    let identification = SafetyNET.MessageIdentification(
      uniqueMessageNumber: UInt(uniqueMessageNumberValue),
      lesSequenceNumber: lesSequenceNumberValue.map(UInt.init),
      lesID: lesIDValue.map(UInt.init)
    )

    let oceanRegion = try sentence.fields.enumeration(at: 4, ofType: SafetyNET.OceanRegion.self)!
    let priority = try sentence.fields.enumeration(at: 5, ofType: SafetyNET.Priority.self)!
    let serviceCode = try sentence.fields.enumeration(
      at: 6,
      ofType: SM4.ServiceCode.self,
      optional: true
    )
    let presentationCode = try sentence.fields.enumeration(
      at: 7,
      ofType: SafetyNET.PresentationCode.self
    )!

    let receptionTime = try makeReceptionTime(sentence: sentence)

    let southWestCorner = try sentence.fields.position(
      latitudeIndex: (13, 14),
      longitudeIndex: (15, 16),
      optional: true
    )

    let latitudeExtent = try sentence.fields.measurement(
      at: 17,
      valueType: .integer,
      units: UnitAngle.degrees,
      optional: true
    )
    let longitudeExtent = try sentence.fields.measurement(
      at: 18,
      valueType: .integer,
      units: UnitAngle.degrees,
      optional: true
    )

    return .safetyNETRectangularArea(
      status: status,
      identification: identification,
      oceanRegion: oceanRegion,
      priority: priority,
      serviceCode: serviceCode,
      presentationCode: presentationCode,
      receptionTime: receptionTime,
      southWestCorner: southWestCorner,
      latitudeExtent: latitudeExtent,
      longitudeExtent: longitudeExtent
    )
  }

  private func makeReceptionTime(sentence: ParametricSentence) throws -> Date {
    let year = try sentence.fields.int(at: 8)!
    let month = try sentence.fields.int(at: 9)!
    let day = try sentence.fields.int(at: 10)!
    let hour = try sentence.fields.int(at: 11)!
    let minute = try sentence.fields.int(at: 12)!

    let components = DateComponents(
      calendar: calendar,
      timeZone: .gmt,
      year: year,
      month: month,
      day: day,
      hour: hour,
      minute: minute
    )
    guard components.isValidDate, let date = components.date else {
      throw sentence.fields.lineError(type: .badDate)
    }
    return date
  }
}
