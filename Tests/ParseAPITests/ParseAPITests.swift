import Foundation
import Testing
@testable import ParseAPI
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Thread-safe recorder for the stubbed transport.
final class StubTransport: @unchecked Sendable {
	private let lock = NSLock()
	private var recorded: [URLRequest] = []
	private var responses: [(status: Int, body: String, headers: [String: String])]

	init(_ responses: [(status: Int, body: String, headers: [String: String])]) {
		self.responses = responses
	}

	convenience init(status: Int = 200, body: String = "{}") {
		self.init([(status, body, [:])])
	}

	var requests: [URLRequest] {
		lock.lock()
		defer { lock.unlock() }
		return recorded
	}

	private func record(_ request: URLRequest) -> (status: Int, body: String, headers: [String: String]) {
		lock.lock()
		defer { lock.unlock() }
		recorded.append(request)
		return responses.count > 1 ? responses.removeFirst() : responses[0]
	}

	var transport: ParseAPITransport {
		{ request in
			let next = self.record(request)
			let response = HTTPURLResponse(
				url: request.url!,
				statusCode: next.status,
				httpVersion: "HTTP/1.1",
				headerFields: next.headers
			)!
			return (Data(next.body.utf8), response)
		}
	}
}

func makeClient(
	_ stub: StubTransport,
	key: String = "parse_testtesttesttest",
	appId: String? = nil,
	retries: Int = 0
) throws -> ParseAPI {
	try ParseAPI(key, appId: appId, baseURL: "https://api.parseapi.com", retries: retries, transport: stub.transport)
}

