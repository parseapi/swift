import Foundation
import Testing
@testable import ParseAPI

@Suite struct BankDX {
	@Test func postContextAndRetryKeepRawInputOutOfURL() async throws {
		let stub = StubTransport([(503, #"{"code":"unavailable"}"#, [:]), (200, #"{"valid":true,"deep":{"directory":{"edition":"fixture","country":"DE","match":"future_grain"}}}"#, [:])])
		let client = try ParseAPI("fixture", transport: stub.transport)
		let raw = "89%20\u{feff}00"
		let result = try await client.bank(raw, country: "DE", deep: true)
		#expect(result.deep?.directory?.edition == "fixture")
		#expect(result.deep?.directory?.match == "future_grain")
		#expect(stub.requests.count == 2)
		for request in stub.requests {
			#expect(request.url?.absoluteString == "https://api.parseapi.com/bank")
			#expect(request.httpMethod == "POST")
			#expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
			#expect(request.value(forHTTPHeaderField: "Parse-Version") == "2.0.0")
			let body = try JSONSerialization.jsonObject(with: #require(request.httpBody)) as? [String: Any]
			#expect(body?["iban"] as? String == raw)
			#expect(body?["country"] as? String == "DE")
			#expect(body?["deep"] as? Bool == true)
		}
	}

	@Test func domesticRawBodyOpenCodesAndNullableFields() async throws {
		let stub = StubTransport(body: #"{"valid":false,"routing":null,"account":null,"checks":{"account_checksum":"future_status"},"issues":[{"field":"account","code":"future_issue"}]}"#)
		let result = try await makeClient(stub).bankUsAch(BankUsAchInput(routing: "021 000021", account: "00a-B %20\u{feff}"))
		#expect(result.routing == nil && result.account == nil)
		#expect(result.checks?.accountChecksum == "future_status")
		#expect(result.issues?.first?.code == "future_issue")
		let request = try #require(stub.requests.first)
		#expect(request.url?.absoluteString == "https://api.parseapi.com/bank" && request.httpMethod == "POST")
		let body = try JSONSerialization.jsonObject(with: #require(request.httpBody)) as? [String: String]
		#expect(body == ["format": "us_ach", "country": "US", "routing": "021 000021", "account": "00a-B %20\u{feff}"])
	}

	@Test func requirementsSupportAndUnknownFormatAreCapabilities() async throws {
		let stub = StubTransport(body: #"{"country":"US","format":"us_ach","supported":true,"fields":[{"key":"account","label":"Account number","required":true,"type":"string","max_length":17,"max_input_length":128,"length_unit":"non_space_characters","pattern":"[A-Za-z0-9 -]+","normalization":"None"}],"checks":{"account_checksum":"not_supported","future":"future_scope"},"limitations":["No account verification"]}"#)
		let result = try await makeClient(stub).bankRequirements("US", format: "us_ach")
		#expect(result.supported && result.fields.first?.maxLength == 17)
		#expect(result.fields.first?.minLength == nil && result.fields.first?.maxInputLength == 128)
		#expect(result.checks["future"] == "future_scope")
		#expect(stub.requests[0].url?.absoluteString == "https://api.parseapi.com/bank/requirements?country=US&format=us_ach")
		#expect(stub.requests[0].httpMethod == "GET" && stub.requests[0].httpBody == nil)
		let unsupported = StubTransport(body: #"{"country":"GB","format":"uk_domestic","supported":false,"fields":[],"checks":{},"limitations":[]}"#)
		#expect(try await makeClient(unsupported).bankRequirements("GB", format: "uk_domestic").supported == false)
		let defaults = StubTransport(body: #"{"country":"DE","format":"iban","supported":true,"fields":[],"checks":{},"limitations":[]}"#)
		_ = try await makeClient(defaults).bankRequirements("DE")
		#expect(defaults.requests[0].url?.absoluteString == "https://api.parseapi.com/bank/requirements?country=DE")
	}
}
