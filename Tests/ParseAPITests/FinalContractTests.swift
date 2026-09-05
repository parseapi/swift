import Foundation
import Testing
@testable import ParseAPI
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

@Suite struct FinalContract {
    @Test func meteredDefaultsDoNotRetry() async throws {
        let operations: [@Sendable (ParseAPI) async throws -> Void] = [
            { _ = try await $0.carrier("junk") },
            { _ = try await $0.caller("junk") },
            { _ = try await $0.hlr("junk") },
            { _ = try await $0.email("a@example.com", deep: true) },
            { _ = try await $0.vat("DE136695976", deep: true) },
            { _ = try await $0.address("123 Main St", deep: true) },
        ]
        for operation in operations {
            let stub = StubTransport(status: 503, body: "{}")
            let parse = try ParseAPI("test", transport: stub.transport)
            do { try await operation(parse); Issue.record("expected API error") }
            catch let error as ParseAPIError { #expect(error.status == 503) }
            #expect(stub.requests.count == 1)
        }
    }

    @Test func explicitRetryOverrideAppliesToMeteredCalls() async throws {
        let stub = StubTransport([(503, "{}", ["Retry-After": "0"]), (200, #"{"phone":"junk","valid":false}"#, [:])])
        _ = try await ParseAPI("test", retries: 1, transport: stub.transport).carrier("junk")
        #expect(stub.requests.count == 2)
    }

    @Test func ordinaryDefaultsKeepTwoRetries() async throws {
        let stub = StubTransport([
            (503, "{}", ["Retry-After": "0"]), (503, "{}", ["Retry-After": "0"]),
            (200, #"{"email":"a@example.com","valid":true,"role":false,"disposable":false}"#, [:]),
        ])
        _ = try await ParseAPI("test", transport: stub.transport).email("a@example.com")
        #expect(stub.requests.count == 3)
    }

    @Test func retryAfterDatesAndBounds() {
        #expect(ParseAPI.retryDelayNanos(attempt: 0, retryAfter: "Sun, 06 Nov 1994 08:49:37 GMT") == 0)
        #expect(ParseAPI.retryDelayNanos(attempt: 0, retryAfter: "Sunday, 06-Nov-94 08:49:37 GMT") == 0)
        #expect(ParseAPI.retryDelayNanos(attempt: 0, retryAfter: "Sun Nov 6 08:49:37 1994") == 0)
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
        let future = formatter.string(from: Date().addingTimeInterval(60))
        #expect(ParseAPI.retryDelayNanos(attempt: 0, retryAfter: future) == 5_000_000_000)
        #expect(ParseAPI.retryDelayNanos(attempt: 999, retryAfter: "NaN") <= 5_000_000_000)
    }

    @Test func invalidConfigurationFailsImmediately() {
        for timeout in [0.0, -1.0, Double.infinity, Double.nan] {
            #expect(throws: ParseAPIError.self) { try ParseAPI("test", timeout: timeout) }
        }
        #expect(throws: ParseAPIError.self) { try ParseAPI("test", retries: -1) }
        for url in ["", "relative/path", "ftp://example.com", "https://user:pass@example.com", "https://example.com?q=1", "https://example.com#x"] {
            #expect(throws: ParseAPIError.self) { try ParseAPI("test", baseURL: url) }
        }
    }

    @Test func addressCompanyAndSearchAreSingleLookups() async throws {
        let address = StubTransport(body: #"{"address":"123 Main St","valid":true,"registered":false,"country":"US","deep":{}}"#)
        let a = try await makeClient(address).address("123 Main St", country: "US", deep: true)
        #expect(a.valid)
        #expect(a.deep != nil)
        #expect(address.requests.count == 1)
        #expect(address.requests[0].url?.absoluteString.hasSuffix("/address/123%20Main%20St?country=US&deep=true") == true)
        let search = StubTransport(body: #"{"q":"123 Main","addresses":[{"address":"123 Main St","postal":"28202"}]}"#)
        let hits = try await makeClient(search).addressSearch("123 Main", country: "US", postal: "28202")
        #expect(hits.addresses[0].postal == "28202")
        #expect(search.requests.count == 1)
        let company = StubTransport(body: #"{"company":"01234567","valid":true,"deep":{"country":{"name":"United Kingdom","blocs":null,"tax":"VAT"}}}"#)
        let c = try await makeClient(company).company("01234567", country: "GB", deep: true)
        #expect(c.deep?.country?.blocs.isEmpty == true)
        #expect(company.requests.count == 1)
    }

    @Test func richerWeatherAndCountryFieldsDecode() async throws {
        let weather = StubTransport(body: #"{"latitude":40,"longitude":-74,"current":{},"source":{"id":"example","name":"Example"},"deep":{"minutes":[{"at":"2026-09-05T12:00Z","precipitation":0.2}],"hours":[{"at":"2026-09-05T12:00Z","feels_like":21,"wind_gust":30}],"days":[{"date":"2026-09-06","high":25}],"air":{"pm2_5":7.5}}}"#)
        let w = try await makeClient(weather).weather(40, -74, deep: true)
        #expect(w.deep?.minutes?.first?.precipitation == 0.2)
        #expect(w.deep?.hours?.first?.feelsLike == 21)
        #expect(w.deep?.hours?.first?.windGust == 30)
        #expect(w.deep?.days?.first?.high == 25)
        #expect(w.deep?.air?.pm25 == 7.5)
        let country = StubTransport(body: #"{"country":"FR","iso3":"FRA","numeric":250,"name":"France","continent":"EU","blocs":["EU","SCHENGEN"]}"#)
        #expect(try await makeClient(country).country("FR").blocs == ["EU", "SCHENGEN"])
    }

    @Test func junkAddressAndCompanyCanEchoNull() async throws {
        let address = StubTransport(body: #"{"address":null,"valid":false}"#)
        let a = try await makeClient(address).address(" ")
        #expect(a.address == nil)
        #expect(a.valid == false)
        let company = StubTransport(body: #"{"company":null,"valid":false}"#)
        let c = try await makeClient(company).company(" ")
        #expect(c.company == nil)
        #expect(c.valid == false)
    }
}
