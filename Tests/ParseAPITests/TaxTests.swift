import Foundation
import Testing
@testable import ParseAPI

@Suite struct TaxFields {
	@Test func referenceFieldsPreservePercentZeroAndNull() async throws {
		let country = try await makeClient(StubTransport(body: #"{"country":"DE","name":"Germany","continent":"EU","tax":{"name":"VAT","rate":19}}"#)).country("DE", deep: true)
 #expect(country.tax?.name == "VAT" && country.tax?.rate == 19)
		let body = #"{"postal":"12345","country":"US","tax":{"name":"Sales tax","rate":7.9,"rate_state":5,"rate_county":0,"rate_city":null,"rate_special":2.9}}"#
		let postal = try await makeClient(StubTransport(body: body)).postal("12345", deep: true)
 #expect(postal.tax?.name == "Sales tax" && postal.tax?.rate == 7.9)
 #expect(postal.tax?.rateState == 5 && postal.tax?.rateCounty == 0)
 #expect(postal.tax?.rateCity == nil && postal.tax?.rateSpecial == 2.9)
	}

	@Test func omittedLockedAndUnknownTaxStayDistinct() async throws {
		for field in ["", #", "deep":{}"#, #", "deep":{"tax":null,"tax_rate":null}"#] {
			let postal = try await makeClient(StubTransport(body: #"{"postal":"12345","country":"US""# + field + "}")).postal("12345")
 #expect(postal.tax == nil && postal.tax?.rate == nil)
						let country = try await makeClient(StubTransport(body: #"{"country":"DE","name":"Germany","continent":"EU""# + field + "}")).country("DE")
 #expect(country.tax?.name == nil && country.tax?.rate == nil)
					}
	}
}
