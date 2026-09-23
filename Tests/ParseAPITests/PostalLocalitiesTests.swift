import Foundation
import Testing
@testable import ParseAPI

@Suite struct PostalLocalities {
	@Test func choicesPreserveObservationWithoutInferringCity() async throws {
		let choice = #"{"city":"SYDNEY","state":"NSW","state_name":"New South Wales","future":true}"#
		let other = #"{"city":"HAYMARKET","state":"NSW","state_name":"New South Wales"}"#
		let fields = ["", #", "localities":null"#, #", "localities":[]"#, #", "localities":["# + choice + "]", #", "localities":["# + choice + "," + other + "]"]
		for (index, field) in fields.enumerated() {
			let body = #"{"postal":"2000","country":"AU","city":null"# + field + "}"
			let result = try await makeClient(StubTransport(body: body)).postal("2000", country: "AU")
			#expect(result.city == nil)
			#expect(result.localities?.count == (index < 2 ? nil : index - 2))
			if let locality = result.localities?.first {
				#expect(locality.city == "SYDNEY")
				#expect(locality.state == "NSW")
				#expect(locality.stateName == "New South Wales")
			}
		}
	}
}
