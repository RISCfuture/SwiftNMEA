import Foundation

class ACSParser: MessageFormat {
  func canParse(sentence: ParametricSentence) throws(NMEAError) -> Bool {
    sentence.delimiter == .parametric && sentence.format == .AISChannelInformationSource
  }

  func parse(sentence: ParametricSentence) throws(NMEAError) -> Message.Payload? {
    let sequenceNumber = try sentence.fields.int(at: 0)!
    let MMSI = try sentence.fields.int(at: 1)!
    let time = try sentence.fields.datetime(ymdIndex: (5, 4, 3), hmsDecimalIndex: 2)!

    return .AISChannelInformationSource(sequenceNumber: sequenceNumber, MMSI: MMSI, time: time)
  }
}
