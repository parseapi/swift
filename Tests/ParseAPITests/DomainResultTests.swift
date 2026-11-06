import Foundation
import Testing
@testable import ParseAPI

@Suite struct DomainResultTests {
	@Test func nullableAvailabilityAndPartialDetailUseOneLookup() async throws {
		let cases: [(String, Bool?)] = [
			(#"{"domain":"x.example","available":null}"#, nil),
			(#"{"domain":"x.example"}"#, nil),
			(#"{"domain":"x.example","available":true,"registration":{"registered":false}}"#, true),
			(#"{"domain":"x.example","available":false,"registration":{"registered":true,"created":null,"status":[],"dnssec":false}}"#, false),
			// Tolerant decoding; unavailable current responses normally use deep:{}.
			(#"{"domain":"x.example","available":false,"registration":null}"#, false),
			(#"{"domain":"x.example","available":false,"registration":{"registered":true,"status":null,"dnssec":null}}"#, false),
			(#"{"domain":"x.example","available":false,"registration":{}}"#, false),
			(#"{"domain":"x.example","available":false,"registration":{"registered":null}}"#, false),
		]
		for (index, item) in cases.enumerated() {
			let stub = StubTransport(body: item.0), client = try makeClient(stub)
			let lookup: (String, Bool) async throws -> DomainResult = client.domainResult
			let result = try await lookup("bücher.example", true)
			let available: Bool? = result.available
 #expect(available == item.1)
 #expect(result.domain == "x.example")
 #expect(stub.requests.count == 1)
 #expect(stub.requests[0].url!.absoluteString == "https://api.parseapi.com/domain/b%C3%BCcher.example?deep=true")
 #expect(stub.requests[0].value(forHTTPHeaderField: "X-API-Version") == "2.1.0")
 #expect(stub.requests[0].value(forHTTPHeaderField: "X-API-Key") == "parse_testtesttesttest")
			if index == 0 {
 #expect(result.registration == nil) }
			if index == 1 { }
			if index == 2 {
 #expect(result.registration?.dnssec == nil && result.registration?.status == nil)
			}
			if index == 3 {
 #expect(result.registration?.dnssec == false && result.registration?.status?.isEmpty == true)
			}
			if index == 4 {
 #expect(result.registration == nil) }
			if index == 5 {
 #expect(result.registration?.dnssec == nil && result.registration?.status == nil)
			}
			if index == 6 || index == 7 {
			}
		}
	}

	@Test func existingDomainCallablePreservesUnknownAndKnownAvailability() async throws {
        for (raw, expected) in [("true", true as Bool?), ("false", false as Bool?), ("null", nil)] {
            for signing in ["", ",\"dnssec\":null", ",\"dnssec\":false", ",\"dnssec\":true"] {
                let detail = raw == "null" ? "{}" : raw == "true" ? "{\"registration\":{\"registered\":false}}" : "{\"registration\":{\"registered\":true\(signing)}}"
                let body = "{\"domain\":\"x.example\",\"available\":\(raw),\"deep\":\(detail)}"
                let stub = StubTransport(body: body), client = try makeClient(stub)
                let lookup: (String, Bool) async throws -> Domain = client.domain
                let result = try await lookup("x.example", true)
                let available: Bool? = result.available
 #expect(available == expected)
 #expect(result.registration?.dnssec == (raw == "false" ? (signing.contains("false") ? false : signing.contains("true") ? true : nil) : nil))
 #expect(stub.requests.count == 1)
            }
        }
        let stub = StubTransport(body: #"{"domain":"x.example","available":"false"}"#)
        do { _ = try await makeClient(stub).domain("x.example"); Issue.record("A string is not nullable boolean availability") }
        catch is DecodingError { }
 #expect(stub.requests.count == 1, "A decode failure does not repeat the lookup")
    }

	@Test func noDeepDefaultAndExplicitFalseRemainAvailable() async throws {
		let stub = StubTransport(body: #"{"domain":"x.example","available":false}"#)
		let result = try await makeClient(stub).domainResult("x.example")
 #expect(result.available == false)
 #expect(stub.requests.count == 1 && stub.requests[0].url!.absoluteString == "https://api.parseapi.com/domain/x.example")
	}
}
