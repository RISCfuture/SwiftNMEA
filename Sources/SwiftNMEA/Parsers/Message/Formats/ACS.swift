import Foundation

class ACSParser: MessageFormat {
  func canParse(sentence: ParametricSentence) throws -> Bool {
    sentence.delimiter == .parametric && sentence.format == .AISChannelInformationSource
  }

  func parse(sentence: ParametricSentence) throws -> Message.Payload? {
    let sequenceNumber = try sentence.fields.int(at: 0)!
    let MMSI = try sentence.fields.int(at: 1)!
    let time = try sentence.fields.datetime(ymdIndex: (3, 4, 5), hmsDecimalIndex: 2)!

    return .AISChannelInformationSource(sequenceNumber: sequenceNumber, MMSI: MMSI, time: time)
  }
}
