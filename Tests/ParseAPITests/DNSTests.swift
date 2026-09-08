import Foundation
import Testing
@testable import ParseAPI

@Suite struct DNSTests {
	@Test func recordsAndQuestion() async throws {
		let stub = StubTransport([
			(200, #"{"domain":"example.com","records":[{"name":"example.com.","type":"TXT","ttl":0,"value":"\"one\" \"two\"","future":true},{"name":"alias.example.","type":"CNAME","ttl":300,"value":"target.example."}],"future":true}"#, [:]),
			(200, #"{"domain":"example.com","records":[]}"#, [:])
		])
		let client = try makeClient(stub)
		let result = try await client.dns("_dmarc.bücher.example.", type: "txt")
		#expect(result.records.count == 2 && result.records[0].ttl == 0)
		#expect(result.records[0].value == #""one" "two""#)
		#expect(result.records[1].type == "CNAME")
		#expect(try await client.dns("example.com").records.isEmpty)
		#expect(stub.requests[0].url!.absoluteString == "https://api.parseapi.com/dns/_dmarc.b%C3%BCcher.example.?type=txt")
		#expect(stub.requests[1].url!.absoluteString == "https://api.parseapi.com/dns/example.com")
	}
}
