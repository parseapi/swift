import Foundation
import Testing
@testable import ParseAPI

@Suite struct CityCollectionsTests {
	private let city = #"{"id":"city_222222222222","object":"city","name":"Fixture","country":"AT","distance":0,"distance_mi":0,"grain":"future-grain","population":0}"#
	private func query(_ stub: StubTransport) -> [String:String] {
		let parts = URLComponents(url:stub.requests.last!.url!,resolvingAgainstBaseURL:false)!
		return Dictionary(uniqueKeysWithValues:(parts.queryItems ?? []).map{($0.name,$0.value!)})
	}

	@Test func collectionControlsReachEachRouteAndOpaqueCursorRemainsExact() async throws {
		let options = CityCollectionOptions(country:"AT",state:"9",type:"city",grain:"municipality",aliases:true,hierarchy:true,ambiguity:"error",minPopulation:0,maxPopulation:9_007_199_254_740_991,bbox:"170,-10,-170,10",sort:"-population",page:true,cursor:"opaque+/=?&",deep:true,lang:"de",timezones:["Europe/Vienna"])
		let filters = ["country":"AT","state":"9","type":"city","grain":"municipality","hierarchy":"true","min_population":"0","max_population":"9007199254740991","timezones":"Europe/Vienna","bbox":"170,-10,-170,10","sort":"-population","cursor":"opaque+/=?&","deep":"true","lang":"de","limit":"5"]
		let list = StubTransport(body:#"{"object":"list","next_cursor":"opaque+/=?&","cities":[]}"#)
 #expect(try await makeClient(list).cityList(limit:5,options:options).nextCursor == "opaque+/=?&")
 #expect(query(list) == filters.merging(["browse":"true"],uniquingKeysWith:{$1}))
		let search = StubTransport(body:#"{"q":"Fi","cities":[],"next_cursor":null}"#)
 #expect(try await makeClient(search).citySearch("Fi",limit:5,options:options).nextCursor == nil)
 #expect(query(search) == filters.merging(["q":"Fi","aliases":"true","page":"true"],uniquingKeysWith:{$1}))
		let named = StubTransport(body:#"{"city":"Fixture","country":"AT","radius":5,"unit":"mi","nearby":[],"next_cursor":null}"#)
		_ = try await makeClient(named).cityNearby("Fixture",radius:5,unit:"mi",limit:5,options:options)
 #expect(named.requests[0].url?.path == "/city/Fixture/nearby")
 #expect(query(named) == filters.merging(["radius":"5","unit":"mi","aliases":"true","ambiguity":"error","page":"true"],uniquingKeysWith:{$1}))
		let coords = StubTransport(body:#"{"latitude":0,"longitude":0,"radius":5,"unit":"mi","object":"list","next_cursor":"next","nearby":[]}"#)
		let result = try await makeClient(coords).cityNearbyCoordinates(0,0,radius:5,unit:"mi",limit:5,options:options)
 #expect(result.latitude == 0 && result.longitude == 0 && result.nextCursor == "next")
 #expect(query(coords) == filters.merging(["lat":"0","lon":"0","nearby":"true","radius":"5","unit":"mi"],uniquingKeysWith:{$1}))
	}

	@Test func oldCollectionSignaturesAndDefaultsStayAvailable() async throws {
		let search = StubTransport(body:#"{"q":"Fi","cities":[]}"#), client = try makeClient(search)
		let oldSearch: (String,String?,String?,Int?,Bool) async throws -> CitySearch = client.citySearch
 #expect(try await oldSearch("Fi",nil,nil,nil,false).nextCursor == nil)
 #expect(query(search) == ["q":"Fi"])
		_ = try await client.citySearch("Fi",options:CityCollectionOptions())
 #expect(query(search) == ["q":"Fi"])
		let named = StubTransport(body:#"{"city":"Fixture","country":"AT","radius":40,"unit":"km","nearby":[]}"#), nearbyClient = try makeClient(named)
		let oldNearby: (String,Double?,String?,String?,String?,Int?,Bool) async throws -> CityNearby = nearbyClient.cityNearby
 #expect(try await oldNearby("Fixture",nil,nil,nil,nil,nil,false).nextCursor == nil)
 #expect(query(named).isEmpty)
		let oldOptions: (String?,String?,String?,String?,Bool,Bool,String?,Bool,String?) -> CityOptions = CityOptions.init
		_ = oldOptions(nil,nil,nil,nil,false,false,nil,false,nil)
		let basicList = StubTransport(body:#"{"object":"list","next_cursor":null,"cities":[]}"#)
		_ = try await makeClient(basicList).cityList()
 #expect(query(basicList) == ["browse":"true"])
		let basicCoords = StubTransport(body:#"{"latitude":0,"longitude":0,"radius":40,"unit":"km","object":"list","next_cursor":null,"nearby":[]}"#)
		_ = try await makeClient(basicCoords).cityNearbyCoordinates(0,0)
 #expect(query(basicCoords) == ["lat":"0","lon":"0","nearby":"true"])
	}

	@Test func newCollectionsDecodeNullCursorUnknownVocabularyAndZeroPopulation() throws {
		let decoder = JSONDecoder(); decoder.keyDecodingStrategy = .convertFromSnakeCase
		let list = try decoder.decode(CityList.self,from:Data("{\"object\":\"list\",\"cities\":[\(city)],\"has_more\":false,\"url\":\"/city\",\"next_cursor\":null,\"future\":true}".utf8))
 #expect(list.nextCursor == nil && list.cities[0].grain == "future-grain" && list.cities[0].population == 0)
		let coords = try decoder.decode(CityNearbyCoordinates.self,from:Data("{\"latitude\":-90,\"longitude\":180,\"radius\":40,\"unit\":\"future-unit\",\"object\":\"list\",\"nearby\":[\(city)],\"has_more\":false,\"url\":\"/city\",\"next_cursor\":\"opaque\"}".utf8))
 #expect(coords.unit == "future-unit" && coords.nearby[0].grain == "future-grain" && coords.nextCursor == "opaque")
	}
}
