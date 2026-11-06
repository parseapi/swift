import Foundation
import Testing
@testable import ParseAPI

@Test func approvedCityMatchesDecodeWithoutSourceOrScore() throws {
 let file = URL(fileURLWithPath: #filePath).deletingLastPathComponent().appendingPathComponent("Fixtures/noise-approved.json")
 let rows = try JSONSerialization.jsonObject(with: Data(contentsOf: file)) as! [[String: Any]]
 let decoder = JSONDecoder(); decoder.keyDecodingStrategy = .convertFromSnakeCase
 let encoder = JSONEncoder(); encoder.keyEncodingStrategy = .convertToSnakeCase
 for row in rows { for city in (row["body"] as! [String: Any])["data"] as? [[String: Any]] ?? [] {
  let actual = try decoder.decode(CityResource.self, from: JSONSerialization.data(withJSONObject: city))
  let match = try #require(actual.match), expected = city["match"] as! [String: Any]
  #expect(match.type == expected["type"] as? String); #expect(match.value == expected["value"] as? String)
  #expect(match.language == expected["language"] as? String)
  let encoded = try JSONSerialization.jsonObject(with: encoder.encode(match)) as! [String: Any]
  #expect(encoded["source"] == nil && encoded["edit_distance"] == nil)
 } }
}
