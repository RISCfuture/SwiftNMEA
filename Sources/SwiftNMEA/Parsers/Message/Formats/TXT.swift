import Foundation
import NMEACommon
import NMEAUnits

class TXTParser: MessageFormat {
    private static let coder = EscapedStringCoder()

    private var buffer = SentenceCountingBuffer<Recipient, BufferElement>()

    func canParse(sentence: ParametricSentence) throws -> Bool {
        sentence.delimiter == .parametric && sentence.format == .text
    }

    func parse(sentence: ParametricSentence) throws -> Message.Payload? {
        if sentence.fields.count == 1 { return try parseSTA8089FG(sentence: sentence) }
        return try parseSpec(sentence: sentence)
    }

    private func parseSpec(sentence: ParametricSentence) throws -> Message.Payload? {
        let totalSentences = try sentence.fields.int(at: 0)!,
            sentenceNumber = try sentence.fields.int(at: 1)!,
            identifier = try sentence.fields.int(at: 2, optional: true),
            message = try sentence.fields.string(at: 3)!

        do {
            let recipient = identifier.map { identifier in
                Recipient(sentence: sentence, identifier: identifier)
            }
            let element = BufferElement(
                lastSentence: sentenceNumber,
                totalSentences: totalSentences,
                message: message
            ),
                finished = try buffer.add(
                    element: element,
                    optionallyFor: recipient
                )

            return try zipOptionals(finished?.0, finished?.1)
                .map { recipient, element in
                    try makePayload(recipient: recipient, element: element)
                }
        } catch let error as TXTErrors {
            switch error {
                case .badMessage: throw sentence.fields.fieldError(type: .badEncoding, index: 3)
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

    private func parseSTA8089FG(sentence: ParametricSentence) throws -> Message.Payload? {
        let message = try sentence.fields.string(at: 0)!

        guard let decodedMessage = Self.coder.decode(string: message) else {
            throw sentence.fields.fieldError(type: .badEncoding, index: 0)
        }

        return .text(decodedMessage, identifier: nil)
    }

    func flush(talker: Talker?, format: Format?, includeIncomplete: Bool) throws -> [any Element] {
        if !includeIncomplete {
            return []
        } // complete messages are flushed upon receipt of the last message

        let flushed = buffer.flush(
            talker: talker,
            format: format,
            includeIncomplete: includeIncomplete
        )

        return try flushed.compactMap { recipient, element in
            do {
                let payload = try makePayload(recipient: recipient, element: element)
                return Message(talker: recipient.talker, format: recipient.format, payload: payload)
            } catch let error as TXTErrors {
                switch error {
                    case .badMessage:
                        return MessageError(type: .badEncoding, fieldNumber: 3)
                }
            }
        }
    }

    private func makePayload(recipient: Recipient, element: BufferElement) throws -> Message.Payload {
        guard let text = element.text else { throw TXTErrors.badMessage }
        return .text(text, identifier: recipient.identifier)
    }

    private struct Recipient: BufferRecipient {
        var talker: Talker
        let format = Format.text
        let identifier: Int

        init(sentence: ParametricSentence, identifier: Int) {
            talker = sentence.talker
            self.identifier = identifier
        }
    }

    private struct BufferElement: SentenceCountingElement {
        private static let coder = EscapedStringCoder()

        var lastSentence: Int
        var totalSentences: Int
        var allSentences = Set<Int>()

        var message: String

        var text: String? { Self.coder.decode(string: message) }

        mutating func append(payloadOnly other: Self) {
            message.append(contentsOf: other.message)
        }
    }

    enum TXTErrors: Error {
        case badMessage
    }
}
