import Foundation
import Testing
@testable import ParseAPI

@Suite struct ADPContracts {
	@Test func countryDepth() async throws {
		let decoder = JSONDecoder()
		decoder.keyDecodingStrategy = .convertFromSnakeCase
		let core = try decoder.decode(Country.self, from: Data(#"{"country":"ZZ","name":"Fixture","continent":"EU"}"#.utf8))
		let locked = try decoder.decode(Country.self, from: Data(#"{"country":"ZZ","name":"Fixture","continent":"EU","deep":{}}"#.utf8))
		let rich = try decoder.decode(Country.self, from: Data(#"{"country":"ZZ","name":"Fixture","continent":"EU","deep":{"numeric":0,"iso3":"ZZZ"}}"#.utf8))
		#expect(core.deep == nil)
		#expect(locked.deep != nil && locked.deep?.numeric == nil)
		#expect(rich.deep?.numeric == 0)
		for depth in [false, true] {
			let stub = StubTransport(body: #"{"country":"ZZ","name":"Fixture","continent":"EU","deep":{"numeric":0,"iso3":"ZZZ"}}"#)
			_ = try await makeClient(stub).country("ZZ", deep: depth)
			let query = URLComponents(url: stub.requests[0].url!, resolvingAgainstBaseURL: false)?.queryItems ?? []
			#expect(query.contains { $0.name == "deep" && $0.value == "true" } == depth)
			#expect(stub.requests.count == 1)
		}
	}

	@Test func stateDepth() async throws {
		let decoder = JSONDecoder()
		decoder.keyDecodingStrategy = .convertFromSnakeCase
		let core = try decoder.decode(State.self, from: Data(#"{"state":"X","name":"Fixture","country":"ZZ"}"#.utf8))
		let locked = try decoder.decode(State.self, from: Data(#"{"state":"X","name":"Fixture","country":"ZZ","deep":{}}"#.utf8))
		let rich = try decoder.decode(State.self, from: Data(#"{"state":"X","name":"Fixture","country":"ZZ","deep":{"population":0}}"#.utf8))
		#expect(core.deep == nil)
		#expect(locked.deep != nil && locked.deep?.population == nil)
		#expect(rich.deep?.population == 0)
		for depth in [false, true] {
			let stub = StubTransport(body: #"{"state":"X","name":"Fixture","country":"ZZ","deep":{"population":0}}"#)
			_ = try await makeClient(stub).state("X", deep: depth)
			let query = URLComponents(url: stub.requests[0].url!, resolvingAgainstBaseURL: false)?.queryItems ?? []
			#expect(query.contains { $0.name == "deep" && $0.value == "true" } == depth)
			#expect(stub.requests.count == 1)
		}
	}

	@Test func districtDepth() async throws {
		let decoder = JSONDecoder()
		decoder.keyDecodingStrategy = .convertFromSnakeCase
		let core = try decoder.decode(District.self, from: Data(#"{"district":"D1","name":"Fixture","country":"ZZ"}"#.utf8))
		let locked = try decoder.decode(District.self, from: Data(#"{"district":"D1","name":"Fixture","country":"ZZ","deep":{}}"#.utf8))
		let rich = try decoder.decode(District.self, from: Data(#"{"district":"D1","name":"Fixture","country":"ZZ","deep":{"population":0}}"#.utf8))
		#expect(core.deep == nil)
		#expect(locked.deep != nil && locked.deep?.population == nil)
		#expect(rich.deep?.population == 0)
		for depth in [false, true] {
			let stub = StubTransport(body: #"{"district":"D1","name":"Fixture","country":"ZZ","deep":{"population":0}}"#)
			_ = try await makeClient(stub).district("D1", deep: depth)
			let query = URLComponents(url: stub.requests[0].url!, resolvingAgainstBaseURL: false)?.queryItems ?? []
			#expect(query.contains { $0.name == "deep" && $0.value == "true" } == depth)
			#expect(stub.requests.count == 1)
		}
	}

	@Test func cityDepth() async throws {
		let decoder = JSONDecoder()
		decoder.keyDecodingStrategy = .convertFromSnakeCase
		let core = try decoder.decode(City.self, from: Data(#"{"name":"Fixture","country":"ZZ","id":null}"#.utf8))
		let locked = try decoder.decode(City.self, from: Data(#"{"name":"Fixture","country":"ZZ","id":null,"deep":{}}"#.utf8))
		let rich = try decoder.decode(City.self, from: Data(#"{"name":"Fixture","country":"ZZ","id":null,"deep":{"population":0}}"#.utf8))
		#expect(core.deep == nil)
		#expect(locked.deep != nil && locked.deep?.population == nil)
		#expect(rich.deep?.population == 0)
		for depth in [false, true] {
			let stub = StubTransport(body: #"{"name":"Fixture","country":"ZZ","id":null,"deep":{"population":0}}"#)
			_ = try await makeClient(stub).city("Fixture", deep: depth)
			let query = URLComponents(url: stub.requests[0].url!, resolvingAgainstBaseURL: false)?.queryItems ?? []
			#expect(query.contains { $0.name == "deep" && $0.value == "true" } == depth)
			#expect(stub.requests.count == 1)
		}
	}

	@Test func postalDepth() async throws {
		let decoder = JSONDecoder()
		decoder.keyDecodingStrategy = .convertFromSnakeCase
		let core = try decoder.decode(Postal.self, from: Data(#"{"postal":"12345","country":"ZZ"}"#.utf8))
		let locked = try decoder.decode(Postal.self, from: Data(#"{"postal":"12345","country":"ZZ","deep":{}}"#.utf8))
		let rich = try decoder.decode(Postal.self, from: Data(#"{"postal":"12345","country":"ZZ","deep":{"population":0,"neighbors":[]}}"#.utf8))
		#expect(core.deep == nil)
		#expect(locked.deep != nil && locked.deep?.population == nil)
		#expect(rich.deep?.population == 0)
		for depth in [false, true] {
			let stub = StubTransport(body: #"{"postal":"12345","country":"ZZ","deep":{"population":0,"neighbors":[]}}"#)
			_ = try await makeClient(stub).postal("12345", deep: depth)
			let query = URLComponents(url: stub.requests[0].url!, resolvingAgainstBaseURL: false)?.queryItems ?? []
			#expect(query.contains { $0.name == "deep" && $0.value == "true" } == depth)
			#expect(stub.requests.count == 1)
		}
	}

	@Test func pointDepth() async throws {
		let decoder = JSONDecoder()
		decoder.keyDecodingStrategy = .convertFromSnakeCase
		let core = try decoder.decode(Point.self, from: Data(#"{"latitude":0,"longitude":0,"timezone":"Etc/UTC"}"#.utf8))
		let locked = try decoder.decode(Point.self, from: Data(#"{"latitude":0,"longitude":0,"timezone":"Etc/UTC","deep":{}}"#.utf8))
		let rich = try decoder.decode(Point.self, from: Data(#"{"latitude":0,"longitude":0,"timezone":"Etc/UTC","deep":{"elevation":0,"elevation_ft":0,"resolution":30,"city":null}}"#.utf8))
		#expect(core.deep == nil)
		#expect(locked.deep != nil && locked.deep?.elevation == nil)
		#expect(rich.deep?.elevation == 0)
		for depth in [false, true] {
			let stub = StubTransport(body: #"{"latitude":0,"longitude":0,"timezone":"Etc/UTC","deep":{"elevation":0,"elevation_ft":0,"resolution":30,"city":null}}"#)
			_ = try await makeClient(stub).point(0, 0, deep: depth)
			let query = URLComponents(url: stub.requests[0].url!, resolvingAgainstBaseURL: false)?.queryItems ?? []
			#expect(query.contains { $0.name == "deep" && $0.value == "true" } == depth)
			#expect(stub.requests.count == 1)
		}
	}

	@Test func phoneDepth() async throws {
		let decoder = JSONDecoder()
		decoder.keyDecodingStrategy = .convertFromSnakeCase
		let core = try decoder.decode(Phone.self, from: Data(#"{"phone":"+123","valid":true}"#.utf8))
		let locked = try decoder.decode(Phone.self, from: Data(#"{"phone":"+123","valid":true,"deep":{}}"#.utf8))
		let rich = try decoder.decode(Phone.self, from: Data(#"{"phone":"+123","valid":true,"deep":{"state":"XY","timezone":null}}"#.utf8))
		#expect(core.deep == nil)
		#expect(locked.deep != nil && locked.deep?.state == nil)
		#expect(rich.deep?.state == "XY")
		for depth in [false, true] {
			let stub = StubTransport(body: #"{"phone":"+123","valid":true,"deep":{"state":"XY","timezone":null}}"#)
			_ = try await makeClient(stub).phone("+123", deep: depth)
			let query = URLComponents(url: stub.requests[0].url!, resolvingAgainstBaseURL: false)?.queryItems ?? []
			#expect(query.contains { $0.name == "deep" && $0.value == "true" } == depth)
			#expect(stub.requests.count == 1)
		}
	}

	@Test func carrierDepth() async throws {
		let decoder = JSONDecoder()
		decoder.keyDecodingStrategy = .convertFromSnakeCase
		let core = try decoder.decode(Carrier.self, from: Data(#"{"phone":"+123","valid":true}"#.utf8))
		let locked = try decoder.decode(Carrier.self, from: Data(#"{"phone":"+123","valid":true,"deep":{}}"#.utf8))
		let rich = try decoder.decode(Carrier.self, from: Data(#"{"phone":"+123","valid":true,"deep":{"city":"Fixture"}}"#.utf8))
		#expect(core.deep == nil)
		#expect(locked.deep != nil && locked.deep?.city == nil)
		#expect(rich.deep?.city == "Fixture")
		for depth in [false, true] {
			let stub = StubTransport(body: #"{"phone":"+123","valid":true,"deep":{"city":"Fixture"}}"#)
			_ = try await makeClient(stub).carrier("+123", deep: depth)
			let query = URLComponents(url: stub.requests[0].url!, resolvingAgainstBaseURL: false)?.queryItems ?? []
			#expect(query.contains { $0.name == "deep" && $0.value == "true" } == depth)
			#expect(stub.requests.count == 1)
		}
	}

	@Test func hLRDepth() async throws {
		let decoder = JSONDecoder()
		decoder.keyDecodingStrategy = .convertFromSnakeCase
		let core = try decoder.decode(HLR.self, from: Data(#"{"phone":"+123","valid":true,"live":false}"#.utf8))
		let locked = try decoder.decode(HLR.self, from: Data(#"{"phone":"+123","valid":true,"live":false,"deep":{}}"#.utf8))
		let rich = try decoder.decode(HLR.self, from: Data(#"{"phone":"+123","valid":true,"live":false,"deep":{"roaming":false,"mcc":null}}"#.utf8))
		#expect(core.deep == nil)
		#expect(locked.deep != nil && locked.deep?.roaming == nil)
		#expect(rich.deep?.roaming == false)
		for depth in [false, true] {
			let stub = StubTransport(body: #"{"phone":"+123","valid":true,"live":false,"deep":{"roaming":false,"mcc":null}}"#)
			_ = try await makeClient(stub).hlr("+123", deep: depth)
			let query = URLComponents(url: stub.requests[0].url!, resolvingAgainstBaseURL: false)?.queryItems ?? []
			#expect(query.contains { $0.name == "deep" && $0.value == "true" } == depth)
			#expect(stub.requests.count == 1)
		}
	}

	@Test func ibanDepth() async throws {
		let decoder = JSONDecoder()
		decoder.keyDecodingStrategy = .convertFromSnakeCase
		let core = try decoder.decode(Iban.self, from: Data(#"{"iban":"DE123","valid":true}"#.utf8))
		let locked = try decoder.decode(Iban.self, from: Data(#"{"iban":"DE123","valid":true,"deep":{}}"#.utf8))
		let rich = try decoder.decode(Iban.self, from: Data(#"{"iban":"DE123","valid":true,"deep":{"checksum":"00"}}"#.utf8))
		#expect(core.deep == nil)
		#expect(locked.deep != nil && locked.deep?.checksum == nil)
		#expect(rich.deep?.checksum == "00")
		for depth in [false, true] {
			let stub = StubTransport(body: #"{"iban":"DE123","valid":true,"deep":{"checksum":"00"}}"#)
			_ = try await makeClient(stub).iban("DE123", deep: depth)
			let query = URLComponents(url: stub.requests[0].url!, resolvingAgainstBaseURL: false)?.queryItems ?? []
			#expect(query.contains { $0.name == "deep" && $0.value == "true" } == depth)
			#expect(stub.requests.count == 1)
		}
	}

	@Test func npiDepth() async throws {
		let decoder = JSONDecoder()
		decoder.keyDecodingStrategy = .convertFromSnakeCase
		let core = try decoder.decode(Npi.self, from: Data(#"{"npi":"123","valid":true,"excluded":true}"#.utf8))
		let locked = try decoder.decode(Npi.self, from: Data(#"{"npi":"123","valid":true,"excluded":true,"deep":{}}"#.utf8))
		let rich = try decoder.decode(Npi.self, from: Data(#"{"npi":"123","valid":true,"excluded":true,"deep":{"deactivated_at":"2026-09-08"}}"#.utf8))
		#expect(core.deep == nil)
		#expect(locked.deep != nil && locked.deep?.deactivatedAt == nil)
		#expect(rich.deep?.deactivatedAt == "2026-09-08")
		for depth in [false, true] {
			let stub = StubTransport(body: #"{"npi":"123","valid":true,"excluded":true,"deep":{"deactivated_at":"2026-09-08"}}"#)
			_ = try await makeClient(stub).npi("123", deep: depth)
			let query = URLComponents(url: stub.requests[0].url!, resolvingAgainstBaseURL: false)?.queryItems ?? []
			#expect(query.contains { $0.name == "deep" && $0.value == "true" } == depth)
			#expect(stub.requests.count == 1)
		}
	}

	@Test func tariffDepth() async throws {
		let decoder = JSONDecoder()
		decoder.keyDecodingStrategy = .convertFromSnakeCase
		let core = try decoder.decode(Tariff.self, from: Data(#"{"hts":"0101","description":"Fixture","revision":"fixture","lineage":[]}"#.utf8))
		let locked = try decoder.decode(Tariff.self, from: Data(#"{"hts":"0101","description":"Fixture","revision":"fixture","lineage":[],"deep":{}}"#.utf8))
		let rich = try decoder.decode(Tariff.self, from: Data(#"{"hts":"0101","description":"Fixture","revision":"fixture","lineage":[],"deep":{"units":[],"special":"Free"}}"#.utf8))
		#expect(core.deep == nil)
		#expect(locked.deep != nil && locked.deep?.special == nil)
		#expect(rich.deep?.special == "Free")
		for depth in [false, true] {
			let stub = StubTransport(body: #"{"hts":"0101","description":"Fixture","revision":"fixture","lineage":[],"deep":{"units":[],"special":"Free"}}"#)
			_ = try await makeClient(stub).tariff("0101", deep: depth)
			let query = URLComponents(url: stub.requests[0].url!, resolvingAgainstBaseURL: false)?.queryItems ?? []
			#expect(query.contains { $0.name == "deep" && $0.value == "true" } == depth)
			#expect(stub.requests.count == 1)
		}
	}

	@Test func vinDepth() async throws {
		let decoder = JSONDecoder()
		decoder.keyDecodingStrategy = .convertFromSnakeCase
		let core = try decoder.decode(Vin.self, from: Data(#"{"vin":"123","valid":true,"year":2020}"#.utf8))
		let locked = try decoder.decode(Vin.self, from: Data(#"{"vin":"123","valid":true,"year":2020,"deep":{}}"#.utf8))
		let rich = try decoder.decode(Vin.self, from: Data(#"{"vin":"123","valid":true,"year":2020,"deep":{"doors":0,"recalls":[]}}"#.utf8))
		#expect(core.deep == nil)
		#expect(locked.deep != nil && locked.deep?.doors == nil)
		#expect(rich.deep?.doors == 0)
		for depth in [false, true] {
			let stub = StubTransport(body: #"{"vin":"123","valid":true,"year":2020,"deep":{"doors":0,"recalls":[]}}"#)
			_ = try await makeClient(stub).vin("123", deep: depth)
			let query = URLComponents(url: stub.requests[0].url!, resolvingAgainstBaseURL: false)?.queryItems ?? []
			#expect(query.contains { $0.name == "deep" && $0.value == "true" } == depth)
			#expect(stub.requests.count == 1)
		}
	}

	@Test func currencyDepth() async throws {
		let decoder = JSONDecoder()
		decoder.keyDecodingStrategy = .convertFromSnakeCase
		let core = try decoder.decode(Currency.self, from: Data(#"{"currency":"USD","name":"Fixture"}"#.utf8))
		let locked = try decoder.decode(Currency.self, from: Data(#"{"currency":"USD","name":"Fixture","deep":{}}"#.utf8))
		let rich = try decoder.decode(Currency.self, from: Data(#"{"currency":"USD","name":"Fixture","deep":{"numeric":0,"countries":[]}}"#.utf8))
		#expect(core.deep == nil)
		#expect(locked.deep != nil && locked.deep?.numeric == nil)
		#expect(rich.deep?.numeric == 0)
		for depth in [false, true] {
			let stub = StubTransport(body: #"{"currency":"USD","name":"Fixture","deep":{"numeric":0,"countries":[]}}"#)
			_ = try await makeClient(stub).currency("USD", deep: depth)
			let query = URLComponents(url: stub.requests[0].url!, resolvingAgainstBaseURL: false)?.queryItems ?? []
			#expect(query.contains { $0.name == "deep" && $0.value == "true" } == depth)
			#expect(stub.requests.count == 1)
		}
	}

	@Test func languageDepth() async throws {
		let decoder = JSONDecoder()
		decoder.keyDecodingStrategy = .convertFromSnakeCase
		let core = try decoder.decode(Language.self, from: Data(#"{"language":"en","name":"English","direction":"ltr"}"#.utf8))
		let locked = try decoder.decode(Language.self, from: Data(#"{"language":"en","name":"English","direction":"ltr","deep":{}}"#.utf8))
		let rich = try decoder.decode(Language.self, from: Data(#"{"language":"en","name":"English","direction":"ltr","deep":{"iso3":"eng","countries":[]}}"#.utf8))
		#expect(core.deep == nil)
		#expect(locked.deep != nil && locked.deep?.iso3 == nil)
		#expect(rich.deep?.iso3 == "eng")
		for depth in [false, true] {
			let stub = StubTransport(body: #"{"language":"en","name":"English","direction":"ltr","deep":{"iso3":"eng","countries":[]}}"#)
			_ = try await makeClient(stub).language("en", deep: depth)
			let query = URLComponents(url: stub.requests[0].url!, resolvingAgainstBaseURL: false)?.queryItems ?? []
			#expect(query.contains { $0.name == "deep" && $0.value == "true" } == depth)
			#expect(stub.requests.count == 1)
		}
	}

	@Test func nameDepth() async throws {
		let decoder = JSONDecoder()
		decoder.keyDecodingStrategy = .convertFromSnakeCase
		let core = try decoder.decode(Name.self, from: Data(#"{"name":"Fixture","valid":true}"#.utf8))
		let locked = try decoder.decode(Name.self, from: Data(#"{"name":"Fixture","valid":true,"deep":{}}"#.utf8))
		let rich = try decoder.decode(Name.self, from: Data(#"{"name":"Fixture","valid":true,"deep":{"known":false,"gender":null,"countries":[]}}"#.utf8))
		#expect(core.deep == nil)
		#expect(locked.deep != nil && locked.deep?.known == nil)
		#expect(rich.deep?.known == false)
		for depth in [false, true] {
			let stub = StubTransport(body: #"{"name":"Fixture","valid":true,"deep":{"known":false,"gender":null,"countries":[]}}"#)
			_ = try await makeClient(stub).name("Fixture", deep: depth)
			let query = URLComponents(url: stub.requests[0].url!, resolvingAgainstBaseURL: false)?.queryItems ?? []
			#expect(query.contains { $0.name == "deep" && $0.value == "true" } == depth)
			#expect(stub.requests.count == 1)
		}
	}

	@Test func timezoneDepth() async throws {
		let decoder = JSONDecoder()
		decoder.keyDecodingStrategy = .convertFromSnakeCase
		let core = try decoder.decode(Timezone.self, from: Data(#"{"timezone":"Etc/UTC","at":"1970-01-01T00:00:00+00:00","unix":0,"offset":"+00:00","dst":false}"#.utf8))
		let locked = try decoder.decode(Timezone.self, from: Data(#"{"timezone":"Etc/UTC","at":"1970-01-01T00:00:00+00:00","unix":0,"offset":"+00:00","dst":false,"deep":{}}"#.utf8))
		let rich = try decoder.decode(Timezone.self, from: Data(#"{"timezone":"Etc/UTC","at":"1970-01-01T00:00:00+00:00","unix":0,"offset":"+00:00","dst":false,"deep":{"offset_seconds":0,"next_dst":null}}"#.utf8))
		#expect(core.deep == nil)
		#expect(locked.deep != nil && locked.deep?.offsetSeconds == nil)
		#expect(rich.deep?.offsetSeconds == 0)
		for depth in [false, true] {
			let stub = StubTransport(body: #"{"timezone":"Etc/UTC","at":"1970-01-01T00:00:00+00:00","unix":0,"offset":"+00:00","dst":false,"deep":{"offset_seconds":0,"next_dst":null}}"#)
			_ = try await makeClient(stub).time("Etc/UTC", deep: depth)
			let query = URLComponents(url: stub.requests[0].url!, resolvingAgainstBaseURL: false)?.queryItems ?? []
			#expect(query.contains { $0.name == "deep" && $0.value == "true" } == depth)
			#expect(stub.requests.count == 1)
		}
	}

	@Test func dateInfoDepth() async throws {
		let decoder = JSONDecoder()
		decoder.keyDecodingStrategy = .convertFromSnakeCase
		let core = try decoder.decode(DateInfo.self, from: Data(#"{"date":"1970-01-01","valid":true,"unix":0}"#.utf8))
		let locked = try decoder.decode(DateInfo.self, from: Data(#"{"date":"1970-01-01","valid":true,"unix":0,"deep":{}}"#.utf8))
		let rich = try decoder.decode(DateInfo.self, from: Data(#"{"date":"1970-01-01","valid":true,"unix":0,"deep":{"year":1970}}"#.utf8))
		#expect(core.deep == nil)
		#expect(locked.deep != nil && locked.deep?.year == nil)
		#expect(rich.deep?.year == 1970)
		for depth in [false, true] {
			let stub = StubTransport(body: #"{"date":"1970-01-01","valid":true,"unix":0,"deep":{"year":1970}}"#)
			_ = try await makeClient(stub).date("1970-01-01", deep: depth)
			let query = URLComponents(url: stub.requests[0].url!, resolvingAgainstBaseURL: false)?.queryItems ?? []
			#expect(query.contains { $0.name == "deep" && $0.value == "true" } == depth)
			#expect(stub.requests.count == 1)
		}
	}

	@Test func weatherDepth() async throws {
		let decoder = JSONDecoder()
		decoder.keyDecodingStrategy = .convertFromSnakeCase
		let core = try decoder.decode(Weather.self, from: Data(#"{"latitude":0,"longitude":0,"current":{"temperature":0}}"#.utf8))
		let locked = try decoder.decode(Weather.self, from: Data(#"{"latitude":0,"longitude":0,"current":{"temperature":0},"deep":{}}"#.utf8))
		let rich = try decoder.decode(Weather.self, from: Data(#"{"latitude":0,"longitude":0,"current":{"temperature":0},"deep":{"current":{"dewpoint":0}}}"#.utf8))
		#expect(core.deep == nil)
		#expect(locked.deep != nil && locked.deep?.current?.dewpoint == nil)
		#expect(rich.deep?.current?.dewpoint == 0)
		for depth in [false, true] {
			let stub = StubTransport(body: #"{"latitude":0,"longitude":0,"current":{"temperature":0},"deep":{"current":{"dewpoint":0}}}"#)
			_ = try await makeClient(stub).weather(0, 0, deep: depth)
			let query = URLComponents(url: stub.requests[0].url!, resolvingAgainstBaseURL: false)?.queryItems ?? []
			#expect(query.contains { $0.name == "deep" && $0.value == "true" } == depth)
			#expect(stub.requests.count == 1)
		}
	}

	@Test func emojiDepth() async throws {
		let decoder = JSONDecoder()
		decoder.keyDecodingStrategy = .convertFromSnakeCase
		let core = try decoder.decode(Emoji.self, from: Data(#"{"emoji":"😀","name":"Fixture","shortcodes":[":grin:"]}"#.utf8))
		let locked = try decoder.decode(Emoji.self, from: Data(#"{"emoji":"😀","name":"Fixture","shortcodes":[":grin:"],"deep":{}}"#.utf8))
		let rich = try decoder.decode(Emoji.self, from: Data(#"{"emoji":"😀","name":"Fixture","shortcodes":[":grin:"],"deep":{"hex":"1F600","skins":[]}}"#.utf8))
		#expect(core.deep == nil)
		#expect(locked.deep != nil && locked.deep?.hex == nil)
		#expect(rich.deep?.hex == "1F600")
		for depth in [false, true] {
			let stub = StubTransport(body: #"{"emoji":"😀","name":"Fixture","shortcodes":[":grin:"],"deep":{"hex":"1F600","skins":[]}}"#)
			_ = try await makeClient(stub).emoji("😀", deep: depth)
			let query = URLComponents(url: stub.requests[0].url!, resolvingAgainstBaseURL: false)?.queryItems ?? []
			#expect(query.contains { $0.name == "deep" && $0.value == "true" } == depth)
			#expect(stub.requests.count == 1)
		}
	}

	@Test func companyDepth() async throws {
		let decoder = JSONDecoder()
		decoder.keyDecodingStrategy = .convertFromSnakeCase
		let core = try decoder.decode(Company.self, from: Data(#"{"company":"123","valid":true}"#.utf8))
		let locked = try decoder.decode(Company.self, from: Data(#"{"company":"123","valid":true,"deep":{}}"#.utf8))
		let rich = try decoder.decode(Company.self, from: Data(#"{"company":"123","valid":true,"deep":{"gst":false,"country_name":"Fixture"}}"#.utf8))
		#expect(core.deep == nil)
		#expect(locked.deep != nil && locked.deep?.gst == nil)
		#expect(rich.deep?.gst == false)
		for depth in [false, true] {
			let stub = StubTransport(body: #"{"company":"123","valid":true,"deep":{"gst":false,"country_name":"Fixture"}}"#)
			_ = try await makeClient(stub).company("123", deep: depth)
			let query = URLComponents(url: stub.requests[0].url!, resolvingAgainstBaseURL: false)?.queryItems ?? []
			#expect(query.contains { $0.name == "deep" && $0.value == "true" } == depth)
			#expect(stub.requests.count == 1)
		}
	}

	@Test func nAICSDepth() async throws {
		let decoder = JSONDecoder()
		decoder.keyDecodingStrategy = .convertFromSnakeCase
		let core = try decoder.decode(NAICS.self, from: Data(#"{"naics":"123","name":"Fixture","level":3,"country":"US","year":2022}"#.utf8))
		let locked = try decoder.decode(NAICS.self, from: Data(#"{"naics":"123","name":"Fixture","level":3,"country":"US","year":2022,"deep":{}}"#.utf8))
		let rich = try decoder.decode(NAICS.self, from: Data(#"{"naics":"123","name":"Fixture","level":3,"country":"US","year":2022,"deep":{"description":"Definition","children":[]}}"#.utf8))
		#expect(core.deep == nil)
		#expect(locked.deep != nil && locked.deep?.description == nil)
		#expect(rich.deep?.description == "Definition")
		for depth in [false, true] {
			let stub = StubTransport(body: #"{"naics":"123","name":"Fixture","level":3,"country":"US","year":2022,"deep":{"description":"Definition","children":[]}}"#)
			_ = try await makeClient(stub).naics("123", deep: depth)
			let query = URLComponents(url: stub.requests[0].url!, resolvingAgainstBaseURL: false)?.queryItems ?? []
			#expect(query.contains { $0.name == "deep" && $0.value == "true" } == depth)
			#expect(stub.requests.count == 1)
		}
	}

	@Test func everyCollectionAndAliasRequestsDepth() async throws {
		let stub0 = StubTransport(body: #"{"state":"X","country":"ZZ","districts":[{"district":"D","name":"Fixture","deep":{"population":0}}]}"#)
		let districts = try await makeClient(stub0).stateDistricts("X", deep: true)
		#expect(districts.districts.first?.deep?.population == 0)
		#expect(stub0.requests[0].url!.query!.contains("deep=true"))
		#expect(stub0.requests.count == 1)
		let stub1 = StubTransport(body: #"{"name":"Fixture","country":"ZZ","id":null,"deep":{}}"#)
		_ = try await makeClient(stub1).cityId("city_23456789abcd", deep: true)
		#expect(stub1.requests[0].url!.query!.contains("deep=true"))
		#expect(stub1.requests.count == 1)
		let stub2 = StubTransport(body: #"{"name":"Fixture","country":"ZZ","id":null,"distance":0,"distance_mi":0,"deep":{}}"#)
		_ = try await makeClient(stub2).cityNearest(0, 0, deep: true)
		#expect(stub2.requests[0].url!.query!.contains("deep=true"))
		#expect(stub2.requests.count == 1)
		let stub3 = StubTransport(body: #"{"q":"fi","cities":[{"name":"Fixture","country":"ZZ","id":null,"deep":{"population":0}}]}"#)
		_ = try await makeClient(stub3).citySearch("fi", deep: true)
		#expect(stub3.requests[0].url!.query!.contains("deep=true"))
		#expect(stub3.requests.count == 1)
		let stub4 = StubTransport(body: #"{"city":"Fixture","country":"ZZ","radius":40,"unit":"km","nearby":[{"name":"Nearby","country":"ZZ","id":null,"distance":0,"distance_mi":0,"deep":{}}]}"#)
		_ = try await makeClient(stub4).cityNearby("Fixture", deep: true)
		#expect(stub4.requests[0].url!.query!.contains("deep=true"))
		#expect(stub4.requests.count == 1)
		let stub5 = StubTransport(body: #"{"postal":"12345","country":"ZZ","radius":40,"unit":"km","nearby":[{"postal":"OTHER","country":"ZZ","distance":0,"distance_mi":0,"deep":{"metros":[]}}],"deep":{"metros":null}}"#)
		_ = try await makeClient(stub5).postalNearby("12345", deep: true)
		#expect(stub5.requests[0].url!.query!.contains("deep=true"))
		#expect(stub5.requests.count == 1)
		let stub6 = StubTransport(body: #"{"country":"ZZ","distance":0,"distance_mi":0,"from":{"postal":"12345","deep":{"metros":[]}},"to":{"postal":"23456","deep":{}}}"#)
		_ = try await makeClient(stub6).postalDistance("12345", "23456", deep: true)
		#expect(stub6.requests[0].url!.query!.contains("deep=true"))
		#expect(stub6.requests.count == 1)
		let stub7 = StubTransport(body: #"{"q":"fixture","country":"US","year":2022,"results":[{"naics":"123","name":"Fixture","level":3,"deep":{"children":[]},"match":{"field":"term","text":"Fixture","corrections":[]}}]}"#)
		_ = try await makeClient(stub7).naicsSearch("fixture", deep: true)
		#expect(stub7.requests[0].url!.query!.contains("deep=true"))
		#expect(stub7.requests.count == 1)
		let stub8 = StubTransport(body: #"{"q":"grin","emojis":[{"emoji":"😀","name":"Fixture","shortcodes":[],"deep":{"skins":[]}}]}"#)
		_ = try await makeClient(stub8).emojiSearch("grin", deep: true)
		#expect(stub8.requests[0].url!.query!.contains("deep=true"))
		#expect(stub8.requests.count == 1)
		let stub9 = StubTransport(body: #"{"timezone":"UTC","to":{"timezone":"UTC","offset":"+00:00","dst":false,"at":"1970-01-01T00:00:00+00:00","deep":{"offset_seconds":0}},"deep":{}}"#)
		_ = try await makeClient(stub9).timeAt(0, 0, to: "UTC", deep: true)
		#expect(stub9.requests[0].url!.query!.contains("deep=true"))
		#expect(stub9.requests.count == 1)
		let stub10 = StubTransport(body: #"{"timezone":"UTC","deep":{}}"#)
		_ = try await makeClient(stub10).timezone("UTC", deep: true)
		#expect(stub10.requests[0].url!.query!.contains("deep=true"))
		#expect(stub10.requests.count == 1)
		let stub11 = StubTransport(body: #"{"timezone":"UTC","deep":{}}"#)
		_ = try await makeClient(stub11).timezoneAt(0, 0, deep: true)
		#expect(stub11.requests[0].url!.query!.contains("deep=true"))
		#expect(stub11.requests.count == 1)
		let stub12 = StubTransport(body: #"{"date":"1970-01-01","valid":true,"deep":{}}"#)
		_ = try await makeClient(stub12).dateToday(deep: true)
		#expect(stub12.requests[0].url!.query!.contains("deep=true"))
		#expect(stub12.requests.count == 1)
		let stub13 = StubTransport(body: #"{"name":"Fixture","valid":true,"deep":{}}"#)
		_ = try await makeClient(stub13).name("Fixture", country: "US", deep: true)
		#expect(stub13.requests[0].url!.query!.contains("deep=true"))
		#expect(stub13.requests.count == 1)
	}
}
