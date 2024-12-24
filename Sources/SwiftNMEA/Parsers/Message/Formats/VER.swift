import Foundation
import NMEACommon
import NMEAUnits

class VERParser: MessageFormat {
    private var buffer = SentenceCountingBuffer<Recipient, BufferElement>()

    func canParse(sentence: ParametricSentence) throws -> Bool {
        sentence.delimiter == .parametric && sentence.format == .version
    }

    func parse(sentence: ParametricSentence) throws -> Message.Payload? {
        let totalSentences = try sentence.fields.int(at: 0)!,
            sentenceNumber = try sentence.fields.int(at: 1)!,
            deviceType = try sentence.fields.string(at: 2, optional: true),
            vendorID = try sentence.fields.string(at: 3, optional: true),
            uniqueID = try sentence.fields.string(at: 4)!,
            serialNumber = try sentence.fields.string(at: 5, optional: true),
            modelCode = try sentence.fields.string(at: 6, optional: true),
            softwareRevision = try sentence.fields.string(at: 7, optional: true),
            hardwareRevision = try sentence.fields.string(at: 8, optional: true),
            sequentialID = try sentence.fields.int(at: 9)!

        do {
            let recipient = Recipient(sentence: sentence, uniqueID: uniqueID, sequentialID: sequentialID),
                element = BufferElement(lastSentence: sentenceNumber,
                                        totalSentences: totalSentences,
                                        deviceType: deviceType,
                                        vendorID: vendorID,
                                        serialNumber: serialNumber,
                                        modelCode: modelCode,
                                        softwareRevision: softwareRevision,
                                        hardwareRevision: hardwareRevision),
                finished = try buffer.add(element: element, optionallyFor: recipient)

            return try zipOptionals(finished?.0, finished?.1).map { recipient, element in
                try makePayload(recipient: recipient, element: element)
            }
        } catch let error as VERErrors {
            switch error {
                case let .missingField(index):
                    throw sentence.fields.fieldError(type: .missingRequiredValue, index: index)
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
        return flushed.compactMap { recipient, element in
            do {
                let payload = try makePayload(recipient: recipient, element: element)
                return Message(talker: recipient.talker, format: recipient.format, payload: payload)
            } catch let error as VERErrors {
                switch error {
                    case let .missingField(index):
                        return MessageError(type: .missingRequiredValue, fieldNumber: index)
                }
            } catch {
                fatalError("Unexpected error \(error)")
            }
        }
    }

    private func makePayload(recipient: Recipient, element: BufferElement) throws -> Message.Payload {
        guard let deviceType = element.deviceType else { throw VERErrors.missingField(index: 2) }
        guard let vendorID = element.vendorID else { throw VERErrors.missingField(index: 3) }
        guard let serialNumber = element.serialNumber else { throw VERErrors.missingField(index: 5) }
        guard let modelCode = element.modelCode else { throw VERErrors.missingField(index: 6) }
        guard let softwareRevision = element.softwareRevision else { throw VERErrors.missingField(index: 7) }
        guard let hardwareRevision = element.hardwareRevision else { throw VERErrors.missingField(index: 8) }

        return .version(type: deviceType,
                        vendorID: vendorID,
                        uniqueID: recipient.uniqueID,
                        serialNumber: serialNumber,
                        modelCode: modelCode,
                        softwareRevision: softwareRevision,
                        hardwareRevision: hardwareRevision)
    }

    private struct Recipient: BufferRecipient {
        var talker: Talker
        let format = Format.version

        let uniqueID: String
        let sequentialID: Int

        init(sentence: ParametricSentence, uniqueID: String, sequentialID: Int) {
            talker = sentence.talker
            self.uniqueID = uniqueID
            self.sequentialID = sequentialID
        }
    }

    private struct BufferElement: SentenceCountingElement {
        var lastSentence: Int
        var totalSentences: Int
        var allSentences = Set<Int>()

        // write-once fields
        let deviceType: String?
        let vendorID: String?

        // concatenated fields
        var serialNumber: String?
        var modelCode: String?
        var softwareRevision: String?
        var hardwareRevision: String?

        mutating func append(payloadOnly other: Self) {
            if let otherSerialNumber = other.serialNumber {
                serialNumber = (serialNumber ?? "") + otherSerialNumber
            }
            if let otherModelCode = other.modelCode {
                modelCode = (modelCode ?? "") + otherModelCode
            }
            if let otherSoftwareRevision = other.softwareRevision {
                softwareRevision = (softwareRevision ?? "") + otherSoftwareRevision
            }
            if let otherHardwareRevision = other.hardwareRevision {
                hardwareRevision = (hardwareRevision ?? "") + otherHardwareRevision
            }
        }
    }

    private enum VERErrors: Error {
        case missingField(index: Int)
    }
}
