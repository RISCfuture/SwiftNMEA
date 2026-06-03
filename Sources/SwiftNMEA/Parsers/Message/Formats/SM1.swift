import Foundation

class SM1Parser: MessageFormat {
  func canParse(sentence: ParametricSentence) throws -> Bool {
    sentence.delimiter == .parametric && sentence.format == .safetyNETAllShips
  }

  func parse(sentence: ParametricSentence) throws -> Message.Payload? {
    let status = try sentence.fields.enumeration(at: 0, ofType: SafetyNET.MSIStatus.self)!

    let uniqueMessageNumberInt = try sentence.fields.int(at: 1)!
    guard uniqueMessageNumberInt >= 0, uniqueMessageNumberInt <= 999_999 else {
      throw sentence.fields.fieldError(type: .badNumericValue, index: 1)
    }
    let uniqueMessageNumber = UInt(uniqueMessageNumberInt)

    let lesSequenceNumber = try sentence.fields.int(at: 2, optional: true).map { value -> UInt in
      guard let unsigned = UInt(exactly: value) else {
        throw sentence.fields.fieldError(type: .badNumericValue, index: 2)
      }
      return unsigned
    }
    let lesID = try sentence.fields.int(at: 3, optional: true).map { value -> UInt in
      guard let unsigned = UInt(exactly: value) else {
        throw sentence.fields.fieldError(type: .badNumericValue, index: 3)
      }
      return unsigned
    }
    let identification = SafetyNET.MessageIdentification(
      uniqueMessageNumber: uniqueMessageNumber,
      lesSequenceNumber: lesSequenceNumber,
      lesID: lesID
    )

    let oceanRegion = try sentence.fields.enumeration(at: 4, ofType: SafetyNET.OceanRegion.self)!
    let priority = try sentence.fields.enumeration(at: 5, ofType: SafetyNET.Priority.self)!
    let serviceCode = try sentence.fields.enumeration(
      at: 6,
      ofType: SafetyNET.AllShipsServiceCode.self,
      optional: true
    )
    let presentationCode = try sentence.fields.enumeration(
      at: 7,
      ofType: SafetyNET.PresentationCode.self
    )!

    let receptionTime = try makeReceptionTime(sentence: sentence)

    let addressCode = try sentence.fields.int(at: 13, optional: true).map { value -> UInt in
      try validateAddressCode(value, sentence: sentence)
    }

    return .safetyNETAllShips(
      status: status,
      identification: identification,
      oceanRegion: oceanRegion,
      priority: priority,
      serviceCode: serviceCode,
      presentationCode: presentationCode,
      receptionTime: receptionTime,
      addressCode: addressCode
    )
  }

  private func makeReceptionTime(sentence: ParametricSentence) throws -> Date {
    let year = try sentence.fields.int(at: 8)!
    let month = try sentence.fields.int(at: 9)!
    let day = try sentence.fields.int(at: 10)!
    let hour = try sentence.fields.int(at: 11)!
    let minute = try sentence.fields.int(at: 12)!

    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = .gmt
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

  private func validateAddressCode(_ value: Int, sentence: ParametricSentence) throws -> UInt {
    guard value == 0 || (1...21).contains(value) else {
      throw sentence.fields.fieldError(type: .badNumericValue, index: 13)
    }
    return UInt(value)
  }
}
