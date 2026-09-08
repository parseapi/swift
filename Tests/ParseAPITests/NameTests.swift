import Foundation
import Testing
@testable import ParseAPI

@Suite struct NameCatalog {
	@Test func countryAndMembershipAreAdditive() async throws {
		let stub = StubTransport(body: #"{"name":"王","valid":true,"known":true,"countries":["CN","TW"],"gender":null,"future":true}"#)
		let client = try makeClient(stub)
		let oldCall: (String) async throws -> Name = client.name
		let result = try await client.name("王", country: "CN")
		#expect(result.known && result.countries == ["CN", "TW"] && result.gender == nil)
		_ = try await oldCall("Andrea")
		let requests = stub.requests
		#expect(requests[0].url?.absoluteString == "https://api.parseapi.com/name/%E7%8E%8B?country=CN")
		#expect(requests[1].url?.absoluteString == "https://api.parseapi.com/name/Andrea")
	}

	@Test func oldAndNullArrayResponsesRemainDecodable() async throws {
		for field in ["", #", "countries":null"#] {
			let result = try await makeClient(StubTransport(body: #"{"name":"Andrea","valid":true,"gender":null"# + field + "}")).name("Andrea")
			#expect(!result.known && result.countries.isEmpty && result.gender == nil)
		}
	}
}
