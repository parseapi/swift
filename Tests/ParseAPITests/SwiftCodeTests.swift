import Foundation
import Testing
@testable import ParseAPI

@Suite struct SwiftCodeTests {
	@Test func swiftEncodesInputAndToleratesNewFields() async throws {
		let stub = StubTransport(body: #"{"swift":"CHASUS33","valid":true,"country":"US","name":"JPMORGAN CHASE BANK, N.A.","future":true}"#)
		let record: SwiftCode = try await makeClient(stub).swift("CHAS/US33 ?#")
		#expect(stub.requests[0].url!.absoluteString == "https://api.parseapi.com/swift/CHAS%2FUS33%20%3F%23")
		#expect(record.valid && record.swift == "CHASUS33" && record.country == "US")
		#expect(record.name == "JPMORGAN CHASE BANK, N.A.")
	}

	@Test func validSyntaxDoesNotRequireKnownName() async throws {
		let stub = StubTransport(body: #"{"swift":"ZZZZZZ99","valid":true,"country":"ZZ","name":null,"future":{}}"#)
		let record = try await makeClient(stub).swift("ZZZZZZ99")
		#expect(record.valid && record.country == "ZZ" && record.name == nil)
	}

	@Test func junkIsDataAndAbsentOptionalFieldsStayUnknown() async throws {
		for body in [#"{"swift":"JUNK","valid":false,"country":null,"name":null}"#, #"{"swift":"JUNK","valid":false}"#] {
			let record = try await makeClient(StubTransport(body: body)).swift("JUNK")
			#expect(!record.valid && record.country == nil && record.name == nil)
		}
	}
}
