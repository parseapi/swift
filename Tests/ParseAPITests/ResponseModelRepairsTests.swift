import Foundation
import Testing
@testable import ParseAPI

@Suite struct ResponseModelRepairs {
	@Test func postalCompactTaxDecodesThroughExistingOperation() async throws {
		for amount in [0.0, 1234.5] {
			let stub = StubTransport(body: "{\"postal\":\"01234\",\"country\":\"US\",\"currency\":\"USD\",\"property_tax\":{\"annual_median\":\(amount)}}")
			let result = try await makeClient(stub).postal("01234", country: "US", deep: true)
			#expect(result.postal == "01234")
			#expect(result.propertyTax?.annualMedian == amount)
			#expect(result.propertyTax?.currency == nil && result.propertyTax?.period == nil)
			#expect(result.currency == "USD")
			#expect(stub.requests.count == 1)
		}
	}

	@Test func postalUnknownLockedAndOlderTaxShapesRemainReadable() throws {
		let decoder = JSONDecoder()
		decoder.keyDecodingStrategy = .convertFromSnakeCase
		for suffix in ["", #", "deep": null"#, #", "deep": {}"#, #", "deep": {"property_tax": null}"#] {
			let result = try decoder.decode(Postal.self, from: Data((#"{"postal":"01234","country":"US""# + suffix + "}").utf8))
			#expect(result.propertyTax == nil)
		}
		let old = try decoder.decode(PostalPropertyTax.self, from: Data(#"{"annual_median":0,"currency":"USD","period":"2020-2024"}"#.utf8))
		#expect(old.annualMedian == 0)
		#expect(old.currency == "USD" && old.period == "2020-2024")
		let encoder = JSONEncoder()
		encoder.keyEncodingStrategy = .convertToSnakeCase
		let compact = try decoder.decode(PostalPropertyTax.self, from: Data(#"{"annual_median":0}"#.utf8))
		let encoded = try #require(JSONSerialization.jsonObject(with: encoder.encode(compact)) as? [String: Any])
		#expect(Set(encoded.keys) == ["annual_median"])
		let district = try decoder.decode(DistrictDeep.self, from: Data(#"{"property_tax":{"annual_median":0,"currency":"USD","period":"2020-2024"}}"#.utf8))
		#expect(district.propertyTax?.annualMedian == 0)
		#expect(district.propertyTax?.currency == "USD")
		#expect(district.propertyTax?.period == "2020-2024")
	}

	@Test func pointElectoralAndTerrainAreAvailableWithoutAnotherRequest() async throws {
		let stub = StubTransport(body: #"{"latitude":39.1,"longitude":-104.1,"country":"US","elevation":-5,"elevation_ft":-16.4,"city":null,"electoral":{"code":"0801","name":null,"congress":119}}"#)
		let point = try await makeClient(stub).point(39.1, -104.1, deep: true)
		#expect(point.electoral?.code == "0801")
		#expect(point.electoral?.name == nil)
		#expect(point.electoral?.congress == 119)
		#expect(point.elevation == -5)
		#expect(stub.requests.count == 1)
	}

	@Test func pointElectoralUnknownAndSparseMetadataRemainNullable() throws {
		let decoder = JSONDecoder()
		decoder.keyDecodingStrategy = .convertFromSnakeCase
		for body in [#"{}"#, #"{"electoral":null}"#, #"{"elevation":0}"#] {
			let deep = try decoder.decode(PointDeep.self, from: Data(body.utf8))
			#expect(deep.electoral == nil)
		}
		let sparse = try decoder.decode(PointDeep.self, from: Data(#"{"electoral":{"code":"0000","name":null,"congress":null}}"#.utf8))
		#expect(sparse.electoral?.code == "0000")
		#expect(sparse.electoral?.name == nil && sparse.electoral?.congress == nil)
	}

	@Test func addressExistingElectoralBranchIsRetained() throws {
		let decoder = JSONDecoder()
		decoder.keyDecodingStrategy = .convertFromSnakeCase
		for body in [#"{}"#, #"{"electoral":null}"#] {
			#expect(try decoder.decode(AddressDeep.self, from: Data(body.utf8)).electoral == nil)
		}
		let deep = try decoder.decode(AddressDeep.self, from: Data(#"{"electoral":{"code":"0801","name":null,"congress":119}}"#.utf8))
		#expect(deep.electoral?.code == "0801")
		#expect(deep.electoral?.name == nil && deep.electoral?.congress == 119)
	}
}
