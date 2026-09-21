import Foundation
import Testing
@testable import ParseAPI
@Suite struct StackTests {
	@Test func inventoryShapesAndEncoding() async throws {
		let records = [
			#"{"domain":"xn--bcher-kva.example","url":"https://xn--bcher-kva.example/","checked_at":null,"scope":"homepage","pages":0,"partial":null,"cms":null,"servers":null,"frameworks":null,"ecommerce":null,"analytics":null,"chat":null,"payments":null,"hosting":null,"future":true}"#,
			#"{"domain":"xn--bcher-kva.example","url":"https://xn--bcher-kva.example/","checked_at":"2026-09-21T12:00:00Z","scope":"site","pages":2,"partial":false,"cms":[],"servers":[],"frameworks":[],"ecommerce":[],"analytics":[],"chat":[],"payments":[],"hosting":[],"future":true,"deep":{}}"#,
			#"{"domain":"xn--bcher-kva.example","url":"https://xn--bcher-kva.example/","checked_at":"2026-09-21T12:00:00Z","scope":"site","pages":3,"partial":true,"cms":[{"technology":"wordpress","name":"WordPress","version":"6.8"},{"technology":"ghost","name":"Ghost","version":null}],"servers":[{"technology":"nginx","name":"nginx","version":"1.26.2"},{"technology":"apache","name":"Apache","version":null}],"frameworks":[{"technology":"nextjs","name":"Next.js","version":null,"future":true},{"technology":"react","name":"React","version":"19.1"}],"ecommerce":[{"technology":"woocommerce","name":"WooCommerce","version":null}],"analytics":[{"technology":"google-analytics","name":"Google Analytics","version":null}],"chat":[{"technology":"intercom","name":"Intercom","version":null}],"payments":[{"technology":"stripe","name":"Stripe","version":null}],"hosting":[{"technology":"vercel","name":"Vercel","version":null}],"future":true}"#,
			#"{"domain":"xn--bcher-kva.example","url":"https://xn--bcher-kva.example/","checked_at":null,"scope":"future-scope","pages":0,"partial":null,"cms":null,"servers":null,"frameworks":null,"ecommerce":null,"analytics":null,"chat":null,"payments":null,"hosting":null,"future":true,"deep":{}}"#,
			#"{"domain":"xn--bcher-kva.example","url":"https://xn--bcher-kva.example/","checked_at":"2026-09-21T12:00:00Z","scope":"homepage","pages":1,"partial":true,"cms":[],"servers":[],"frameworks":[{"technology":"nextjs","name":"Next.js","version":null,"future":true}],"ecommerce":[],"analytics":[],"chat":[],"payments":[],"hosting":[],"future":true,"deep":{}}"#
		]
		for (i, body) in records.enumerated() {
			let stub = StubTransport(body: body)
			let client = try makeClient(stub)
			let result = try await client.stack("bücher.example", deep: true, pretty: true)
			#expect(stub.requests[0].url!.absoluteString == "https://api.parseapi.com/stack/b%C3%BCcher.example?deep=true&pretty=true")
			#expect(stub.requests[0].value(forHTTPHeaderField: "Parse-Version") == "2.0.0")
			if i == 0 || i == 3 { #expect(result.cms == nil && result.servers == nil && result.pages == 0 && result.partial == nil) }
			else if i != 2 { #expect(result.cms?.isEmpty == true && result.servers?.isEmpty == true) }
			for group in [result.ecommerce, result.analytics, result.chat, result.payments, result.hosting] {
				if i == 0 || i == 3 { #expect(group == nil) }
				else if i == 2 { #expect(group?.count == 1 && group?.first?.technology.isEmpty == false) }
				else { #expect(group?.isEmpty == true) }
			}
			switch i {
			case 0: #expect(result.frameworks == nil && result.checkedAt == nil && result.deep == nil)
			case 1: #expect(result.scope == "site" && result.pages == 2 && result.partial == false && result.frameworks?.isEmpty == true && result.deep != nil)
			case 2:
				#expect(result.checkedAt != nil)
				#expect(result.scope == "site" && result.pages == 3 && result.partial == true)
				#expect(result.cms?.count == 2 && result.servers?.count == 2 && result.frameworks?.count == 2 && result.deep == nil)
				#expect(result.cms?.first?.technology == "wordpress" && result.cms?.first?.name == "WordPress" && result.cms?.first?.version == "6.8")
				#expect(result.cms?.last?.technology == "ghost" && result.cms?.last?.version == nil)
				#expect(result.servers?.first?.version == "1.26.2" && result.servers?.last?.technology == "apache")
				#expect(result.frameworks?.first?.version == nil)
			case 3: #expect(result.scope == "future-scope" && result.frameworks == nil && result.deep != nil)
			default:
				#expect(result.scope == "homepage" && result.pages == 1 && result.partial == true)
				#expect(result.deep != nil && result.frameworks?.first?.technology == "nextjs")
				#expect(result.frameworks?.first?.version == nil)
			}
			_ = try await client.stack("example.com")
			#expect(stub.requests[1].url!.absoluteString == "https://api.parseapi.com/stack/example.com")
		}
	}
}

@Suite struct StackDeadlineTests {
	@Test func operationDefaultsAndExplicitTimeouts() async throws {
		let body = #"{"domain":"example.com","url":"https://example.com/","checked_at":null,"scope":"homepage","pages":0,"partial":null,"cms":null,"servers":null,"frameworks":null,"ecommerce":null,"analytics":null,"chat":null,"payments":null,"hosting":null,"deep":{},"available":false}"#
		for configured: TimeInterval? in [nil, 10, 1.2, 45] {
			let stub = StubTransport(body: body)
			let client: ParseAPI
			if let configured {
				// Retain the exact full initializer function type used by existing consumers.
				let initialize: (String?, String?, String?, TimeInterval, Int?, ParseAPITransport?) throws -> ParseAPI = ParseAPI.init
				client = try initialize("test_key", nil, nil, configured, 0, stub.transport)
			} else {
				client = try ParseAPI("test_key", retries: 0, transport: stub.transport)
			}
			let core = try await client.stack("example.com")
			#expect(core.frameworks == nil && core.deep != nil)
			_ = try await client.domain("example.com")
			_ = try await client.stack("example.com", deep: true)
			let actualTimeouts: [TimeInterval] = stub.requests.map(\.timeoutInterval)
			let expectedTimeouts: [TimeInterval] = [configured ?? 35, configured ?? 10, configured ?? 35]
			#expect(actualTimeouts == expectedTimeouts)
		}
	}
}
