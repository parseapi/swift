import Foundation
import Testing
@testable import ParseAPI
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

private actor CallCount {
	var value = 0
	func increment() { value += 1 }
}

@Suite struct Stability {
	@Test func dateEncodingAndCalendarFields() async throws {
		let stub = StubTransport(body: #"{"date":"2026-03-04","valid":true,"month_name":"March","week_year":2026,"days_in_month":31,"unix":1772582400,"to":"2026-03-09","days":5}"#)
		let value = try await makeClient(stub).date("03/04/2026", format: "mdy", to: "2026-03-09")
		#expect(stub.requests.count == 1)
		#expect(stub.requests[0].url?.absoluteString == "https://api.parseapi.com/date/03%2F04%2F2026?format=mdy&to=2026-03-09")
		#expect(value.monthName == "March")
		#expect(value.weekYear == 2026)
		#expect(value.daysInMonth == 31)
		#expect(value.days == 5)
	}

	@Test func invalidDateAndTodayAreSeparateCalls() async throws {
		let invalid = StubTransport(body: #"{"date":"03/04/2026","valid":false,"year":null}"#)
		let value = try await makeClient(invalid).date("03/04/2026")
		#expect(value.valid == false)
		#expect(value.year == nil)
		let today = StubTransport(body: #"{"date":"2026-09-05","valid":true}"#)
		_ = try await makeClient(today).dateToday(to: "2026-12-25")
		#expect(today.requests[0].url?.absoluteString == "https://api.parseapi.com/date?to=2026-12-25")
	}

	@Test func blocAndMembers() async throws {
		let bloc = StubTransport(body: #"{"bloc":"EU","name":"European Union","members":27}"#)
		#expect(try await makeClient(bloc).bloc("EU").members == 27)
		#expect(bloc.requests[0].url?.path == "/bloc/EU")
		let members = StubTransport(body: #"{"bloc":"EU","countries":[{"country":"FR","name":"France","calling_code":"33"}]}"#)
		let result = try await makeClient(members).blocCountries("EU")
		#expect(members.requests[0].url?.path == "/bloc/EU/countries")
		#expect(result.countries[0].callingCode == "33")
	}

	@Test func countryStatesIsOneRequest() async throws {
		let stub = StubTransport(body: #"{"country":"US","states":[]}"#)
		_ = try await makeClient(stub).countryStates("US")
		#expect(stub.requests.count == 1)
		#expect(stub.requests[0].url?.path == "/country/US/states")
	}

	@Test func timezoneConversionIsOptional() async throws {
		let stub = StubTransport(body: #"{"timezone":"America/New_York","at":"2026-09-05T09:00:00-04:00","to":{"timezone":"Europe/London","offset":"+01:00","offset_minutes":60,"dst":true,"at":"2026-09-05T14:00:00+01:00"}}"#)
		let value = try await makeClient(stub).timezone("America/New_York", at: "2026-09-05T09:00:00", to: "Europe/London")
		#expect(value.to?.at == "2026-09-05T14:00:00+01:00")
		#expect(stub.requests[0].url?.absoluteString.hasSuffix("&to=Europe%2FLondon") == true)
		let previous = StubTransport(body: #"{"timezone":"America/New_York"}"#)
		#expect(try await makeClient(previous).timezone("America/New_York").to == nil)
	}

	@Test func weatherHistoryIsOptional() async throws {
		let stub = StubTransport(body: #"{"latitude":40,"longitude":-74,"current":{},"source":{"id":"example","name":"Example"},"deep":{"history":{"date":"2026-09-01","high_f":80,"wind_max_mph":20}}}"#)
		let value = try await makeClient(stub).weather(40, -74, deep: true, date: "2026-09-01")
		#expect(stub.requests[0].url?.absoluteString == "https://api.parseapi.com/weather?lat=40&lon=-74&date=2026-09-01&deep=true")
		#expect(value.deep?.history?.highF == 80)
		#expect(value.deep?.history?.windMaxMph == 20)
	}

	@Test func nullCoreCollectionsDecodeAsEmpty() async throws {
		let stub = StubTransport(body: #"{"country":"US","states":null,"future":{"x":1}}"#)
		#expect(try await makeClient(stub).countryStates("US").states.isEmpty)
		let missing = StubTransport(body: #"{"domain":"example.com"}"#)
		#expect(try await makeClient(missing).mx("example.com").mx.isEmpty)
	}

	@Test func malformedCollectionIsStillAnError() async throws {
		let stub = StubTransport(body: #"{"country":"US","states":"wrong"}"#)
		do {
			_ = try await makeClient(stub).countryStates("US")
			Issue.record("expected decoding error")
		} catch is DecodingError {}
		#expect(stub.requests.count == 1)
	}

	@Test func cancellationIsNotRetried() async throws {
		let calls = CallCount()
		let client = try ParseAPI("test", retries: 2, transport: { _ in
			await calls.increment()
			throw CancellationError()
		})
		do {
			_ = try await client.domain("example.com")
			Issue.record("expected cancellation")
		} catch is CancellationError {}
		#expect(await calls.value == 1)
	}

	@Test func cancelledURLRequestIsNotRetried() async throws {
		let calls = CallCount()
		let client = try ParseAPI("test", retries: 2, transport: { _ in
			await calls.increment()
			throw URLError(.cancelled)
		})
		do {
			_ = try await client.domain("example.com")
			Issue.record("expected cancellation")
		} catch let error as URLError {
			#expect(error.code == .cancelled)
		}
		#expect(await calls.value == 1)
	}

	@Test func redirectPolicyRejectsCredentialForwarding() async throws {
		let session = URLSession(configuration: .ephemeral)
		defer { session.invalidateAndCancel() }
		let origin = URL(string: "https://api.parseapi.com/domain/example.com")!
		let destination = URL(string: "https://other.example/collect")!
		var redirected = URLRequest(url: destination)
		redirected.setValue("test-key", forHTTPHeaderField: "X-API-Key")
		let response = HTTPURLResponse(url: origin, statusCode: 302, httpVersion: nil, headerFields: ["Location": destination.absoluteString])!
		let followed: Bool = await withCheckedContinuation { continuation in
			ParseAPIRedirectDelegate().urlSession(session, task: session.dataTask(with: origin), willPerformHTTPRedirection: response, newRequest: redirected) { request in
				continuation.resume(returning: request != nil)
			}
		}
		#expect(followed == false)
	}
}
