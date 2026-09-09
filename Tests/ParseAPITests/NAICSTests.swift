import Foundation
import Testing
@testable import ParseAPI

@Suite struct NAICSTests {
 @Test func hierarchyAndSearch() async throws {
  let stub = StubTransport([
   (200, #"{"naics":"31-33","name":"Manufacturing","level":2,"parent":null,"parent_name":null,"year":2022,"country":"US","future":true,"deep":{"description":null,"children":[{"naics":"311","name":"Food Manufacturing"}]}}"#, [:]),
   (200, #"{"q":"coffee & tea","year":2022,"country":"US","results":[]}"#, [:])
  ])
  let c = try makeClient(stub)
  let industry = try await c.naics("31-33")
  #expect(industry.naics == "31-33" && industry.parent == nil && industry.deep?.description == nil)
  #expect(industry.deep?.children?.first?.naics == "311")
  let search = try await c.naicsSearch("coffee & tea", limit: 5)
  #expect(search.year == 2022 && search.results.isEmpty)
  #expect(stub.requests[0].url!.absoluteString == "https://api.parseapi.com/naics/31-33")
  #expect(stub.requests[1].url!.absoluteString == "https://api.parseapi.com/naics?q=coffee%20%26%20tea&limit=5")
 }
}


@Suite struct NAICSEvidenceTests {
 @Test func exclusionsAndMatchRemainCompatible() async throws {
  let stub = StubTransport([(200, #"{"q":"sofware","year":2022,"country":"US","results":[{"naics":"541511","name":"Custom Computer Programming Services","level":6,"parent":"54151","parent_name":"Computer Systems Design and Related Services","deep":{"description":null,"children":[]}},{"naics":"541511","name":"Custom Computer Programming Services","level":6,"parent":"54151","parent_name":"Computer Systems Design and Related Services","match":null,"deep":{"description":null,"children":[],"exclusions":null}},{"naics":"541511","name":"Custom Computer Programming Services","level":6,"parent":"54151","parent_name":"Computer Systems Design and Related Services","match":{"field":"future-field","text":"Future matching evidence","corrections":[],"future":true},"deep":{"description":null,"children":[],"exclusions":[]}},{"naics":"541511","name":"Custom Computer Programming Services","level":6,"parent":"54151","parent_name":"Computer Systems Design and Related Services","match":{"field":"term","text":"Computer software programming services","corrections":[{"from":"sofware","to":"software"}]},"future":true,"deep":{"description":null,"children":[],"exclusions":[{"description":"Designing integrated computer systems","codes":[{"naics":"541512","name":"Computer Systems Design Services"}]},{"description":"Activities classified elsewhere","codes":[]}]}}]}"#, [:])])
  let client = try makeClient(stub)
  let search = try await client.naicsSearch("sofware")
  let results: [NAICSSearchItem] = search.results
  #expect(results[0].deep?.exclusions == nil && results[0].match == nil)
  #expect(results[1].deep?.exclusions == nil && results[1].match == nil)
  #expect(results[2].deep?.exclusions?.isEmpty == true)
  #expect(results[2].match?.field == "future-field")
  #expect(results[2].match?.corrections.isEmpty == true)
  #expect(results[3].deep?.exclusions?[0].codes[0].naics == "541512")
  #expect(results[3].deep?.exclusions?[1].description == "Activities classified elsewhere")
  #expect(results[3].deep?.exclusions?[1].codes.isEmpty == true)
  #expect(results[3].match?.text == "Computer software programming services")
  #expect(results[3].match?.corrections[0].from == "sofware")
  #expect(results[3].match?.corrections[0].to == "software")
 }
}
