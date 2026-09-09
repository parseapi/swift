import Foundation
import Testing
@testable import ParseAPI

@Suite struct NAICSTests {
 @Test func hierarchyAndSearch() async throws {
  let stub = StubTransport([
   (200, #"{"naics":"31-33","name":"Manufacturing","description":null,"level":2,"parent":null,"parent_name":null,"children":[{"naics":"311","name":"Food Manufacturing"}],"year":2022,"country":"US","future":true}"#, [:]),
   (200, #"{"q":"coffee & tea","year":2022,"country":"US","results":[]}"#, [:])
  ])
  let c = try makeClient(stub)
  let industry = try await c.naics("31-33")
  #expect(industry.naics == "31-33" && industry.parent == nil && industry.description == nil)
  #expect(industry.children[0].naics == "311")
  let search = try await c.naicsSearch("coffee & tea", limit: 5)
  #expect(search.year == 2022 && search.results.isEmpty)
  #expect(stub.requests[0].url!.absoluteString == "https://api.parseapi.com/naics/31-33")
  #expect(stub.requests[1].url!.absoluteString == "https://api.parseapi.com/naics?q=coffee%20%26%20tea&limit=5")
 }
}