@Suite struct URLMapping {
	@Test func ipPath() async throws {
		let stub = StubTransport(body: #"{"ip":"8.8.8.8","country":null,"country_name":null,"continent":null,"asn":null,"asn_name":null}"#)
		_ = try await makeClient(stub).ip("8.8.8.8")
		#expect(stub.requests[0].url!.absoluteString == "https://api.parseapi.com/ip/8.8.8.8")
	}

	@Test func ipSelfBarePath() async throws {
		let stub = StubTransport(body: #"{"ip":"1.2.3.4","country":null,"country_name":null,"continent":null,"asn":null,"asn_name":null}"#)
		_ = try await makeClient(stub).ipSelf()
		#expect(stub.requests[0].url!.absoluteString == "https://api.parseapi.com/ip")
	}

	@Test func timezoneEncodesSlash() async throws {
		let stub = StubTransport(body: #"{"timezone":"America/New_York","name":null,"abbreviation":null,"offset":null,"offset_minutes":null,"dst":null,"next_dst":null}"#)
		_ = try await makeClient(stub).timezone("America/New_York")
		#expect(stub.requests[0].url!.absoluteString == "https://api.parseapi.com/timezone/America%2FNew_York")
	}

	@Test func emailEncodesAt() async throws {
		let stub = StubTransport(body: #"{"email":"a@b.com","didyoumean":null,"valid":true,"domain":"b.com","domain_valid":true,"role":false,"disposable":false}"#)
		_ = try await makeClient(stub).email("a@b.com")
		#expect(stub.requests[0].url!.absoluteString == "https://api.parseapi.com/email/a%40b.com")
	}

	@Test func phoneEncodesPlus() async throws {
		let stub = StubTransport(body: #"{"phone":"+14155552671","valid":true,"country":"US"}"#)
		_ = try await makeClient(stub).phone("+14155552671")
		#expect(stub.requests[0].url!.absoluteString == "https://api.parseapi.com/phone/%2B14155552671")
	}

	@Test func stateSendsCountry() async throws {
		let stub = StubTransport(body: #"{"state":"NC","name":"North Carolina","local_name":null,"type":null,"country":"US","country_name":null,"latitude":null,"longitude":null,"population":null,"area":null,"timezone":null}"#)
		_ = try await makeClient(stub).state("NC", country: "US")
		#expect(stub.requests[0].url!.absoluteString == "https://api.parseapi.com/state/NC?country=US")
	}

	@Test func citySearchQuery() async throws {
		let stub = StubTransport(body: #"{"q":"char","cities":[]}"#)
		_ = try await makeClient(stub).citySearch("char", country: "US", limit: 5)
		#expect(stub.requests[0].url!.absoluteString == "https://api.parseapi.com/city?q=char&country=US&limit=5")
	}

	@Test func cityIdPath() async throws {
		let stub = StubTransport(body: #"{"name":"Charlotte","local_name":null,"state":"NC","state_name":null,"country":"US","latitude":null,"longitude":null,"population":null,"timezone":null,"id":"city_abcdefabcdef"}"#)
		_ = try await makeClient(stub).cityId("city_abcdefabcdef")
		#expect(stub.requests[0].url!.absoluteString == "https://api.parseapi.com/city/id/city_abcdefabcdef")
	}

	@Test func pointCoordsAndDeep() async throws {
		let stub = StubTransport(body: #"{"latitude":36.07,"longitude":-79.79,"country":"US","country_name":null,"state":null,"state_name":null,"district":null,"district_name":null,"elevation":null,"elevation_ft":null,"resolution":null,"deep":{}}"#)
		_ = try await makeClient(stub).point(36.07, -79.79, deep: true)
		#expect(stub.requests[0].url!.absoluteString == "https://api.parseapi.com/point?lat=36.07&lon=-79.79&deep=true")
	}

	@Test func deepOmittedWhenFalse() async throws {
		let stub = StubTransport(body: #"{"ip":"8.8.8.8","country":null,"country_name":null,"continent":null,"asn":null,"asn_name":null}"#)
		_ = try await makeClient(stub).ip("8.8.8.8", deep: false)
		#expect(stub.requests[0].url!.absoluteString == "https://api.parseapi.com/ip/8.8.8.8")
	}

	@Test func wholeNumberCoordsStayClean() async throws {
		let stub = StubTransport(body: #"{"latitude":40,"longitude":-74,"elevation":null,"elevation_ft":null,"resolution":null}"#)
		_ = try await makeClient(stub).elevation(40, -74)
		#expect(stub.requests[0].url!.absoluteString == "https://api.parseapi.com/elevation?lat=40&lon=-74")
	}

	@Test func postalDistancePath() async throws {
		let stub = StubTransport(body: #"{"country":"US","from":{"postal":"28202","city":null},"to":{"postal":"10001","city":null},"distance":1,"distance_mi":1}"#)
		_ = try await makeClient(stub).postalDistance("28202", "10001", country: "US")
		#expect(stub.requests[0].url!.absoluteString == "https://api.parseapi.com/postal/28202/distance/10001?country=US")
	}
}

@Suite struct Headers {
	@Test func apiKeyAndUserAgent() async throws {
		let stub = StubTransport(body: #"{"domain":"x.com","available":false}"#)
		_ = try await makeClient(stub).domain("x.com")
		let request = stub.requests[0]
		#expect(request.value(forHTTPHeaderField: "X-API-Key") == "parse_testtesttesttest")
		#expect(request.value(forHTTPHeaderField: "User-Agent") == "parseapi-swift/\(ParseAPI.version)")
		#expect(request.value(forHTTPHeaderField: "X-App-Id") == nil)
	}

	@Test func appIdHeaderWhenSet() async throws {
		let stub = StubTransport(body: #"{"domain":"x.com","available":false}"#)
		_ = try await makeClient(stub, appId: "com.example.weather").domain("x.com")
		#expect(stub.requests[0].value(forHTTPHeaderField: "X-App-Id") == "com.example.weather")
	}

	@Test func useragentReplacesUA() async throws {
		let stub = StubTransport(body: #"{"useragent":"x","device":null,"os":null,"browser":null,"bot":false,"mobile":false}"#)
		_ = try await makeClient(stub).useragent("SomeAgent/1.0")
		#expect(stub.requests[0].value(forHTTPHeaderField: "User-Agent") == "SomeAgent/1.0")
	}
}

@Suite struct Errors {
	@Test func honest404() async throws {
		let stub = StubTransport(status: 404, body: #"{"code":"not_found","message":"City not found","docs":"https://parseapi.com/docs#not_found","request_id":"req_123"}"#)
		do {
			_ = try await makeClient(stub).city("nowhere")
			Issue.record("expected ParseAPIError")
		} catch let error as ParseAPIError {
			#expect(error.status == 404)
			#expect(error.code == "not_found")
			#expect(error.requestId == "req_123")
			#expect(error.docs == "https://parseapi.com/docs#not_found")
		}
	}

	@Test func nonJSONErrorBody() async throws {
		let stub = StubTransport(status: 400, body: "boom")
		do {
			_ = try await makeClient(stub).country("US")
			Issue.record("expected ParseAPIError")
		} catch let error as ParseAPIError {
			#expect(error.code == "unknown_error")
			#expect(error.status == 400)
		}
	}

	@Test func missingKeyThrowsAtConstruction() throws {
		unsetenv("PARSEAPI_KEY")
		do {
			_ = try ParseAPI(nil, appId: nil)
			Issue.record("expected ParseAPIError")
		} catch let error as ParseAPIError {
			#expect(error.code == "missing_api_key")
		}
		setenv("PARSEAPI_KEY", "parse_envenvenvenvenv0", 1)
		defer { unsetenv("PARSEAPI_KEY") }
		_ = try ParseAPI(nil, appId: nil)
	}
}

@Suite struct Retries {
	@Test func retriesOn503ThenSucceeds() async throws {
		let stub = StubTransport([
			(503, "{}", [:]),
			(503, "{}", [:]),
			(200, #"{"domain":"x.com","available":false}"#, [:]),
		])
		let client = try ParseAPI("parse_testtesttesttest", appId: nil, baseURL: "https://api.parseapi.com", retries: 2, transport: stub.transport)
		let result = try await client.domain("x.com")
		#expect(result.available == false)
		#expect(stub.requests.count == 3)
	}

	@Test func noRetryWhenDisabled() async throws {
		let stub = StubTransport(status: 503, body: "{}")
		do {
			_ = try await makeClient(stub, retries: 0).domain("x.com")
			Issue.record("expected ParseAPIError")
		} catch let error as ParseAPIError {
			#expect(error.status == 503)
		}
		#expect(stub.requests.count == 1)
	}

	@Test func honorsRetryAfterZero() async throws {
		let stub = StubTransport([
			(429, "{}", ["Retry-After": "0"]),
			(200, #"{"domain":"x.com","available":false}"#, [:]),
		])
		let client = try ParseAPI("parse_testtesttesttest", appId: nil, baseURL: "https://api.parseapi.com", retries: 2, transport: stub.transport)
		_ = try await client.domain("x.com")
		#expect(stub.requests.count == 2)
	}

	@Test func no404Retry() async throws {
		let stub = StubTransport(status: 404, body: #"{"code":"not_found","message":"nope"}"#)
		let client = try ParseAPI("parse_testtesttesttest", appId: nil, baseURL: "https://api.parseapi.com", retries: 2, transport: stub.transport)
		do {
			_ = try await client.country("XX")
		} catch let error as ParseAPIError {
			#expect(error.code == "not_found")
		}
		#expect(stub.requests.count == 1)
	}
}

@Suite struct Decoding {
	@Test func snakeCaseFields() async throws {
		let stub = StubTransport(body: #"{"ip":"8.8.8.8","country":"US","country_name":"United States","continent":"NA","asn":"AS15169","asn_name":"Google","deep":{"state":"CA","datacenter":true}}"#)
		let result = try await makeClient(stub).ip("8.8.8.8", deep: true)
		#expect(result.countryName == "United States")
		#expect(result.asnName == "Google")
		#expect(result.deep?.state == "CA")
		#expect(result.deep?.datacenter == true)
		#expect(result.deep?.vpn == nil)
	}

	@Test func deepTriad() async throws {
		let locked = StubTransport(body: #"{"ip":"8.8.8.8","country":null,"country_name":null,"continent":null,"asn":null,"asn_name":null,"deep":{}}"#)
		let lockedResult = try await makeClient(locked).ip("8.8.8.8", deep: true)
		#expect(lockedResult.deep != nil)
		#expect(lockedResult.deep?.datacenter == nil)

		let omitted = StubTransport(body: #"{"ip":"8.8.8.8","country":null,"country_name":null,"continent":null,"asn":null,"asn_name":null}"#)
		let omittedResult = try await makeClient(omitted).ip("8.8.8.8")
		#expect(omittedResult.deep == nil)
	}

	@Test func nullRegionsArray() async throws {
		let stub = StubTransport(body: #"{"country":"US","date":"2026-12-25","holiday":{"date":"2026-12-25","name":"Christmas Day","local_name":null,"type":"public","regions":null,"substitute":false}}"#)
		let result = try await makeClient(stub).holidayDate("US", "2026-12-25")
		#expect(result.holiday?.regions == nil)
		#expect(result.holiday?.name == "Christmas Day")
	}

	@Test func unknownFieldsIgnored() async throws {
		let stub = StubTransport(body: #"{"domain":"x.com","available":false,"some_future_field":{"a":1}}"#)
		let result = try await makeClient(stub).domain("x.com")
		#expect(result.domain == "x.com")
	}

	@Test func weatherRooms() async throws {
		let stub = StubTransport(body: #"{"latitude":40.71,"longitude":-74.01,"current":{"temperature":21.7,"temperature_f":71.1,"feels_like":21.7,"feels_like_f":71.1,"dewpoint":null,"dewpoint_f":null,"humidity":63,"wind_speed":9.3,"wind_speed_mph":5.8,"wind_gust":null,"wind_gust_mph":null,"wind_direction":180,"pressure":1017.2,"pressure_inhg":30.04,"visibility":16.1,"visibility_mi":10,"condition":"clear","condition_name":"Clear","condition_emoji":"C","observed_at":"2026-08-28T12:51:00Z"},"station":{"id":"KNYC","name":"New York City, Central Park","distance":4.3,"distance_mi":2.7},"source":{"id":"nws","name":"US National Weather Service"}}"#)
		let result = try await makeClient(stub).weather(40.71, -74.01)
		#expect(result.current.temperatureF == 71.1)
		#expect(result.station?.id == "KNYC")
		#expect(result.source.id == "nws")
		#expect(result.deep == nil)
	}
}
