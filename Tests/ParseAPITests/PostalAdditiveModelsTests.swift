import Foundation
import Testing
@testable import ParseAPI

@Test func alreadyServedPostalFieldsPreserveOldPayloadsAndValues() throws {
 let file = URL(fileURLWithPath: #filePath).deletingLastPathComponent().appendingPathComponent("Fixtures/PostalAdditive.json")
 let decoder = JSONDecoder(); decoder.keyDecodingStrategy = .convertFromSnakeCase
 let cases = try decoder.decode([String: Postal].self, from: Data(contentsOf: file))
 for (name, postal) in cases {
  #expect(postal.deep?.metros?.first?.share == 0.125)
  if name == "missing" || name == "null" { #expect(postal.type == nil); #expect(postal.deep?.metros?.first?.sharePercent == nil) }
 }
 #expect(cases["current"]?.type == "standard")
 #expect(cases["current"]?.deep?.metros?.first?.sharePercent == 12.5)
 #expect(cases["zero"]?.deep?.metros?.first?.sharePercent == 0)
 #expect(cases["future"]?.type == "future_custom")
 #expect(cases["future"]?.deep?.metros?.first?.sharePercent == 100)
}
