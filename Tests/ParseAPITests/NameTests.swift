import Foundation
import Testing
@testable import ParseAPI

@Suite struct NameCatalog {
	@Test func countryAndMembershipAreAdditive() async throws {
		let stub = StubTransport(body: #"{"name":"王","valid":true,"future":true,"deep":{"known":true,"gender":null}}"#)
		let client = try makeClient(stub)
		let oldCall: (String) async throws -> Name = client.name
		let result = try await client.name("王", country: "CN")
		#expect(result.deep?.known == true && result.deep?.gender == nil)
		_ = try await oldCall("Andrea")
		let requests = stub.requests
		#expect(requests[0].url?.absoluteString == "https://api.parseapi.com/name/%E7%8E%8B?country=CN")
		#expect(requests[1].url?.absoluteString == "https://api.parseapi.com/name/Andrea")
	}

	@Test func oldResponsesRemainDecodable() async throws {
		let result = try await makeClient(StubTransport(body: #"{"name":"Andrea","valid":true,"gender":null}"#)).name("Andrea")
		#expect(result.deep == nil)
	}
}
