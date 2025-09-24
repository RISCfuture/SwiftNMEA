import Foundation
import NMEACommon

class DSCParser: MessageFormat {
  func canParse(sentence: ParametricSentence) throws -> Bool {
    sentence.delimiter == .parametric && sentence.format == .DSC
  }

  func parse(sentence: ParametricSentence) throws -> Message.Payload? {
    let format = try sentence.fields.enumeration(at: 0, ofType: DSC.FormatSpecifier.self)!
    let address = try sentence.fields.string(at: 1)!
    let category = try sentence.fields.enumeration(at: 2, ofType: DSC.Category.self)!
    let message1_1 = try sentence.fields.string(at: 3, optional: true)
    let message1_2 = try sentence.fields.string(at: 4, optional: true)
    let message2 = try sentence.fields.string(at: 5, optional: true)
    let message3 = try sentence.fields.string(at: 6, optional: true)
    let distressMMSI = try sentence.fields.int(at: 7, optional: true).map { $0 / 10 }
    let distressNature = try sentence.fields.enumeration(
      at: 8,
      ofType: DSC.DistressNature.self,
      optional: true
    )
    let acknowledgement = try sentence.fields.enumeration(
      at: 9,
      ofType: DSC.Acknowledgement.self,
      optional: true
    )
    let expansion =
      try sentence.fields.bool(at: 10, trueValue: "E", falseValue: "", optional: true) ?? false

    let MMSI: Int?
    let area: GeoArea?
    if format == .geographic {
      MMSI = nil
      area = DSC.geoArea(from: address)

      guard area != nil else {
        throw sentence.fields.fieldError(type: .badNumericValue, index: 1)
      }
    } else {
      MMSI = Int(address).map { $0 / 10 }
      area = nil

      guard MMSI != nil else {
        throw sentence.fields.fieldError(type: .badNumericValue, index: 1)
      }
    }

    return .DSC(
      format: format,
      MMSI: MMSI,
      area: area,
      category: category,
      message1_1: message1_1,
      message1_2: message1_2,
      message2: message2,
      message3: message3,
      distressMMSI: distressMMSI,
      distressMMSINature: distressNature,
      acknowledgement: acknowledgement,
      expansion: expansion
    )
  }
}
