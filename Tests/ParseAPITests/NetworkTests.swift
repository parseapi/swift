import Foundation
import Testing
@testable import ParseAPI

@Suite struct NetworkTests {
	@Test func asnPreservesNullsAndFullNumberRange() async throws {
		let stub = StubTransport(body: #"{"asn":4294967295,"name":null,"country":null,"country_name":null,"future":true}"#)
		let record = try await makeClient(stub).asn("AS4294967295")
		#expect(stub.requests[0].url!.absoluteString == "https://api.parseapi.com/asn/AS4294967295")
		#expect(record.asn == UInt32.max)
		#expect(record.name == nil && record.country == nil && record.countryName == nil)
	}

	@Test func macEncodesColonsAndDecodesFlags() async throws {
		let stub = StubTransport(body: #"{"mac":"02:00:00:00:00:01","valid":true,"vendor":null,"local":true,"multicast":false,"future":true}"#)
		let record = try await makeClient(stub).mac("02:00:00:00:00:01")
		#expect(stub.requests[0].url!.absoluteString == "https://api.parseapi.com/mac/02%3A00%3A00%3A00%3A00%3A01")
		#expect(record.valid && record.local == true && record.multicast == false)
		#expect(record.vendor == nil)
	}

	@Test func invalidMacIsData() async throws {
		let stub = StubTransport(body: #"{"mac":"junk","valid":false,"vendor":null,"local":null,"multicast":null}"#)
		let record = try await makeClient(stub).mac("junk")
		#expect(record.mac == "junk" && !record.valid)
		#expect(record.vendor == nil && record.local == nil && record.multicast == nil)
	}
}
