import Foundation
import Testing
@testable import ParseAPI

@Suite struct CityFoundationTests {
	private let core = #"{"id":"city_222222222222","name":"Fixture","country":"JP","distance":0,"distance_mi":0}"#
	private let rich = #"{"id":"city_222222222222","name":"Fixture","country":"JP","distance":0,"distance_mi":0,"grain":"subdivision","parent":{"id":"city_333333333333","name":null,"name_local":"市","country":"JP","state":"14","type":"city","grain":"municipality","future":true},"deep":{"population":0,"population_observed_on":"2025-12-31","population_basis":"registered_population"},"future":true}"#

	@Test func optionalParentAndPopulationDecodeWithoutChangingOldBodies() throws {
		let decoder = JSONDecoder(); decoder.keyDecodingStrategy = .convertFromSnakeCase
		let old = try decoder.decode(City.self, from: Data(core.utf8))
		#expect(old.grain == nil && old.parent == nil)
		let city = try decoder.decode(City.self, from: Data(rich.utf8))
		#expect(city.grain == "subdivision" && city.parent?.id == "city_333333333333")
		#expect(city.parent?.name == nil && city.parent?.nameLocal == "市")
		#expect(city.deep?.population == 0 && city.deep?.populationObservedOn == "2025-12-31")
		#expect(city.deep?.populationBasis == "registered_population")
		let nearest = try decoder.decode(CityNearest.self, from: Data(rich.utf8))
		#expect(nearest.parent?.grain == "municipality" && nearest.distance == 0)
		let explicitNull = rich.replacingOccurrences(of: #""grain":"subdivision""#, with: #""grain":null"#)
		#expect(try decoder.decode(City.self, from: Data(explicitNull.utf8)).grain == nil)
	}

	@Test func optionsForwardToEachRouteAndExistingFunctionReferenceKeepsItsSignature() async throws {
		let options = CityOptions(country:"JP",state:"14",type:"ward",grain:"subdivision",aliases:true,hierarchy:true,ambiguity:"error",deep:true,lang:"ja")
		let calls: [(String, (ParseAPI) async throws -> Void, [String:String])] = [
			("/city/Fixture", { _ = try await $0.city("Fixture", options:options) }, ["country":"JP","state":"14","type":"ward","grain":"subdivision","aliases":"true","hierarchy":"true","ambiguity":"error","deep":"true","lang":"ja"]),
			("/city/id/city_222222222222", { _ = try await $0.cityId("city_222222222222",options:options) }, ["hierarchy":"true","deep":"true","lang":"ja"]),
			("/city", { _ = try await $0.citySearch("Fi",limit:5,options:options) }, ["q":"Fi","limit":"5","country":"JP","state":"14","type":"ward","grain":"subdivision","aliases":"true","hierarchy":"true","deep":"true","lang":"ja"]),
			("/city", { _ = try await $0.cityNearest(0,0,options:options) }, ["lat":"0","lon":"0","country":"JP","state":"14","type":"ward","grain":"subdivision","hierarchy":"true","deep":"true","lang":"ja"]),
			("/city/Fixture/nearby", { _ = try await $0.cityNearby("Fixture",radius:10,unit:"km",limit:5,options:options) }, ["radius":"10","unit":"km","limit":"5","country":"JP","state":"14","type":"ward","grain":"subdivision","aliases":"true","hierarchy":"true","ambiguity":"error","deep":"true","lang":"ja"]),
		]
		for (path, call, expected) in calls {
			let body = path.contains("nearby") ? #"{"city":"Fixture","country":"JP","radius":10,"unit":"km","nearby":[]}"#
				: expected["q"] != nil ? #"{"q":"Fi","cities":[],"grain":"subdivision","type":"ward","aliases":true}"# : rich
			let stub = StubTransport(body:body)
			try await call(makeClient(stub))
			let parts = URLComponents(url:stub.requests[0].url!,resolvingAgainstBaseURL:false)!
			#expect(parts.path == path)
			#expect(Dictionary(uniqueKeysWithValues:parts.queryItems!.map{($0.name,$0.value!)}) == expected)
		}
		let stub = StubTransport(body:core), client = try makeClient(stub)
		let existing: (String,String?,String?,Bool) async throws -> City = client.city
		_ = try await existing("Fixture",nil,nil,false)
		_ = try await client.city("Fixture",options:CityOptions())
		#expect(stub.requests.allSatisfy{$0.url?.query == nil})
	}
}
