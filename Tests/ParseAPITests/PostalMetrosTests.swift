import Foundation
import Testing
@testable import ParseAPI

@Suite struct PostalMetros {
	@Test func observationStatesSurviveEveryPostalResponse() async throws {
		let fields = ["", #", "deep":{"metros":null}"#, #", "deep":{"metros":[]}"#, #", "deep":{"metros":[{"code":"12345","name":"Example area","type":"future-area-type","share":0.75,"residential_share":0,"business_share":1,"other_share":null,"future":true}]}"#]
		for (index, field) in fields.enumerated() {
			let member = #"{"postal":"12345","country":"US","city":null,"distance":0,"distance_mi":0,"future":true"# + field + "}"
			let postal = try await makeClient(StubTransport(body: member)).postal("12345")
			let nearbyBody = #"{"postal":"12345","country":"US","radius":10,"unit":"km","nearby":["# + member + "]" + field + "}"
			let nearby = try await makeClient(StubTransport(body: nearbyBody)).postalNearby("12345")
			let distanceBody = #"{"country":"US","distance":0,"distance_mi":0,"from":"# + member + #", "to":"# + member + "}"
			let distance = try await makeClient(StubTransport(body: distanceBody)).postalDistance("12345", "12345")
			for value in [postal.deep?.metros, nearby.deep?.metros, nearby.nearby[0].deep?.metros, distance.from.deep?.metros, distance.to.deep?.metros] {
				#expect(value?.count == (index < 2 ? nil : index == 2 ? 0 : 1))
				if let metro = value?.first {
					#expect(metro.code == "12345")
					#expect(metro.name == "Example area")
					#expect(metro.type == "future-area-type")
					#expect(metro.share == 0.75)
					#expect(metro.residentialShare == 0)
					#expect(metro.businessShare == 1)
					#expect(metro.otherShare == nil)
				}
			}
		}
	}

	@Test func missingSharesRemainUnknown() async throws {
		let body = #"{"postal":"12345","country":"US","deep":{"metros":[{"code":"12345","name":"Example area","type":"metropolitan"}]}}"#
		let result = try await makeClient(StubTransport(body: body)).postal("12345")
		let metro = try #require(result.deep?.metros?.first)
		#expect(metro.share == nil && metro.residentialShare == nil && metro.businessShare == nil && metro.otherShare == nil)
	}
}
