import Foundation
import Testing
@testable import ParseAPI
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

private let currencyRateFixture = #"{"base":"USD","quote":"JPY","rate":148.99,"date":"2026-10-09","converted":null,"requested_date":"2026-10-10","stale":true,"dates":{"base":["2026-10-08","2026-10-09"]},"units":{"quote":"indexed_unit"},"future":true}"#

@Suite struct CurrencyReference {
	private func captured(_ name: String) throws -> String {
		try String(contentsOf: URL(fileURLWithPath: #filePath).deletingLastPathComponent().appendingPathComponent("Fixtures/\(name).json"), encoding: .utf8)
	}
	@Test func currentCollectionsAndUnitsDecodeCapturedApiBodies() async throws {
		let catalog = StubTransport(body: try captured("currencies"))
		#expect(try await makeClient(catalog).currencyList(q: "dollar", country: "US", deep: true, lang: "fr").data.count == 2)
		#expect(catalog.requests[0].url?.path == "/currency")
		#expect(catalog.requests[0].url?.query == "q=dollar&country=US&deep=true&lang=fr")
		let rates = StubTransport(body: try captured("rates"))
		#expect(try await makeClient(rates).currencyRates("USD").rates.count == 46)
		#expect(rates.requests[0].url?.query == nil)
		let metal = StubTransport(body: try captured("metal"))
		let gold = try await makeClient(metal).currencyRate("USD", "XAU", amount: 100)
		#expect(gold.converted == nil && gold.units?.quote == "troy_ounce")
	}
	@Test func oldRateFunctionReferenceAndDefaultsRemainAvailable() async throws {
		let stub = StubTransport(body: #"{"base":"USD","quote":"EUR","rate":0.85,"date":"2026-10-09"}"#)
		let client = try makeClient(stub)
		let old: (String, String, String?, Double?) async throws -> CurrencyRate = client.currencyRate
		let rate = try await old("USD", "EUR", nil, nil)
		#expect(rate.rate == 0.85 && rate.stale == nil)
		_ = try await client.currencyRate("USD", "EUR")
		#expect(stub.requests.count == 2 && stub.requests.allSatisfy { $0.url?.query == nil })
	}
	@Test func sourceAndEvidenceKeepDatesUnknownsAndZero() async throws {
		let stub = StubTransport(body: currencyRateFixture)
		let client = try makeClient(stub)
		let rate = try await client.currencyRate("U/S", "JPY", date: "2026-10-10", amount: 0)
		#expect(stub.requests[0].url?.absoluteString == "https://api.parseapi.com/currency/U%2FS/JPY?date=2026-10-10&amount=0")
		#expect(rate.converted == nil && rate.date == "2026-10-09" && rate.stale == true)
		#expect(rate.dates?.base == ["2026-10-08", "2026-10-09"] && rate.units?.quote == "indexed_unit")
		_ = try await client.currencyRate("USD", "JPY")
		#expect(stub.requests[1].url?.query == nil)
	}
	@Test func batchRetainsPartialMissingAndNullableDate() async throws {
		let stub = StubTransport(body: #"{"base":"USD","rates":{},"missing":[{"quote":"XCG","reason":"rate_unavailable"}]}"#)
		let result = try await makeClient(stub).currencyRates("USD", quotes: ["JPY", "XCG"], amount: 0)
		#expect(result.requestedDate == nil && result.missing[0].quote == "XCG" && result.rates.isEmpty)
		#expect(stub.requests[0].url?.query == "quotes=JPY%2CXCG&amount=0")
	}
	@Test func historiesRetainRequestedCalendarDaysAndGaps() async throws {
		let pair = StubTransport(body: "{\"base\":\"USD\",\"quote\":\"JPY\",\"from\":\"2026-10-09\",\"to\":\"2026-10-10\",\"data\":[\(currencyRateFixture)],\"missing\":[\"2026-10-09\"]}")
		let history = try await makeClient(pair).currencyHistory("USD", "JPY", from: "2026-10-09", to: "2026-10-10")
		#expect(history.data[0].requestedDate == "2026-10-10" && history.missing == ["2026-10-09"])
		#expect(pair.requests[0].url?.query == "from=2026-10-09&to=2026-10-10")
		let multi = StubTransport(body: #"{"base":"USD","quotes":["JPY","XCG"],"from":"2026-10-09","to":"2026-10-10","data":[],"missing":[{"requested_date":"2026-10-10","quote":"XCG","reason":"future-reason"}]}"#)
		let result = try await makeClient(multi).currencyRatesHistory("USD", quotes: ["JPY", "XCG"], from: "2026-10-09", to: "2026-10-10", amount: 0)
		#expect(result.missing[0].requestedDate == "2026-10-10" && result.missing[0].reason == "future-reason")
		#expect(multi.requests[0].url?.path == "/currency/USD/rates/history")
	}
	@Test func sampledHistoryAndCompleteReportsKeepOriginalDatesAndGaps() async throws {
		let pair = StubTransport(body: try captured("sampled-history"))
		let history = try await makeClient(pair).currencyHistory("USD", "EUR", from: "1971-01-04", to: "2026-10-02",  interval: "month")
		#expect(history.interval == "month" && history.data[1].date == "2024-01-07" && history.data[1].stale == true)
		#expect(history.missing == ["2024-02-15"] && pair.requests[0].url?.query == "from=1971-01-04&to=2026-10-02&interval=month")
		let summary = StubTransport(body: try captured("period-summary"))
		let report = try await makeClient(summary).currencyRatesSummary("U/S", quotes: ["EUR", "JPY", "XCG"], from: "2024-01-01", to: "2024-02-15")
		#expect(report.interval == "month" && report.data[0].average == 0.825 && report.data[0].observationCount == 2)
		#expect(report.data[0].min == 0.8 && report.data[0].max == 0.85 && report.data[0].missingDayCount == 1)
		#expect(report.data[0].firstDate == "2024-01-02" && report.data[0].lastDate == "2024-01-07")
		#expect(report.data[0].stale == nil && report.data[0].units == nil && report.missing.count == 4)
		#expect(report.missing[1].reason == "no_observations" && report.missing[0].missingDayCount == 31)
		#expect(summary.requests[0].url?.absoluteString == "https://api.parseapi.com/currency/U%2FS/rates/summary?quotes=EUR%2CJPY%2CXCG&from=2024-01-01&to=2024-02-15&interval=month")
	}
	@Test func oldHistoryFunctionReferenceRemainsAvailable() async throws {
		let stub = StubTransport(body: try captured("sampled-history"))
		let client = try makeClient(stub)
		let old: (String, String, String, String, Double?, String?, Bool?) async throws -> CurrencyHistory = client.currencyHistory
		_ = try await old("USD", "EUR", "2024-01-01", "2024-01-31", nil, nil, nil)
		#expect(stub.requests[0].url?.query == "from=2024-01-01&to=2024-01-31")
	}

}
