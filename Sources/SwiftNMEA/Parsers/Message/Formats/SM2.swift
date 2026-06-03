class SM2Parser: MessageFormat {
  func canParse(sentence: ParametricSentence) throws -> Bool {
    sentence.delimiter == .parametric && sentence.format == .safetyNETCoastalWarningArea
  }

  func parse(sentence: ParametricSentence) throws -> Message.Payload? {
    let status = try sentence.fields.enumeration(at: 0, ofType: SafetyNET.MSIStatus.self)!

    let identification = try SafetyNET.MessageIdentification(
      fields: sentence.fields,
      uniqueIndex: 1,
      lesSequenceIndex: 2,
      lesIDIndex: 3
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

    let time = try sentence.fields.datetime(ymdhmIndex: (8, 9, 10, 11, 12))!

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
