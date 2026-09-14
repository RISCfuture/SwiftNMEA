import Foundation
import NMEAUnits

class MSKParser: MessageFormat {
  func canParse(sentence: ParametricSentence) throws(NMEAError) -> Bool {
    sentence.delimiter == .parametric && sentence.format == .MSKReceiverInterface
  }

  func parse(sentence: ParametricSentence) throws(NMEAError) -> Message.Payload? {
    let frequencyAuto = try sentence.fields.bool(at: 1, trueValue: "A", falseValue: "M")!
    let bitRateAuto = try sentence.fields.bool(at: 3, trueValue: "A", falseValue: "M")!
    let interval = try sentence.fields.measurement(
      at: 4,
      valueType: .float,
      units: UnitDuration.seconds,
      optional: true
    )
    let channel = try sentence.fields.int(at: 5, optional: true)
    let status = try sentence.fields.enumeration(at: 6, ofType: SentenceType.self)!

    let frequency = MSK.AutoMeasurement(
      isAuto: frequencyAuto,
      value: try sentence.fields.measurement(
        at: 0,
        valueType: .float,
        units: UnitFrequency.kilohertz
      )!
    )
    let bitRate = MSK.AutoMeasurement(
      isAuto: bitRateAuto,
      value: try sentence.fields.measurement(
        at: 2,
        valueType: .float,
        units: UnitInformationTransferRate.bitsPerSecond
      )!
    )

    return .MSKReceiverInterface(
      frequency: frequency,
      bitRate: bitRate,
      statusInterval: interval,
      channel: channel,
      status: status
    )
  }
}
