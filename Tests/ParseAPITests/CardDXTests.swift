import Foundation
import Testing
@testable import ParseAPI

@Suite struct CardDXTests {
    @Test func invalidPrefixesNeverDispatchAndAcceptedInputIsPreserved() async throws {
        let stub = StubTransport(body: #"{"bin":"001234","logo":"https://cdn.parseapi.com/card/generic.svg"}"#)
        let parse = try makeClient(stub)
        for raw in ["4111111111111111", "4111-1111-1111-1111", "1", "123456789012", "１２３４５６", "001\u{00a0}234", "001\u{200b}234", "00%20234", "001\u{000b}234", String(repeating: " ", count: 59) + "001234"] {
            do { _ = try await parse.card(raw); Issue.record("expected local rejection") }
            catch let error as ParseAPIError {
                #expect(error.status == 0)
                #expect(error.message == "Card requires a 2-11 digit prefix string.")
            }
        }
        #expect(stub.requests.isEmpty)
        for raw in [" \t00-1234\r\n", String(repeating: " ", count: 58) + "001234", "12345678901"] {
            _ = try await parse.card(raw)
            #expect(stub.requests.last?.url?.absoluteString == "https://api.parseapi.com/card/" + raw.addingPercentEncoding(withAllowedCharacters: .parseAPIUnreserved)!)
        }
    }

    @Test func retryAfterBudgetReturnsOriginalErrorAndMetadata() async throws {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
        let future = formatter.string(from: Date().addingTimeInterval(60))
        for header in ["60", String(repeating: "9", count: 400), future] {
            let stub = StubTransport([(429, #"{"code":"rate_limited","message":"Later","request_id":"receipt"}"#, ["Retry-After": header])])
            let start = Date()
            do { _ = try await ParseAPI("fixture", transport: stub.transport).country("US"); Issue.record("expected API error") }
            catch let error as ParseAPIError {
                #expect(error.retryAfter == header)
                #expect(error.code == "rate_limited")
                #expect(error.requestId == "receipt")
            }
            #expect(Date().timeIntervalSince(start) < 1)
            #expect(stub.requests.count == 1)
        }
        for header in ["0", "0.01", "invalid"] {
            let stub = StubTransport([(503,"{}",["Retry-After":header]),(503,"{}",["Retry-After":header])])
            do { _ = try await ParseAPI("fixture", retries: 1, transport: stub.transport).country("US"); Issue.record("expected API error") }
            catch let error as ParseAPIError { #expect(error.retryAfter == header) }
            #expect(stub.requests.count == 2)
        }
        #expect(ParseAPI.retryDelayNanos(attempt: 0, retryAfter: "0") == 0)
        #expect(ParseAPI.retryDelayNanos(attempt: 0, retryAfter: "0.01") == 10_000_000)
        #expect(ParseAPI.retryDelayNanos(attempt: 0, retryAfter: "0.0000000001") == 1)
        #expect(ParseAPI.retryDelayNanos(attempt: 0, retryAfter: String(repeating: "9", count: 400)) == nil)
        #expect(ParseAPIError(status: 400, code: "test", message: "test", docs: nil, requestId: nil).retryAfter == nil)
    }
}
