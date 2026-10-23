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


}
