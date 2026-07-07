import Foundation
import Testing

@testable import SwiftNMEA

@Suite("8.3.46 GSA")
struct GSATests {
  @Test("parses a sentence")
  func parsesASentence() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .GPS,
      format: .GNSS_DOP,
      fields: [
        "A", 3,
        "05", "03", "01", "02", "04",
        0.5, 0.6, 0.7,
        1
      ]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    guard
      case let .GNSS_DOP(PDOP, HDOP, VDOP, auto3D, solution, ids) = payload
    else {
      Issue.record("expected .GNSS_DOP, got \(payload)")
      return
    }

    #expect(PDOP == 0.5)
    #expect(HDOP == 0.6)
    #expect(VDOP == 0.7)
    #expect(auto3D)
    #expect(solution == .fix3D)
    #expect(
      ids == [
        .GPS(5, signal: nil),
        .GPS(3, signal: nil),
        .GPS(1, signal: nil),
        .GPS(2, signal: nil),
        .GPS(4, signal: nil)
      ]
    )
  }

  @Test("parses a sentence from a STA8089FG")
  func parsesASentenceFromASTA8089FG() async throws {
    let parser = SwiftNMEA()
    let sentence = "$GPGSA,A,1,,,,,,,,,,,,,99.0,99.0,99.0*00\r\n"
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    guard
      case let .GNSS_DOP(PDOP, HDOP, VDOP, auto3D, solution, ids) = payload
    else {
      Issue.record("expected .GNSS_DOP, got \(payload)")
      return
    }

    #expect(PDOP == 99.0)
    #expect(HDOP == 99.0)
    #expect(VDOP == 99.0)
    #expect(auto3D)
    #expect(solution == GNSS.SolutionType.none)
    #expect(ids.isEmpty)
  }
}
