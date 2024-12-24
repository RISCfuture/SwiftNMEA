import Foundation
import NMEACommon

class LRIParser: MessageFormat {
    private var buffer = LRIBuffer()

    func canParse(sentence: ParametricSentence) throws -> Bool {
        sentence.delimiter == .parametric && (
            sentence.format == .AISLongRangeInterrogation ||
            sentence.format == .AISLongRangeFunction)
    }

    func parse(sentence: ParametricSentence) throws -> Message.Payload? {
        guard let element = LRIElement(sentence: sentence),
              let recipient = try LRIRecipient(sentence: sentence) else {
            return nil
        }

        do {
            return try buffer.add(element: element, for: recipient).map { element in
                return try .AISLongRangeInterrogation(replyLogic: element.replyLogic!,
                                                      requestorMMSI: recipient.MMSI,
                                                      requestorName: element.requestorName!,
                                                      destination: element.destination!,
                                                      functions: element.functions!)
            }
        } catch let error as LRIErrors {
            switch error {
                case .formatAlreadySeen:
                    throw sentence.fields.lineError(type: .unexpectedFormat)
            }
        }
    }

    private struct LRIRecipient: BufferRecipient {
        var talker: Talker
        let format = Format.AISLongRangeInterrogation // placeholder as recipients are not distinguished by format
        var MMSI: Int
        var sequence: Int

        init?(sentence: ParametricSentence) throws {
            talker = sentence.talker

            switch sentence.format {
                case .AISLongRangeInterrogation:
                    MMSI = try sentence.fields.int(at: 2)!
                    sequence = try sentence.fields.int(at: 0)!
                case .AISLongRangeFunction:
                    MMSI = try sentence.fields.int(at: 1)!
                    sequence = try sentence.fields.int(at: 0)!
                default: return nil
            }
        }
    }

    private struct LRIElement: BufferElement {
        static var formats: Set<Format> { .init([.AISLongRangeInterrogation, .AISLongRangeFunction]) }

        var sentences = [Format: ParametricSentence]()

        var isComplete: Bool { Set(sentences.keys) == Self.formats }

        var replyLogic: AISLongRange.ReplyLogic? {
            get throws {
                try sentences[.AISLongRangeInterrogation]?.fields.enumeration(at: 1, ofType: AISLongRange.ReplyLogic.self)
            }
        }

        var requestorName: String? {
            get throws {
                try sentences[.AISLongRangeFunction]?.fields.string(at: 2)
            }
        }

        var destination: AISLongRange.Destination? {
            get throws {
                guard let sentence = sentences[.AISLongRangeInterrogation] else { return nil }
                if let MMSI = try sentence.fields.int(at: 3, optional: true) {
                    return .MMSI(MMSI)
                }
                if let northeast = try sentence.fields.position(latitudeIndex: (4, 5), longitudeIndex: (6, 7), optional: true),
                   let southwest = try sentence.fields.position(latitudeIndex: (8, 9), longitudeIndex: (10, 11), optional: true) {
                    return .area(.init(northeast: northeast, southwest: southwest))
                }
                throw sentence.fields.fieldError(type: .missingRequiredValue, index: 3)
            }
        }

        var functions: Set<AISLongRange.Function>? {
            get throws {
                guard let sentence = sentences[.AISLongRangeFunction] else { return nil }
                return try .init(LRFunctions(fields: sentence.fields))
            }
        }

        init?(sentence: ParametricSentence) {
            guard Self.formats.contains(sentence.format) else {
                return nil
            }
            sentences[sentence.format] = sentence
        }

        mutating func append(_ other: Self) throws {
            try sentences.merge(other.sentences) { _, _ in
                throw LRIErrors.formatAlreadySeen
            }
        }
    }

    private class LRIBuffer: Buffer {
        typealias Recipient = LRIRecipient
        typealias Element = LRIElement

        var buffer = [Recipient: Element]()
    }

    private enum LRIErrors: Error {
        case formatAlreadySeen
    }
}
