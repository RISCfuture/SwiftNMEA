import Foundation
import Testing

@testable import SwiftNMEA

@Suite
struct `8.3.72 NRM` {
  @Test
  func `parses the first example sentence`() async throws {
    let parser = SwiftNMEA()
    let data = Data("$INNRM,2,1,00001E1F,00000023,R*29\r\n".utf8)
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    guard
      case let .NAVTEXReceiverMask(
        function,
        frequency,
        coverageAreaMask,
        messageTypeMask,
        status
      ) =
        payload
    else {
      Issue.record("expected .windDirectionSpeed, got \(payload)")
      return
    }

    #expect(function == .printer)
    #expect(frequency == .freq490)
    for area in "ABCDEJKLM" {
      #expect(coverageAreaMask![area] == true)
    }
    for area in "FGHINOPQRSTUVWXYZ" {
      #expect(coverageAreaMask![area] == false)
    }
    for type in "ABF" {
      #expect(messageTypeMask![type] == true)
    }
    for type in "CDEGHIJKLMNOPQRSTUVWXYZ" {
      #expect(messageTypeMask![type] == false)
    }
    #expect(status == .reply)
  }

  @Test
  func `parses the second example sentence`() async throws {
    let parser = SwiftNMEA()
    let data = Data("$INNRM,0,2,00001E1F,0FFFFFFF,R*5F\r\n".utf8)
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    guard
      case let .NAVTEXReceiverMask(
        function,
        frequency,
        coverageAreaMask,
        messageTypeMask,
        status
      ) =
        payload
    else {
      Issue.record("expected .NAVTEXReceiverMask, got \(payload)")
      return
    }

    #expect(function == .request)
    #expect(frequency == .freq518)
    for area in "ABCDEJKLM" {
      #expect(coverageAreaMask![area] == true)
    }
    for area in "FGHINOPQRSTUVWXYZ" {
      #expect(coverageAreaMask![area] == false)
    }
    for type in "ABCDEFGHIJKLMNOPQRSTUVWXYZ" {
      #expect(messageTypeMask![type] == true)
    }
    #expect(status == .reply)
  }
}
