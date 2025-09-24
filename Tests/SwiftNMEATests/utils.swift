import Algorithms
import Foundation

@testable import SwiftNMEA

func applyChecksum(to sentence: String) -> String {
  let delimiter = sentence.first!
  let rest = sentence.slice(from: 1)
  let checksum = calculateChecksum(for: rest)
  let checksumStr = String(format: "%02X", checksum)
  return "\(delimiter)\(rest)*\(checksumStr)\r\n"
}

func createSentence(delimiter: Delimiter, talker: Talker, format: Format, fields: [Any?]) -> String
{
  let strFields = fields.map { $0 == nil ? "" : String(describing: $0!) }
  let sentence = ParametricSentence(
    delimiter: delimiter,
    talker: talker,
    format: format,
    fields: strFields
  )
  return sentence.rawValue
}

let calendar: Calendar = {
  var c = Calendar(identifier: .gregorian)
  c.timeZone = .gmt
  return c
}()

func encapsulatedSentences(
  format: Format,
  from chunks: [String],
  fillBits: UInt8,
  sequenceID: Int,
  otherFields: [Any?],
  hex: Bool = false
) -> [String] {
  let totalSentences = String(format: hex ? "%02X" : "%d", chunks.count)

  return chunks.enumerated().map { index, chunk in
    let lastSentence = String(format: hex ? "%02X" : "%d", index + 1)
    return if index == 0 {
      createSentence(
        delimiter: .encapsulated,
        talker: .commVHF,
        format: format,
        fields: [totalSentences, lastSentence, sequenceID] + otherFields + [chunk, fillBits]
      )
    } else {
      createSentence(
        delimiter: .encapsulated,
        talker: .commVHF,
        format: format,
        fields: [totalSentences, lastSentence, sequenceID]
          + Array(repeating: nil, count: otherFields.count) + [chunk, fillBits]
      )
    }
  }
}
