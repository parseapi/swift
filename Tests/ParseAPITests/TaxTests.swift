import Foundation
import Testing
@testable import ParseAPI

@Suite struct TaxFields {
	@Test func referenceFieldsPreservePercentZeroAndNull() async throws {
		let country = try await makeClient(StubTransport(body: #"{"country":"DE","name":"Germany","continent":"EU","deep":{"tax":"VAT","tax_rate":19,"tax_id_format":"DE999999999","tax_id_regex":"^DE[0-9]{9}$"}}"#)).country("DE", deep: true)
		#expect(country.deep?.tax == "VAT" && country.deep?.taxRate == 19)
		#expect(country.deep?.taxIdFormat == "DE999999999" && country.deep?.taxIdRegex == "^DE[0-9]{9}$")
		let body = #"{"postal":"12345","country":"US","deep":{"tax":"Sales tax","tax_rate":7.9,"tax_rate_state":5,"tax_rate_county":0,"tax_rate_city":null,"tax_rate_special":2.9}}"#
		let postal = try await makeClient(StubTransport(body: body)).postal("12345", deep: true)
		#expect(postal.deep?.tax == "Sales tax" && postal.deep?.taxRate == 7.9)
		#expect(postal.deep?.taxRateState == 5 && postal.deep?.taxRateCounty == 0)
		#expect(postal.deep?.taxRateCity == nil && postal.deep?.taxRateSpecial == 2.9)
	}

	@Test func omittedLockedAndUnknownTaxStayDistinct() async throws {
		for field in ["", #", "deep":{}"#, #", "deep":{"tax":null,"tax_rate":null}"#] {
			let postal = try await makeClient(StubTransport(body: #"{"postal":"12345","country":"US""# + field + "}")).postal("12345")
			#expect(postal.deep?.tax == nil && postal.deep?.taxRate == nil)
			#expect((postal.deep == nil) == field.isEmpty)
			let country = try await makeClient(StubTransport(body: #"{"country":"DE","name":"Germany","continent":"EU""# + field + "}")).country("DE")
			#expect(country.deep?.tax == nil && country.deep?.taxRate == nil)
			#expect((country.deep == nil) == field.isEmpty)
		}
	}
}
