import Foundation
import Testing
@testable import ParseAPI

@Suite struct TariffTests {
	@Test func searchPreservesParentContextAndOlderResponses() async throws {
		for suffix in ["", #", "lineage":null"#] {
			let json = #"{"q":"horses","revision":"fixture","lines":[{"hts":"0101.29.00.90","description":"Other","general":null"# + suffix + "}]}"
			let result = try await makeClient(StubTransport(body: json)).tariffSearch("horses")
			#expect(result.lines[0].lineage == nil)
		}
		let stub = StubTransport(body: #"{"q":"horses & ponies","revision":"fixture","lines":[{"hts":"0101.29.00.90","description":"Other","general":null,"lineage":["Live horses","Other horses"],"future":true},{"hts":"0101","description":"Live horses","general":null,"lineage":[]}]}"#)
		let result = try await makeClient(stub).tariffSearch("horses & ponies")
		#expect(result.lines[0].lineage == ["Live horses", "Other horses"])
		#expect(result.lines[1].lineage == [])
		let params = URLComponents(url: stub.requests[0].url!, resolvingAgainstBaseURL: false)?.queryItems
		#expect(params == [URLQueryItem(name: "q", value: "horses & ponies")])
	}

	@Test func editionDateRoundtrip() async throws {
		let edition = String(repeating: "a", count: 64)
		let body = "{\"hts\":\"0101\",\"description\":\"Horses\",\"lineage\":[],\"revision\":\"fixture\",\"edition\":\"\(edition)\",\"date\":\"2026-09-15\",\"deep\":{\"reason\":\"future_reason\",\"effective_rate\":null,\"measures\":[]}}"
		let stub = StubTransport(body: body)
		let result = try await makeClient(stub).tariff("0101", deep: true, origin: "CA", edition: edition, date: "2026-09-15")
		#expect(result.edition == edition)
		#expect(result.date == "2026-09-15")
		#expect(result.deep?.reason == "future_reason")
		#expect(result.deep?.effectiveRate == nil)
		let params = Dictionary(uniqueKeysWithValues: URLComponents(url: stub.requests[0].url!, resolvingAgainstBaseURL: false)!.queryItems!.map { ($0.name, $0.value!) })
		#expect(params == ["deep": "true", "origin": "CA", "edition": edition, "date": "2026-09-15"])
		let searchStub = StubTransport(body: "{\"q\":\"horses\",\"revision\":\"fixture\",\"edition\":\"\(edition)\",\"date\":\"2026-09-15\",\"lines\":[]}")
		let search = try await makeClient(searchStub).tariffSearch("horses", edition: edition, date: "2026-09-15")
		#expect(search.edition == edition)
		#expect(search.date == "2026-09-15")
		let searchParams = Dictionary(uniqueKeysWithValues: URLComponents(url: searchStub.requests[0].url!, resolvingAgainstBaseURL: false)!.queryItems!.map { ($0.name, $0.value!) })
		#expect(searchParams == ["q": "horses", "edition": edition, "date": "2026-09-15"])
		let old = try await makeClient(StubTransport(body: #"{"hts":"0101","description":"Horses","lineage":[],"revision":"old","deep":{}}"#)).tariff("0101")
		#expect(old.edition == nil && old.date == nil && old.deep?.reason == nil)
	}

	@Test func ignoredSelectionIsRejected() async throws {
		let lookup = try makeClient(StubTransport(body: #"{"hts":"0101","description":"Horses","lineage":[],"revision":"old"}"#))
		do { _ = try await lookup.tariff("0101", edition: String(repeating: "a", count: 64)); Issue.record("Ignored edition accepted") }
		catch let error as ParseAPIError { #expect(error.code == "tariff_selection_mismatch"); #expect(error.status == 0) }
		let search = try makeClient(StubTransport(body: #"{"q":"horses","revision":"old","lines":[]}"#))
		do { _ = try await search.tariffSearch("horses", date: "2026-09-15"); Issue.record("Ignored date accepted") }
		catch let error as ParseAPIError { #expect(error.code == "tariff_selection_mismatch") }
	}

	@Test func dateSelectionRequiresExactEditionFingerprint() async throws {
		for edition in ["legacy", "", String(repeating: "A", count: 64), String(repeating: "a", count: 64) + "\n"] {
			let encodedEdition = edition.replacingOccurrences(of: "\n", with: "\\n")
			let lookup = try makeClient(StubTransport(body: "{\"hts\":\"0101\",\"description\":\"Horses\",\"lineage\":[],\"revision\":\"fixture\",\"edition\":\"\(encodedEdition)\",\"date\":\"2026-09-15\"}"))
			do { _ = try await lookup.tariff("0101", date: "2026-09-15"); Issue.record("Invalid edition accepted") }
			catch let error as ParseAPIError { #expect(error.code == "tariff_selection_mismatch"); #expect(error.status == 0) }
			let search = try makeClient(StubTransport(body: "{\"q\":\"horses\",\"revision\":\"fixture\",\"edition\":\"\(encodedEdition)\",\"date\":\"2026-09-15\",\"lines\":[]}"))
			do { _ = try await search.tariffSearch("horses", date: "2026-09-15"); Issue.record("Invalid edition accepted") }
			catch let error as ParseAPIError { #expect(error.code == "tariff_selection_mismatch"); #expect(error.status == 0) }
		}
	}

	@Test func explicitScopeAllowsConfirmedDateOrUndatedEdition() async throws {
		let edition = String(repeating: "0123456789abcdef", count: 4)
		for date in [nil, "2026-09-15"] as [String?] {
			let dateJSON = date.map { "\"\($0)\"" } ?? "null"
			let requestedEdition = date == nil ? edition : nil
			let lookup = try makeClient(StubTransport(body: "{\"hts\":\"0101\",\"description\":\"Horses\",\"lineage\":[],\"revision\":\"fixture\",\"edition\":\"\(edition)\",\"date\":\(dateJSON),\"deep\":{}}"))
			let result = try await lookup.tariff("0101", deep: true, edition: requestedEdition, date: date)
			#expect(result.edition == edition && result.date == date && result.deep?.reason == nil)
			let search = try makeClient(StubTransport(body: "{\"q\":\"horses\",\"revision\":\"fixture\",\"edition\":\"\(edition)\",\"date\":\(dateJSON),\"lines\":[]}"))
			let results = try await search.tariffSearch("horses", edition: requestedEdition, date: date)
			#expect(results.edition == edition && results.date == date)
		}
	}
}
