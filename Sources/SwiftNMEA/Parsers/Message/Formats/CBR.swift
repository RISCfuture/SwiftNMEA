import Foundation
import NMEACommon

class CBRParser: MessageFormat {
  func canParse(sentence: ParametricSentence) throws -> Bool {
    sentence.delimiter == .parametric && sentence.format == .navaidMessageBroadcastRates
  }

  func parse(sentence: ParametricSentence) throws -> Message.Payload? {
    let MMSI = try sentence.fields.int(at: 0)!
    let messageID = try sentence.fields.enumeration(at: 1, ofType: Navaid.MessageID.self)!
    let index = try sentence.fields.int(at: 2)!
    let hourA = try sentence.fields.int(at: 3)!
    let minuteA = try sentence.fields.int(at: 4)!
    let slotA = try sentence.fields.int(at: 5, optional: true)
    let intervalA = try sentence.fields.int(at: 6, optional: true)
    let scheduleType = try sentence.fields.enumeration(at: 7, ofType: Navaid.Schedule.self)!
    let hourB = try sentence.fields.int(at: 8, optional: true)
    let minuteB = try sentence.fields.int(at: 9, optional: true)
    let slotB = try sentence.fields.int(at: 10, optional: true)
    let intervalB = try sentence.fields.int(at: 11, optional: true)
    let sentenceType = try sentence.fields.enumeration(at: 12, ofType: SentenceType.self)!

    let slotConfigA = Navaid.SlotConfiguration(
      hour: hourA,
      minute: minuteA,
      slot: slotA,
      interval: intervalA
    )
    let slotConfigB = zipOptionals(hourB, minuteB).map { hourB, minuteB in
      Navaid.SlotConfiguration(hour: hourB, minute: minuteB, slot: slotB, interval: intervalB)
    }

    return .navaidMessageBroadcastRates(
      MMSI: MMSI,
      message: messageID,
      index: index,
      channelA: slotConfigA,
      scheduleType: scheduleType,
      channelB: slotConfigB,
      type: sentenceType
    )
  }
}
