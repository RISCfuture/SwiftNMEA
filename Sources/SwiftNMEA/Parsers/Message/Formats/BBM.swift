import Foundation
import NMEACommon

class BBMParser: MessageFormat {
    private var buffer = SixBitBuffer<Recipient, BufferElement>()

    func canParse(sentence: ParametricSentence) throws -> Bool {
        sentence.delimiter == .encapsulated && sentence.format == .AISBroadcastBinaryMessage
    }

    func parse(sentence: ParametricSentence) throws -> Message.Payload? {
        let totalSentences = try sentence.fields.int(at: 0)!,
            sentenceNumber = try sentence.fields.int(at: 1)!,
            sequentialID = try sentence.fields.int(at: 2)!,
            channel = try sentence.fields.enumeration(at: 3, ofType: AIS.BroadcastChannel.self, optional: true),
            messageID = try sentence.fields.enumeration(at: 4, ofType: AIS.MessageID.self, optional: true),
            data = try sentence.fields.string(at: 5)!,
            fillBits = try sentence.fields.int(at: 6)!

        let recipient = zipOptionals(channel, messageID).map { channel, messageID in
            Recipient(sentence: sentence, channel: channel, messageID: messageID, sequentialID: sequentialID)
        }

        do {
            let element = BufferElement(lastSentence: sentenceNumber,
                                        totalSentences: totalSentences,
                                        encapsulatedData: data,
                                        fillBits: fillBits),
                finished = try buffer.add(element: element, optionallyFor: recipient)

            return try zipOptionals(finished?.0, finished?.1).flatMap { recipient, element in
                try makePayload(recipient: recipient, element: element)
            }
        } catch let error as BBMErrors {
            switch error {
                case .badData:
                    throw sentence.fields.fieldError(type: .badSixBitEncoding, index: 5)
            }
        } catch let error as BufferErrors {
            switch error {
                case .missingRecipient:
                    if channel == nil {
                        throw sentence.fields.fieldError(type: .missingRequiredValue, index: 3)
                    }
                    throw sentence.fields.fieldError(type: .missingRequiredValue, index: 4)
                case .wrongSentenceNumber:
                    throw sentence.fields.fieldError(type: .wrongSentenceNumber, index: 1)
            }
        }
    }

    func flush(talker: Talker?, format: Format?, includeIncomplete: Bool = false) throws -> [any Element] {
        if !includeIncomplete { return [] } // complete messages are flushed upon receipt of the last message

        let flushed = buffer.flush(talker: talker, format: format, includeIncomplete: includeIncomplete)
        return try flushed.compactMap { recipient, element in
            do {
                guard let payload = try makePayload(recipient: recipient, element: element) else { return nil }
                return Message(talker: recipient.talker, format: recipient.format, payload: payload)
            } catch let error as BBMErrors {
                switch error {
                    case .badData:
                        return MessageError(type: .badSixBitEncoding, fieldNumber: 5)
                }
            }
        }
    }

    private func makePayload(recipient: Recipient, element: BufferElement) throws -> Message.Payload? {
        guard let data = element.data else { throw BBMErrors.badData }

        return .AISBroadcastBinaryMessage(sequentialIdentifier: recipient.sequentialID,
                                          channel: recipient.channel,
                                          messageID: recipient.messageID,
                                          data: data)
    }

    private struct Recipient: BufferRecipient {
        let talker: Talker
        let format: Format
        let channel: AIS.BroadcastChannel
        let messageID: AIS.MessageID
        var sequentialID: Int

        init(sentence: ParametricSentence, channel: AIS.BroadcastChannel, messageID: AIS.MessageID, sequentialID: Int) {
            self.talker = sentence.talker
            self.format = sentence.format
            self.channel = channel
            self.messageID = messageID
            self.sequentialID = sequentialID
        }
    }

    private struct BufferElement: SixBitElement {
        var lastSentence: Int
        var totalSentences: Int
        var allSentences = Set<Int>()

        var encapsulatedData: String
        var fillBits: Int

        mutating func append(otherFields _: Self) {
            // no other fields
        }
    }

    private enum BBMErrors: Error {
        case badData
    }
}
