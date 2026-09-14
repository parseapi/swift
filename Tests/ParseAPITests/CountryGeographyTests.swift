import Testing
@testable import ParseAPI

@Suite struct CountryGeography {
	@Test func decimalsZeroAndNegativeElevation() async throws {
		let body = #"{"country":"XX","name":"Test Country","continent":"NA","deep":{"land_area":10010.5,"water_area":0,"coastline":0,"elevation":0,"lowest_point":{"name":null,"elevation":-430.5},"highest_point":{"name":"Summit","elevation":8848.86}}}"#
		let country = try await makeClient(StubTransport(body: body)).country("XX", deep: true)
		#expect(country.deep?.landArea == 10010.5)
		#expect(country.deep?.waterArea == 0 && country.deep?.coastline == 0 && country.deep?.elevation == 0)
		#expect(country.deep?.lowestPoint?.name == nil && country.deep?.lowestPoint?.elevation == -430.5)
		#expect(country.deep?.highestPoint?.name == "Summit" && country.deep?.highestPoint?.elevation == 8848.86)
	}

	@Test func olderLockedAndNullGeography() async throws {
		for field in ["", #", "deep":{}"#, #", "deep":{"land_area":null,"water_area":null,"coastline":null,"elevation":null,"lowest_point":null,"highest_point":null}"#] {
			let body = #"{"country":"XX","name":"Test Country","continent":"NA""# + field + "}"
			let country = try await makeClient(StubTransport(body: body)).country("XX")
			#expect((country.deep == nil) == field.isEmpty)
			#expect(country.deep?.landArea == nil && country.deep?.waterArea == nil)
			#expect(country.deep?.coastline == nil && country.deep?.elevation == nil)
			#expect(country.deep?.lowestPoint == nil && country.deep?.highestPoint == nil)
		}
	}
}
