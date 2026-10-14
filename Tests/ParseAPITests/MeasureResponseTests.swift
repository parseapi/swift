import Foundation
import Testing
@testable import ParseAPI

@Suite struct MeasureResponseTests {
 @Test func cleanAndLegacyResponsesDecodeThroughClient() async throws {
  let url = URL(fileURLWithPath: #filePath).deletingLastPathComponent().appendingPathComponent("Fixtures/measure-response.json")
  let cases = try JSONSerialization.jsonObject(with: Data(contentsOf: url)) as! [[String: Any]]
  for body in cases {
   let raw = String(data: try JSONSerialization.data(withJSONObject: body), encoding: .utf8)!
   let stub = StubTransport(body: raw)
   let answer = try await makeClient(stub).measure(body["measure"] as! String)
   #expect(answer.amount == body["amount"] as? String)
   #expect(answer.reason == body["reason"] as? String)
   #expect(answer.choices.count == ((body["choices"] as? [[String: Any]])?.count ?? 0))
   let encoded = try JSONSerialization.jsonObject(with: JSONEncoder().encode(answer)) as! [String: Any]
   if answer.valid { #expect(encoded.count == 5) }
   else {
    #expect(encoded["type"] is NSNull)
    #expect(encoded["amount"] is NSNull)
    #expect(encoded["unit"] is NSNull)
   }
  }
 }
}
