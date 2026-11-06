import Testing
@testable import ParseAPI

@Suite struct CountryGeography {
	@Test func decimalsZeroAndNegativeElevation() async throws {
		let body = #"{"country":"XX","name":"Test Country","continent":"NA","gdp_usd":30769700000000,"gdp_per_capita_usd":90026.5163,"population_growth_percent":-0.25,"urban_population_percent":0,"internet_users_percent":95.5,"land_area":10010.5,"water_area":0,"coastline":0,"elevation":0,"lowest_point":{"name":null,"elevation":-430.5},"highest_point":{"name":"Summit","elevation":8848.86}}"#
		let country = try await makeClient(StubTransport(body: body)).country("XX", deep: true)
 #expect(country.gdpUsd == 30769700000000)
 #expect(country.gdpPerCapitaUsd == 90026.5163)
 #expect(country.populationGrowthPercent == -0.25)
 #expect(country.urbanPopulationPercent == 0)
 #expect(country.internetUsersPercent == 95.5)
 #expect(country.landArea == 10010.5)
 #expect(country.waterArea == 0 && country.coastline == 0 && country.elevation == 0)
 #expect(country.lowestPoint?.name == nil && country.lowestPoint?.elevation == -430.5)
 #expect(country.highestPoint?.name == "Summit" && country.highestPoint?.elevation == 8848.86)
	}

	@Test func olderLockedAndNullGeography() async throws {
		for field in ["", #", "deep":{}"#, #", "deep":{"land_area":null,"water_area":null,"coastline":null,"elevation":null,"lowest_point":null,"highest_point":null}"#] {
			let body = #"{"country":"XX","name":"Test Country","continent":"NA""# + field + "}"
			let country = try await makeClient(StubTransport(body: body)).country("XX")
 #expect(country.landArea == nil && country.waterArea == nil)
 #expect(country.coastline == nil && country.elevation == nil)
 #expect(country.lowestPoint == nil && country.highestPoint == nil)
		}
	}
}
