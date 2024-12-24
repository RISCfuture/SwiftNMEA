import Foundation
import NMEACommon

class VDOParser: MessageFormat {
    private var buffer = SixBitBuffer<Recipient, BufferElement>()

    func canParse(sentence: ParametricSentence) throws -> Bool {
        sentence.delimiter == .encapsulated && sentence.format == .VDLOwnshipReport
    }

    func parse(sentence: ParametricSentence) throws -> Message.Payload? {
        let totalSentences = try sentence.fields.int(at: 0)!,
            sentenceNumber = try sentence.fields.int(at: 1)!,
            sequentialID = try sentence.fields.int(at: 2, optional: true),
            channel = try sentence.fields.enumeration(at: 3, ofType: AIS.Channel.self, optional: true),
            data = try sentence.fields.string(at: 4)!,
            fillBits = try sentence.fields.int(at: 5)!

        let recipient = Recipient(sentence: sentence, sequentialID: sequentialID)

        do {
            let element = BufferElement(lastSentence: sentenceNumber,
                                        totalSentences: totalSentences,
                                        channel: channel,
                                        encapsulatedData: data,
                                        fillBits: fillBits),
                finished = try buffer.add(element: element, optionallyFor: recipient)

            return try zipOptionals(finished?.0, finished?.1).flatMap { recipient, element in
                try makePayload(recipient: recipient, element: element)
            }
        } catch let error as VDOErrors {
            switch error {
                case .badData:
                    throw sentence.fields.fieldError(type: .badSixBitEncoding, index: 4)
            }
        } catch let error as BufferErrors {
            switch error {
                case .missingRecipient:
                fatalError("Unexpected missingRecipient error")
                case .wrongSentenceNumber:
                    throw sentence.fields.fieldError(type: .wrongSentenceNumber, index: 1)
            }
        }
    }

    func flush(talker: Talker?, format: Format?, includeIncomplete: Bool) throws -> [any Element] {
        if !includeIncomplete { return [] } // complete messages are flushed upon receipt of the last message

        let flushed = buffer.flush(talker: talker, format: format, includeIncomplete: includeIncomplete)
        return try flushed.compactMap { recipient, element in
            do {
                guard let payload = try makePayload(recipient: recipient, element: element) else { return nil }
                return Message(talker: recipient.talker, format: recipient.format, payload: payload)
            } catch let error as VDOErrors {
                switch error {
                    case .badData:
                        return MessageError(type: .badSixBitEncoding, fieldNumber: 4)
                }
            }
        }
    }

    private func makePayload(recipient _: Recipient, element: BufferElement) throws -> Message.Payload? {
        guard let data = element.data else { throw VDOErrors.badData }
        return .VDLOwnshipReport(data, channel: element.channel)
    }

    private struct Recipient: BufferRecipient {
        let talker: Talker
        let format: Format
        let sequentialID: Int?

        init(sentence: ParametricSentence, sequentialID: Int?) {
            self.talker = sentence.talker
            self.format = sentence.format
            self.sequentialID = sequentialID
        }
    }

    private struct BufferElement: SixBitElement {
        var lastSentence: Int
        var totalSentences: Int
        var allSentences = Set<Int>()

        // other fields
        let channel: AIS.Channel?

        // sixBit
        var encapsulatedData: String
        var fillBits: Int

        mutating func append(otherFields _: Self) {
            // no other fields to update
        }
    }

    private enum VDOErrors: Error {
        case badData
    }
}
