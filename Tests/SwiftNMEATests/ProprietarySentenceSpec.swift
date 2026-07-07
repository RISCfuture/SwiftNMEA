import Testing

@testable import SwiftNMEA

@Suite("ProprietarySentence")
struct ProprietarySentenceTests {
  // MARK: - rawValue

  @Test("encodes the sentence from the spec")
  func encodesTheSentenceFromTheSpec() throws {
    let sentence = ProprietarySentence(
      manufacturer: "SRD",
      data: "A003[470738][1224523]???RST47, 3809, A004"
    )
    #expect(sentence.rawValue == "$PSRDA003[470738][1224523]???RST47, 3809, A004*47\r\n")
  }

  // MARK: - parsing

  @Test("parses the sentence from the spec")
  func parsesTheSentenceFromTheSpec() async throws {
    let sentence = try await ProprietarySentence(
      sentence: "$PSRDA003[470738][1224523]???RST47, 3809, A004*47"
    )!
    #expect(sentence.manufacturer == "SRD")
    #expect(sentence.data == "A003[470738][1224523]???RST47, 3809, A004")
  }
}
