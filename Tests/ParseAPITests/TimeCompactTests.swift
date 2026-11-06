import Foundation
import Testing
@testable import ParseAPI

@Test func approvedCompactTimePlacesAndChoicesDecode() throws {
 let file = URL(fileURLWithPath: #filePath).deletingLastPathComponent().appendingPathComponent("Fixtures/time-compact.json")
 let rows = try JSONSerialization.jsonObject(with: Data(contentsOf: file)) as! [[String: Any]]
 let decoder = JSONDecoder(); decoder.keyDecodingStrategy = .convertFromSnakeCase
 let encoder = JSONEncoder(); encoder.keyEncodingStrategy = .convertToSnakeCase
 for row in rows {
  let body = row["body"] as! [String: Any]
  let decoded = try decoder.decode(Timezone.self, from: JSONSerialization.data(withJSONObject: body))
  if let expected = body["location"] as? [String: Any] {
   let place = try #require(decoded.location)
   let actual = try JSONSerialization.jsonObject(with: encoder.encode(place)) as! [String: Any]
   for field in ["id", "name", "country", "state", "latitude", "longitude", "status"] {
    if let want = expected[field] as? NSObject { #expect((actual[field] as? NSObject)?.isEqual(want) == true, Comment(rawValue: "\(row["id"]!):\(field)")) }
   }
   if expected["status"] == nil {
    #expect(actual["input"] == nil && actual["candidates"] == nil && actual["truncated"] == nil)
   }
  } else { #expect(decoded.location == nil) }
 }
}
