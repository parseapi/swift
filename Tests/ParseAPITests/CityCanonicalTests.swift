import Foundation
import Testing
@testable import ParseAPI

@Suite struct CityCanonicalTests {
    private let id = "city_7aj899nvwyku"
    private func query(_ stub: StubTransport) -> [String:String] { Dictionary(uniqueKeysWithValues:(URLComponents(url:stub.requests.last!.url!,resolvingAgainstBaseURL:false)!.queryItems ?? []).map{($0.name,$0.value!)}) }

    @Test func sparseListsFiltersAndNativeResources() async throws {
        let stub=StubTransport(body:#"{"object":"list","data":[{"id":"city_7aj899nvwyku","object":"city","name":"Vienna"}],"has_more":true,"url":"/city","next_cursor":"opaque+/="}"#)
        let result=try await makeClient(stub).cityList(options:CityCollectionOptions(minPopulation:0,sort:"-population,+name",cursor:"opaque+/=",countries:["AT","CH"],excludeCountries:["JP"],timezones:["Europe/Vienna"],minElevation:-10,maxElevation:0,))
        #expect(result.object=="list" && result.hasMore == true && result.data[0].country==nil && result.data[0].name=="Vienna")
        for(k,v) in ["format":"list","countries":"AT,CH","exclude_countries":"JP","timezones":"Europe/Vienna","min_elevation":"-10","max_elevation":"0","min_population":"0","sort":"-population,+name","cursor":"opaque+/="] { #expect(query(stub)[k]==v) }
        let resource=StubTransport(body:#"{"id":"city_7aj899nvwyku","object":"city","name_local":"Wien"}"#)
        #expect(try await makeClient(resource).cityResource("Vienna",options:CityOptions(country:"AT")).nameLocal=="Wien")
        #expect(query(resource)==["country":"AT","format":"resource",])
        _ = try await makeClient(stub).citySearchList("Vi",); #expect(query(stub)["format"]=="list")
        _ = try await makeClient(stub).cityNearbyList("Vienna"); #expect(stub.requests.last?.url?.path=="/city/Vienna/nearby")
    }

    @Test func explicitMatchingRetainsSuggestionEvidence() async throws {
        let stub=StubTransport(body:#"{"object":"list","data":[{"id":"city_7aj899nvwyku","object":"city","match":{"type":"fuzzy","source":"name","value":"Vienna","language":null,"edit_distance":1}}],"has_more":false,"url":"/city","next_cursor":null}"#)
        let result=try await makeClient(stub).citySearchList("Viena",options:CityCollectionOptions(match:"fuzzy",maxDistance:1))
        #expect(result.data[0].match?.editDistance==1 && result.data[0].match?.value=="Vienna")
        #expect(query(stub)==["q":"Viena","format":"list","match":"fuzzy","max_distance":"1"])
    }

    @Test func partialRelationsAndZeroUnknownDistance() async throws {
        let stub=StubTransport(body:#"{"object":"list","data":[],"has_more":false,"url":"/city","next_cursor":null,"city_id":"city_7aj899nvwyku","relationship":"children","coverage":"partial"}"#)
        #expect(try await makeClient(stub).cityChildren(id,options:CityRelationsOptions(limit:2,cursor:"opaque+/=",)).coverage=="partial")
        #expect(stub.requests.last?.url?.path=="/city/id/\(id)/children")
        _ = try await makeClient(stub).cityAncestors(id); #expect(stub.requests.last?.url?.path=="/city/id/\(id)/ancestors")
        _ = try await makeClient(stub).citySiblings(id); #expect(stub.requests.last?.url?.path=="/city/id/\(id)/siblings")
        for value in ["0","null"] {
            let distance=StubTransport(body:"{\"object\":\"city_distance\",\"from\":\"\(id)\",\"to\":\"\(id)\",\"distance\":\(value),\"distance_mi\":\(value),\"method\":\"great_circle\"}")
            let result=try await makeClient(distance).cityDistance(id,id)
            #expect(result.distance == (value=="0" ? 0 : nil)); #expect(query(distance).isEmpty)
        }
    }

    @Test func bounded409ChoicesAndOtherErrorsUnchanged() async throws {
        for(status,code,present) in [(409,"ambiguous_city",true),(400,"ambiguous_city",false),(409,"invalid_request",false),(429,"rate_limited",false)] {
            let safe=#"{"id":"city_7aj899nvwyku","object":"city","name":"Vienna","state":null,"deep":{"population":99}}"#
            let stub=StubTransport([(status,"{\"code\":\"\(code)\",\"message\":\"Choose\",\"candidates\":[\(safe),\(safe),\(safe)]}",["Retry-After":"60"])])
            do { _ = try await makeClient(stub).city("Vienna",options:CityOptions(ambiguity:"error")); Issue.record("Expected API error") }
            catch let error as ParseAPIError {
                #expect(error.status==status && error.code==code && error.retryAfter=="60")
                #expect((error.candidates != nil)==present)
                if present { #expect(error.candidates?.count==2 && error.candidates?[0].name=="Vienna" && error.candidates?[0].state==nil) }
            }
            #expect(stub.requests.count==1)
        }
    }

    @Test func reviewedRomanizedOptInAndNull() async throws {
        let stub=StubTransport(body:#"{"id":"city_7aj899nvwyku","object":"city","name_romanized":"Kitakyūshū","romanization_language":"ja-Latn"}"#);let row=try await makeClient(stub).cityIdResource(id,romanized:true);#expect(row.nameRomanized=="Kitakyūshū" && row.romanizationLanguage=="ja-Latn");#expect(query(stub)==["format":"resource","romanized":"true"])
        let unknown=StubTransport(body:#"{"id":"city_7aj899nvwyku","object":"city","name_romanized":null,"romanization_language":null}"#);let missing=try await makeClient(unknown).cityIdResource(id,romanized:true);#expect(missing.nameRomanized==nil && missing.romanizationLanguage==nil)
    }


    @Test func spellingRouteAdaptsClassicEnvelopeOnly() async throws {
        let body = #"{"object":"list","q":"Viena","data":[{"id":"city_7aj899nvwyku","object":"city","name":"Vienna","country":"AT"}],"has_more":false,"url":"/city/search","next_cursor":null}"#
        let stub = StubTransport(body: body)
        let classic = try await makeClient(stub).citySearch("Viena",options:CityCollectionOptions(match:"fuzzy",maxDistance:1))
        #expect(classic.cities.first?.name == "Vienna" && classic.q == "Viena")
        #expect(stub.requests.last?.url?.path == "/city/search")
        _ = try await makeClient(stub).citySearchList("Viena",options:CityCollectionOptions(match:"fuzzy")); #expect(stub.requests.last?.url?.path == "/city/search")
        let old = StubTransport(body: #"{"q":"Vi","cities":[]}"#)
        _ = try await makeClient(old).citySearch("Vi"); #expect(old.requests.last?.url?.path == "/city")
    }

}
