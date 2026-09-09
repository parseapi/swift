import Foundation
import Testing
@testable import ParseAPI

@Suite struct BinTests {
	@Test func preservesPrefixAndFalse() async throws {
		let stub = StubTransport(body: #"{"bin":"00123456","prefix":"001234","country":null,"issuer":"Fixture Bank","brand":"future-brand","type":null,"prepaid":false,"deep":{},"future":true}"#)
		let record = try await makeClient(stub).bin("00 1234-56", deep: true)
		#expect(stub.requests[0].url!.absoluteString == "https://api.parseapi.com/bin/00%201234-56?deep=true")
		#expect(record.bin == "00123456" && record.prefix == "001234" && record.country == nil)
		#expect(record.prepaid == false && record.deep != nil)
	}
	@Test func unknownAndAbsentFieldsStayUnknown() async throws {
		for body in [#"{"bin":"000000","prefix":null,"country":null,"issuer":null,"brand":null,"type":null,"prepaid":null}"#, #"{"bin":"000000"}"#] {
			let stub = StubTransport(body: body)
			let record = try await makeClient(stub).bin("000000")
			#expect(record.prefix == nil && record.prepaid == nil && record.deep == nil)
			#expect(stub.requests[0].url!.absoluteString == "https://api.parseapi.com/bin/000000")
		}
	}
}
