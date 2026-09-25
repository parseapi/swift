import Foundation
import Testing
@testable import ParseAPI

@Suite struct CardTests {
	@Test func preservesPrefixAndFalse() async throws {
		let stub = StubTransport(body: #"{"bin":"00123456","brand":"future-brand","brand_name":null,"logo":"https://cdn.parseapi.com/card/generic.svg","deep":{"prefix":"001234","issuer":"Fixture Bank","country":null,"type":null,"prepaid":false},"future":true}"#)
		let record = try await makeClient(stub).card("00 1234-56", deep: true)
		#expect(stub.requests[0].url!.absoluteString == "https://api.parseapi.com/card/00%201234-56?deep=true")
		#expect(record.bin == "00123456" && record.deep?.prefix == "001234" && record.deep?.country == nil)
		#expect(record.deep?.prepaid == false)
	}
	@Test func unknownAndAbsentFieldsStayUnknown() async throws {
		for body in [#"{"bin":"000000","brand":null,"brand_name":null,"logo":"https://cdn.parseapi.com/card/generic.svg"}"#, #"{"bin":"000000","logo":"https://cdn.parseapi.com/card/generic.svg"}"#] {
			let stub = StubTransport(body: body)
			let record = try await makeClient(stub).card("000000")
			#expect(record.deep?.prefix == nil && record.deep?.prepaid == nil)
			#expect(stub.requests[0].url!.absoluteString == "https://api.parseapi.com/card/000000")
		}
	}
}
