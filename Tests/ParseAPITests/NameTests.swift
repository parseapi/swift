import Foundation
import Testing
@testable import ParseAPI

@Suite struct NameCatalog {
	@Test func formattingLocaleAndNullableResults() async throws {
		let stub = StubTransport(body: #"{"name":"Robert James Smith","valid":true,"deep":{"gender":"male","salutation":"Mr","short":"R.J. Smith","directory":"Smith, Robert James","initials":"RJS"}}"#)
		let client = try makeClient(stub)
		let result = try await client.name("Robert James Smith", country: "US", deep: true, nameLocale: "en-GB")
		#expect(result.deep?.short == "R.J. Smith")
		#expect(result.deep?.directory == "Smith, Robert James")
		#expect(result.deep?.initials == "RJS")
		#expect(stub.requests[0].url?.absoluteString == "https://api.parseapi.com/name/Robert%20James%20Smith?country=US&deep=true&name_locale=en-GB")
		let oldDeep: (String, Bool) async throws -> Name = client.name
		let oldCountry: (String, String?, Bool) async throws -> Name = client.name
		_ = try await oldDeep("Andrea", true)
		_ = try await oldCountry("Andrea", "IT", true)
		_ = try await client.name("Andrea", deep: true, nameLocale: nil)
		#expect(stub.requests.dropFirst().allSatisfy { $0.url?.query?.contains("name_locale") != true })
		for body in [#"{"name":"Andrea","valid":true,"deep":{"short":null,"directory":null,"initials":null}}"#, #"{"name":"Andrea","valid":true,"deep":{"gender":null,"salutation":null}}"#, #"{"name":"Andrea","valid":true,"deep":{}}"#] {
			let nullable = try await makeClient(StubTransport(body: body)).name("Andrea")
			#expect(nullable.deep != nil && nullable.deep?.short == nil && nullable.deep?.directory == nil && nullable.deep?.initials == nil)
		}
	}

	@Test func countryAndNullableEvidence() async throws {
		let stub = StubTransport(body: #"{"name":"王","valid":true,"future":true,"deep":{"gender":null,"salutation":null}}"#)
		let client = try makeClient(stub)
		let oldCall: (String) async throws -> Name = client.name
		let result = try await client.name("王", country: "CN")
		#expect(result.deep != nil && result.deep?.gender == nil && result.deep?.salutation == nil)
		_ = try await oldCall("Andrea")
		let requests = stub.requests
		#expect(requests[0].url?.absoluteString == "https://api.parseapi.com/name/%E7%8E%8B?country=CN")
		#expect(requests[1].url?.absoluteString == "https://api.parseapi.com/name/Andrea")
	}

	@Test func oldResponsesRemainDecodable() async throws {
		let result = try await makeClient(StubTransport(body: #"{"name":"Andrea","valid":true,"gender":null}"#)).name("Andrea")
		#expect(result.deep == nil)
		let historical = try await makeClient(StubTransport(body: #"{"name":"Andrea","valid":true,"deep":{"known":true,"gender":null,"future":true}}"#)).name("Andrea")
		#expect(historical.deep != nil && historical.deep?.gender == nil && historical.deep?.salutation == nil)
	}
}
