class SM1Parser: MessageFormat {
  func canParse(sentence: ParametricSentence) throws -> Bool {
    sentence.delimiter == .parametric && sentence.format == .safetyNETAllShips
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
      ofType: SafetyNET.AllShipsServiceCode.self,
      optional: true
    )
    let presentationCode = try sentence.fields.enumeration(
      at: 7,
      ofType: SafetyNET.PresentationCode.self
    )!

    let receptionTime = try sentence.fields.datetime(ymdhmIndex: (8, 9, 10, 11, 12))!

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

  private func validateAddressCode(_ value: Int, sentence: ParametricSentence) throws -> UInt {
    guard value == 0 || (1...21).contains(value) else {
      throw sentence.fields.fieldError(type: .badNumericValue, index: 13)
    }
    return UInt(value)
  }
}
