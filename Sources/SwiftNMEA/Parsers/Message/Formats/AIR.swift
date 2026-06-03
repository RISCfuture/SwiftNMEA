import Foundation

class AIRParser: MessageFormat {
  func canParse(sentence: ParametricSentence) throws -> Bool {
    sentence.delimiter == .parametric && sentence.format == .AISInterrogationRequest
  }

  func parse(sentence: ParametricSentence) throws -> Message.Payload? {
    let MMSI1 = try sentence.fields.int(at: 0)!
    let messageNumber1_1 = try sentence.fields.int(at: 1)!
    let subsection1_1 = try sentence.fields.int(at: 2, optional: true)
    let messageNumber1_2 = try sentence.fields.int(at: 3, optional: true)
    let subsection1_2 = try sentence.fields.int(at: 4, optional: true)
    let MMSI2 = try sentence.fields.int(at: 5, optional: true)
    let messageNumber2 = try sentence.fields.int(at: 6, optional: true)
    let subsection2 = try sentence.fields.int(at: 7, optional: true)
    let channel = try sentence.fields.enumeration(at: 8, ofType: AIS.Channel.self, optional: true)
    let replySlot1_1 = try sentence.fields.int(at: 9, optional: true)
    let replySlot1_2 = try sentence.fields.int(at: 10, optional: true)
    let replySlot2 = try sentence.fields.int(at: 11, optional: true)

    let request1_1 = AIS.MessageRequest(
      number: messageNumber1_1,
      subsection: subsection1_1,
      replySlot: replySlot1_1
    )

    let request1_2: AIS.MessageRequest?
    if let messageNumber1_2 {
      request1_2 = .init(
        number: messageNumber1_2,
        subsection: subsection1_2,
        replySlot: replySlot1_2
      )
    } else {
      // Second message number for station 1 is absent: its sub-section and
      // reply slot fields shall be absent too.
      if subsection1_2 != nil {
        throw sentence.fields.fieldError(type: .missingRequiredValue, index: 3)
      }
      if replySlot1_2 != nil {
        throw sentence.fields.fieldError(type: .missingRequiredValue, index: 3)
      }
      request1_2 = nil
    }

    let request2: AIS.MessageRequest?
    if let messageNumber2 {
      request2 = .init(number: messageNumber2, subsection: subsection2, replySlot: replySlot2)
    } else {
      // Station 2 message number is absent: its sub-section and reply slot
      // fields shall be absent too.
      if subsection2 != nil {
        throw sentence.fields.fieldError(type: .missingRequiredValue, index: 6)
      }
      if replySlot2 != nil {
        throw sentence.fields.fieldError(type: .missingRequiredValue, index: 6)
      }
      request2 = nil
    }

    return .AISInterrogationRequest(
      station1: MMSI1,
      station1Request1: request1_1,
      station1Request2: request1_2,
      station2: MMSI2,
      station2Request: request2,
      channel: channel
    )
  }
}
