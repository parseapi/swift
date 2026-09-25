import Foundation
import Testing
@testable import ParseAPI

@Suite struct LanguageOptions {
	@Test func everySupportedOperationKeepsLanguagePerRequest() async throws {
		let cases: [(String, (ParseAPI) async throws -> Void, (ParseAPI) async throws -> Void)] = [
			("continent", { _ = try await $0.continent("AF", lang: "fr-CA") }, { _ = try await $0.continent("AF") }),
			("continentCountries", { _ = try await $0.continentCountries("AF", lang: "fr-CA") }, { _ = try await $0.continentCountries("AF") }),
			("blocCountries", { _ = try await $0.blocCountries("EU", lang: "fr-CA") }, { _ = try await $0.blocCountries("EU") }),
			("country", { _ = try await $0.country("DE", lang: "fr-CA") }, { _ = try await $0.country("DE") }),
			("countryStates", { _ = try await $0.countryStates("US", lang: "fr-CA") }, { _ = try await $0.countryStates("US") }),
			("state", { _ = try await $0.state("CO", lang: "fr-CA") }, { _ = try await $0.state("CO") }),
			("stateDistricts", { _ = try await $0.stateDistricts("CO", lang: "fr-CA") }, { _ = try await $0.stateDistricts("CO") }),
			("district", { _ = try await $0.district("08031", lang: "fr-CA") }, { _ = try await $0.district("08031") }),
			("city", { _ = try await $0.city("Denver", lang: "fr-CA") }, { _ = try await $0.city("Denver") }),
			("cityId", { _ = try await $0.cityId("city_abcdefabcdef", lang: "fr-CA") }, { _ = try await $0.cityId("city_abcdefabcdef") }),
			("citySearch", { _ = try await $0.citySearch("München", lang: "fr-CA") }, { _ = try await $0.citySearch("München") }),
			("cityNearest", { _ = try await $0.cityNearest(39.77, -104.9, lang: "fr-CA") }, { _ = try await $0.cityNearest(39.77, -104.9) }),
			("cityNearby", { _ = try await $0.cityNearby("Denver", lang: "fr-CA") }, { _ = try await $0.cityNearby("Denver") }),
			("postal", { _ = try await $0.postal("SW1A 1AA", lang: "fr-CA") }, { _ = try await $0.postal("SW1A 1AA") }),
			("postalNearby", { _ = try await $0.postalNearby("SW1A 1AA", lang: "fr-CA") }, { _ = try await $0.postalNearby("SW1A 1AA") }),
			("postalDistance", { _ = try await $0.postalDistance("10001", "10002", lang: "fr-CA") }, { _ = try await $0.postalDistance("10001", "10002") }),
			("currency", { _ = try await $0.currency("EUR", lang: "fr-CA") }, { _ = try await $0.currency("EUR") }),
			("language", { _ = try await $0.language("de", lang: "fr-CA") }, { _ = try await $0.language("de") }),
			("date", { _ = try await $0.date("2026-09-15", lang: "fr-CA") }, { _ = try await $0.date("2026-09-15") }),
			("dateToday", { _ = try await $0.dateToday(lang: "fr-CA") }, { _ = try await $0.dateToday() }),
			("time", { _ = try await $0.time("America/Denver", lang: "fr-CA") }, { _ = try await $0.time("America/Denver") }),
			("timeAt", { _ = try await $0.timeAt(39.77, -104.9, lang: "fr-CA") }, { _ = try await $0.timeAt(39.77, -104.9) }),
			("timezone", { _ = try await $0.timezone("America/Denver", lang: "fr-CA") }, { _ = try await $0.timezone("America/Denver") }),
			("timezoneAt", { _ = try await $0.timezoneAt(39.77, -104.9, lang: "fr-CA") }, { _ = try await $0.timezoneAt(39.77, -104.9) }),
			("measureUnits", { _ = try await $0.measureUnits(lang: "fr-CA") }, { _ = try await $0.measureUnits() }),
			("emoji", { _ = try await $0.emoji("😀", lang: "fr-CA") }, { _ = try await $0.emoji("😀") }),
			("emojiSearch", { _ = try await $0.emojiSearch("visage heureux", lang: "fr-CA") }, { _ = try await $0.emojiSearch("visage heureux") }),
			("point", { _ = try await $0.point(39.77, -104.9, lang: "fr-CA") }, { _ = try await $0.point(39.77, -104.9) }),
			("ip", { _ = try await $0.ip("8.8.8.8", lang: "fr-CA") }, { _ = try await $0.ip("8.8.8.8") }),
			("ipSelf", { _ = try await $0.ipSelf(lang: "fr-CA") }, { _ = try await $0.ipSelf() }),
			("asn", { _ = try await $0.asn("15169", lang: "fr-CA") }, { _ = try await $0.asn("15169") }),
			("company", { _ = try await $0.company("01234567", lang: "fr-CA") }, { _ = try await $0.company("01234567") }),
			("npi", { _ = try await $0.provider("1881018208", lang: "fr-CA") }, { _ = try await $0.provider("1881018208") }),
		]
		for (name, localized, plain) in cases {
			// A normal API miss exercises request construction without inventing
			// a shared successful response shape for unrelated products.
			let stub = StubTransport(status: 404, body: #"{"code":"not_found","message":"Fixture miss"}"#)
			let client = try makeClient(stub)
			for call in [localized, plain] {
				do { try await call(client); Issue.record("expected fixture miss") }
				catch let error as ParseAPIError { #expect(error.status == 404) }
			}
			#expect(stub.requests.count == 2, "one request per call: \(name)")
			var first = URLComponents(url: stub.requests[0].url!, resolvingAgainstBaseURL: false)!
			let next = URLComponents(url: stub.requests[1].url!, resolvingAgainstBaseURL: false)!
			#expect(first.queryItems?.filter { $0.name == "lang" }.map(\.value) == ["fr-CA"], "language: \(name)")
			#expect(next.queryItems?.contains { $0.name == "lang" } != true, "no language leak: \(name)")
			let remaining = (first.queryItems ?? []).filter { $0.name != "lang" }
			first.queryItems = remaining.isEmpty ? nil : remaining
			#expect(first.url == next.url, "only the language query changes: \(name)")
		}
	}

	@Test func inputInterpretationAndEncodingRemainIndependent() async throws {
		let stub = StubTransport(body: #"{"date":"2026-04-03","valid":true,"measure":"1,5 m","type":"length","amount":"1.5","unit":"m","choices":[]}"#)
		let client = try makeClient(stub)
		_ = try await client.date("03/04/2026", format: "dmy", to: "2026-12-25", deep: true, lang: "fr&deep=false")
		let url = URLComponents(url: stub.requests[0].url!, resolvingAgainstBaseURL: false)!
		let items = url.queryItems ?? []
		#expect(url.percentEncodedPath == "/date/03%2F04%2F2026")
		#expect(items.filter { $0.name == "lang" }.map(\.value) == ["fr&deep=false"])
		#expect(items.filter { $0.name == "deep" }.map(\.value) == ["true"])
		#expect(items.first { $0.name == "format" }?.value == "dmy")
		_ = try await client.measure("1,5 m", locale: "de")
		#expect(stub.requests[1].url?.query == "locale=de")
	}

	@Test func originalFunctionReferencesRemainAvailable() async throws {
		let stub = StubTransport(status: 404, body: #"{"code":"not_found","message":"Fixture miss"}"#)
		let client = try makeClient(stub)
		let continent: (String) async throws -> Continent = client.continent
		let country: (String, Bool) async throws -> Country = client.country
		let date: (String, String?, String?, Bool) async throws -> DateInfo = client.date
		let units: (String?, String?, String?) async throws -> MeasureUnits = client.measureUnits
		_ = try? await continent("AF")
		_ = try? await country("DE", false)
		_ = try? await date("03/04/2026", "dmy", nil, false)
		_ = try? await units(nil, "length", nil)
		#expect(stub.requests.count == 4)
		#expect(stub.requests.allSatisfy { $0.url?.query?.contains("lang=") != true })
	}
}
