import Foundation

class SM3Parser: MessageFormat {
  func canParse(sentence: ParametricSentence) throws -> Bool {
    sentence.delimiter == .parametric && sentence.format == .safetyNETCircularArea
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
      ofType: SM3.ServiceCode.self,
      optional: true
    )
    let presentationCode = try sentence.fields.enumeration(
      at: 7,
      ofType: SafetyNET.PresentationCode.self
    )!

    let receptionTime = try sentence.fields.datetime(ymdhmIndex: (8, 9, 10, 11, 12))!

    let centre = try sentence.fields.position(
      latitudeIndex: (13, 14),
      longitudeIndex: (15, 16),
      optional: true
    )
    let radius = try sentence.fields.measurement(
      at: 17,
      valueType: .float,
      units: UnitLength.nauticalMiles,
      optional: true
    )

    return .safetyNETCircularArea(
      status: status,
      identification: identification,
      oceanRegion: oceanRegion,
      priority: priority,
      serviceCode: serviceCode,
      presentationCode: presentationCode,
      receptionTime: receptionTime,
      centre: centre,
      radius: radius
    )
  }
}
