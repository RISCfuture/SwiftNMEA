import Foundation
import Nimble
import Quick
@testable import SwiftNMEA

final class GENSpec: AsyncSpec {
    override static func spec() {
        describe("8.3.33 GEN") {
            it("parses the example in the spec") {
                let parser = SwiftNMEA(),
                sentences = [
                    "$VRGEN,0000,011200.00,0123,4567,89AB,CDEF,0123,4567,89AB,CDEF*64\r\n",
                    "$VRGEN,0008,011200.00,0123,4567*6C\r\n"
                ],
                data = sentences.joined().data(using: .ascii)!,
                parsed = try await parser.parse(data: data),
                flushed = try await parser.flush(includeIncomplete: true)

                expect(parsed).to(haveCount(2))
                expect(flushed).to(haveCount(1))

                guard let message = flushed[0] as? Message else {
                    fail("expected Message, got \(flushed[0])")
                    return
                }
                guard case let .genericBinary(time, data) = message.payload else {
                    fail("expected .genericBinary, got \(message)")
                    return
                }

                let components = Calendar.current.dateComponents(in: .gmt, from: time!)
                expect(components.hour).to(equal(1))
                expect(components.minute).to(equal(12))
                expect(components.second).to(equal(0))
                expect(components.nanosecond).to(equal(0))
                expect(data.hex).to(equal("0123456789ABCDEF0123456789ABCDEF01234567"))
            }
        }
    }
}
