import Foundation
import Testing
@testable import ParseAPI

@Suite struct BankCheckDecoding {
	@Test func rawInputReachesTransport() async throws {
		for (input, _) in [
			("DE89.370400440532013000", "DE89.370400440532013000"),
			("\u{feff}DE89370400440532013000", "%EF%BB%BFDE89370400440532013000"),
			("DE89\u{00a0}370400440532013000", "DE89%C2%A0370400440532013000"),
			("DE89%20370400440532013000", "DE89%2520370400440532013000"),
		] {
			let stub = StubTransport(body: #"{"valid":false}"#)
			_ = try await makeClient(stub).bank(input)
			#expect(stub.requests[0].url?.absoluteString == "https://api.parseapi.com/bank")
			#expect(stub.requests[0].httpMethod == "POST")
			let sent = try JSONDecoder().decode([String: String].self, from: #require(stub.requests[0].httpBody))
			#expect(sent["iban"] == input)
			#expect(stub.requests[0].value(forHTTPHeaderField: "Parse-Version") == "2.0.0")
		}
	}

	@Test func oldAndNullResponses() async throws {
		for extra in ["", #", "checks":null,"issues":null"#] {
			let body = #"{"iban":"DE89370400440532013000","valid":true,"deep":{"account":"0532013000"}"# + extra + "}"
			let result = try await makeClient(StubTransport(body: body)).bank("DE89370400440532013000")
			#expect(result.checks == nil && result.issues == nil)
			#expect(result.iban == "DE89370400440532013000" && result.deep?.account == "0532013000")
		}
	}

	@Test func passedAndUnsupportedChecks() async throws {
		let body = #"{"iban":"DE89370400440532013000","valid":true,"checks":{"input":"passed","country":"passed","length":"passed","structure":"passed","checksum":"passed","national":"not_supported"},"issues":[]}"#
		let stub = StubTransport(body: body)
		let result = try await makeClient(stub).bank("DE89 3704 0044 0532 0130 00")
		let checks = try #require(result.checks)
		#expect([checks.input, checks.country, checks.length, checks.structure, checks.checksum].allSatisfy { $0 == "passed" })
		#expect(checks.national == "not_supported" && result.valid)
		#expect(result.issues?.isEmpty == true)
		#expect(stub.requests[0].url?.absoluteString == "https://api.parseapi.com/bank")
		#expect(stub.requests[0].value(forHTTPHeaderField: "Parse-Version") == "2.0.0")
	}

	@Test func nationalFailureAndFutureCodes() async throws {
		for (status, code) in [("failed", "invalid_national_checksum"), ("future_status", "future_issue")] {
			let body = #"{"valid":false,"checks":{"checksum":"passed","national":"\#(status)","future":true},"issues":[{"field":"iban","code":"\#(code)","message":"Review these bank details.","future":true}],"future":true}"#
			let result = try await makeClient(StubTransport(body: body)).bank("fixture")
			#expect(!result.valid && result.checks?.national == status && result.checks?.input == nil)
			let issue = try #require(result.issues?.first)
			#expect(issue.field == "iban" && issue.code == code && issue.message == "Review these bank details.")
		}
		let empty = try await makeClient(StubTransport(body: #"{"valid":false,"checks":{},"issues":[{}]}"#)).bank("fixture")
		#expect(empty.checks?.national == nil && empty.issues?.first?.code == nil)
	}
}
