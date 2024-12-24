import Foundation
import NMEACommon

class MEBParser: MessageFormat {
    private var buffer = SixBitBuffer<Recipient, BufferElement>()

    func canParse(sentence: ParametricSentence) throws -> Bool {
        sentence.delimiter == .encapsulated && sentence.format == .broadcastCommandMessage
    }

    func parse(sentence: ParametricSentence) throws -> Message.Payload? {
        let totalSentences = try sentence.fields.int(at: 0)!,
            sentenceNumber = try sentence.fields.int(at: 1)!,
            sequentialID = try sentence.fields.int(at: 2)!,
            channel = try sentence.fields.enumeration(at: 3, ofType: AIS.BroadcastChannel.self, optional: true),
            MMSI = try sentence.fields.int(at: 4, optional: true),
            messageID = try sentence.fields.enumeration(at: 5, ofType: AIS.MessageID.self, optional: true),
            messageIndex = try sentence.fields.int(at: 6, optional: true),
            behavior = try sentence.fields.enumeration(at: 7, ofType: AIS.BroadcastBehavior.self, optional: true),
            destMMSI = try sentence.fields.int(at: 8, optional: true),
            dataFlag = try sentence.fields.enumeration(at: 9, ofType: AIS.BinaryDataStructure.self, optional: true),
            sentenceType = try sentence.fields.enumeration(at: 10, ofType: SentenceType.self, optional: true),
            data = try sentence.fields.string(at: 11)!,
            fillBits = try sentence.fields.int(at: 12)!

        let recipient = zipOptionals(MMSI, messageID).map { MMSI, messageID in
            Recipient(sentence: sentence, MMSI: MMSI, channel: channel, messageID: messageID, sequentialID: sequentialID)
        }

        do {
            let element = BufferElement(lastSentence: sentenceNumber,
                                        totalSentences: totalSentences,
                                        AISChannel: channel,
                                        MMSI: MMSI,
                                        messageID: messageID,
                                        messageIndex: messageIndex,
                                        broadcastBehavior: behavior,
                                        destinationMMSI: destMMSI,
                                        binaryStructure: dataFlag,
                                        sentenceType: sentenceType,
                                        encapsulatedData: data,
                                        fillBits: fillBits),
                finished = try buffer.add(element: element, optionallyFor: recipient)

            return try zipOptionals(finished?.0, finished?.1).flatMap { recipient, element in
                try makePayload(recipient: recipient, element: element, sentence: sentence.rawValue)
            }
        } catch let error as MEBErrors {
            switch error {
                case .badData:
                    throw sentence.fields.fieldError(type: .badSixBitEncoding, index: 11)
            }
        } catch let error as BufferErrors {
            switch error {
                case .missingRecipient:
                    if MMSI == nil {
                        throw sentence.fields.fieldError(type: .missingRequiredValue, index: 4)
                    }
                    throw sentence.fields.fieldError(type: .missingRequiredValue, index: 5)
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
            } catch let error as MEBErrors {
                switch error {
                    case .badData:
                        return MessageError(type: .badSixBitEncoding, fieldNumber: 11)
                }
            } catch let error as NMEAError {
                return MessageError(from: error)
            }
        }
    }

    private func makePayload(recipient: Recipient, element: BufferElement, sentence: String? = nil) throws -> Message.Payload? {
        guard let AISChannel = element.AISChannel else { throw NMEAError(type: .missingRequiredValue, line: sentence, fieldNumber: 3) }
        guard let MMSI = element.MMSI else { throw NMEAError(type: .missingRequiredValue, line: sentence, fieldNumber: 4) }
        guard let messageID = element.messageID else { throw NMEAError(type: .missingRequiredValue, line: sentence, fieldNumber: 5) }
        guard let messageIndex = element.messageIndex else { throw NMEAError(type: .missingRequiredValue, line: sentence, fieldNumber: 6) }
        guard let broadcastBehavior = element.broadcastBehavior else { throw NMEAError(type: .missingRequiredValue, line: sentence, fieldNumber: 7) }
        guard let binaryStructure = element.binaryStructure else { throw NMEAError(type: .missingRequiredValue, line: sentence, fieldNumber: 9) }
        guard let sentenceType = element.sentenceType else { throw NMEAError(type: .missingRequiredValue, line: sentence, fieldNumber: 10) }
        guard let data = element.data else { throw MEBErrors.badData }

        return .broadcastMessage(sequence: recipient.sequentialID,
                                 AISChannel: AISChannel,
                                 MMSI: MMSI,
                                 messageID: messageID,
                                 messageIndex: messageIndex,
                                 broadcastBehavior: broadcastBehavior,
                                 destinationMMSI: element.destinationMMSI,
                                 binaryStructure: binaryStructure,
                                 sentenceType: sentenceType,
                                 data: data)
    }

    private struct Recipient: BufferRecipient {
        let talker: Talker
        let format: Format
        let MMSI: Int
        let channel: AIS.BroadcastChannel?
        let messageID: AIS.MessageID
        let sequentialID: Int

        init(sentence: ParametricSentence, MMSI: Int, channel: AIS.BroadcastChannel?, messageID: AIS.MessageID, sequentialID: Int) {
            talker = sentence.talker
            format = sentence.format
            self.MMSI = MMSI
            self.channel = channel
            self.messageID = messageID
            self.sequentialID = sequentialID
        }
    }

    private struct BufferElement: SixBitElement {
        var lastSentence: Int
        var totalSentences: Int
        var allSentences = Set<Int>()

        // other fields
        var AISChannel: AIS.BroadcastChannel?
        var MMSI: Int?
        var messageID: AIS.MessageID?
        var messageIndex: Int?
        var broadcastBehavior: AIS.BroadcastBehavior?
        var destinationMMSI: Int?
        var binaryStructure: AIS.BinaryDataStructure?
        var sentenceType: SentenceType?

        // six-bit
        var encapsulatedData: String
        var fillBits: Int

        mutating func append(otherFields other: Self) {
            AISChannel ??= other.AISChannel
            MMSI ??= other.MMSI
            messageID ??= other.messageID
            messageIndex ??= other.messageIndex
            broadcastBehavior ??= other.broadcastBehavior
            destinationMMSI ??= other.destinationMMSI
            binaryStructure ??= other.binaryStructure
            sentenceType ??= other.sentenceType
        }
    }

    private enum MEBErrors: Error {
        case badData
    }
}
