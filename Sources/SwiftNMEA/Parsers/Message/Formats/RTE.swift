import Foundation
import NMEACommon
import NMEAUnits

class RTEParser: MessageFormat {
    private var buffer = SentenceCountingBuffer<Recipient, BufferElement>()

    func canParse(sentence: ParametricSentence) throws -> Bool {
        sentence.delimiter == .parametric && sentence.format == .route
    }

    func parse(sentence: ParametricSentence) throws -> Message.Payload? {
        let totalSentences = try sentence.fields.int(at: 0)!,
            sentenceNumber = try sentence.fields.int(at: 1)!,
            mode = try sentence.fields.enumeration(at: 2, ofType: Navigation.RouteType.self, optional: true),
            identifier = try sentence.fields.string(at: 3, optional: true),
            waypoints = sentence.fields[4...].compactMap(\.self)

        do {
            let recipient = zipOptionals(mode, identifier).map { mode, identifier in
                Recipient(sentence: sentence, mode: mode, identifier: identifier)
            }
            let element = BufferElement(lastSentence: sentenceNumber, totalSentences: totalSentences, identifiers: waypoints),
                finished = try buffer.add(element: element, optionallyFor: recipient)

            return zipOptionals(finished?.0, finished?.1).map { recipient, element in
                makePayload(recipient: recipient, element: element)
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

    func flush(talker: Talker?, format: Format?, includeIncomplete: Bool) -> [any Element] {
        if !includeIncomplete { return [] } // complete messages are flushed upon receipt of the last message

        let flushed = buffer.flush(talker: talker, format: format, includeIncomplete: includeIncomplete)
        return flushed.compactMap { recipient, element in
            let payload = makePayload(recipient: recipient, element: element)
            return Message(talker: recipient.talker, format: recipient.format, payload: payload)
        }
    }

    private func makePayload(recipient: Recipient, element: BufferElement) -> Message.Payload {
        return .route(mode: recipient.mode,
                      identifier: recipient.identifier,
                      waypoints: element.identifiers)
    }

    private struct Recipient: BufferRecipient {
        var talker: Talker
        let format = Format.route
        let mode: Navigation.RouteType
        let identifier: String

        init(sentence: ParametricSentence, mode: Navigation.RouteType, identifier: String) {
            talker = sentence.talker
            self.mode = mode
            self.identifier = identifier
        }
    }

    private struct BufferElement: SentenceCountingElement {
        var lastSentence: Int
        var totalSentences: Int
        var allSentences = Set<Int>()

        var identifiers = [String]()

        mutating func append(payloadOnly other: Self) {
            identifiers.append(contentsOf: other.identifiers)
        }
    }
}
