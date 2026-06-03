import Foundation

class SM2Parser: MessageFormat {
  private var calendar: Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = .gmt
    return calendar
  }

  func canParse(sentence: ParametricSentence) throws -> Bool {
    sentence.delimiter == .parametric && sentence.format == .safetyNETCoastalWarningArea
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
      ofType: SM2.ServiceCode.self,
      optional: true
    )
    let presentationCode = try sentence.fields.enumeration(
      at: 7,
      ofType: SafetyNET.PresentationCode.self
    )!

    let year = try sentence.fields.int(at: 8)!
    let month = try sentence.fields.int(at: 9)!
    let day = try sentence.fields.int(at: 10)!
    let hour = try sentence.fields.int(at: 11)!
    let minute = try sentence.fields.int(at: 12)!
    let components = DateComponents(
      timeZone: .gmt,
      year: year,
      month: month,
      day: day,
      hour: hour,
      minute: minute,
      second: 0
    )
    guard let time = calendar.date(from: components) else {
      throw sentence.fields.lineError(type: .badDate)
    }

    let navareaValue = try sentence.fields.int(at: 13, optional: true)
    var navarea: UInt?
    if let navareaValue {
      guard navareaValue >= 1, navareaValue <= 21 else {
        throw sentence.fields.fieldError(type: .badValue, index: 13)
      }
      navarea = UInt(navareaValue)
    }

    let warningArea = try sentence.fields.character(at: 14, optional: true)
    if let warningArea, !warningArea.isLetter || !warningArea.isUppercase {
      throw sentence.fields.fieldError(type: .badCharacterValue, index: 14)
    }

    let subject = try sentence.fields.enumeration(
      at: 15,
      ofType: SM2.CoastalWarningSubject.self,
      optional: true
    )

    return .safetyNETCoastalWarningArea(
      status: status,
      identification: identification,
      oceanRegion: oceanRegion,
      priority: priority,
      serviceCode: serviceCode,
      presentationCode: presentationCode,
      receptionTime: time,
      warningArea: navarea,
      warningAreaLetter: warningArea.map(String.init),
      subjectIndicator: subject
    )
  }
}
