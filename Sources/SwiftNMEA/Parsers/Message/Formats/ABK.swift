import Foundation

class ABKParser: MessageFormat {
  func canParse(sentence: ParametricSentence) throws -> Bool {
    sentence.delimiter == .parametric && sentence.format == .AISBroadcastAcknowledgement
  }

  func parse(sentence: ParametricSentence) throws -> Message.Payload? {
    let MMSI = try sentence.fields.int(at: 0, optional: true)
    let channel = try sentence.fields.enumeration(at: 1, ofType: AIS.Channel.self)!
    let messageID = try sentence.fields.string(at: 2)!
    let sequence = try sentence.fields.int(at: 3, optional: true)
    let type = try sentence.fields.enumeration(at: 4, ofType: AIS.AcknowledgementType.self)!

    return .AISBroadcastAcknowledgement(
      MMSI: MMSI,
      channel: channel,
      messageID: messageID,
      sequence: sequence,
      type: type
    )
  }
}
