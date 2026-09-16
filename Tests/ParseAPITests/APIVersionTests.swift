import Foundation
import Testing
@testable import ParseAPI

@Suite struct APIVersionTests {
	@Test func contractPinSurvivesRetriesAndSelfLookup() async throws {
		let stub = StubTransport([
			(503, #"{"code":"unavailable","message":"Try again"}"#, ["Retry-After": "0"]),
			(200, #"{"ip":"192.0.2.1","country":null,"deep":{"datacenter":null},"future":true}"#, [:]),
		])
		let client = try makeClient(stub, key: "parse_app_version_test", appId: "com.example.version", retries: 1)
		let result = try await client.ipSelf(deep: true)
		#expect(result.ip == "192.0.2.1")
		#expect(result.country == nil)
		#expect(result.deep != nil)
		#expect(result.deep?.datacenter == nil)
		#expect(stub.requests.count == 2)
		for request in stub.requests {
			#expect(request.url?.absoluteString == "https://api.parseapi.com/ip?deep=true")
			#expect(request.value(forHTTPHeaderField: "Parse-Version") == "2.0.0")
			#expect(request.value(forHTTPHeaderField: "X-API-Key") == "parse_app_version_test")
			#expect(request.value(forHTTPHeaderField: "X-App-Id") == "com.example.version")
			#expect(request.value(forHTTPHeaderField: "User-Agent") == "parseapi-swift/\(ParseAPI.version)")
		}
	}

	@Test func contractPinWithUserAgentInput() async throws {
		let stub = StubTransport(body: #"{"useragent":"Example/1.0","bot":false,"mobile":false,"deep":{}}"#)
		_ = try await makeClient(stub, appId: "com.example.version").useragent("Example/1.0")
		let request = stub.requests[0]
		#expect(request.value(forHTTPHeaderField: "Parse-Version") == "2.0.0")
		#expect(request.value(forHTTPHeaderField: "User-Agent") == "Example/1.0")
		#expect(request.value(forHTTPHeaderField: "X-API-Key") == "parse_testtesttesttest")
		#expect(request.value(forHTTPHeaderField: "X-App-Id") == "com.example.version")
	}

	@Test(arguments: [400, 410]) func versionErrorDoesNotRetryOrFallBack(status: Int) async throws {
		let stub = StubTransport(status: status, body: #"{"code":"invalid_request","message":"Unsupported API version","request_id":"req_version"}"#)
		do {
			_ = try await makeClient(stub, retries: 2).ipSelf()
			Issue.record("Expected an API error")
		} catch let error as ParseAPIError {
			#expect(error.status == status)
			#expect(error.code == "invalid_request")
			#expect(error.requestId == "req_version")
		}
		#expect(stub.requests.count == 1)
		#expect(stub.requests[0].value(forHTTPHeaderField: "Parse-Version") == "2.0.0")
	}
}
