import Foundation
import Testing
@testable import ParseAPI

@Suite struct NameLocalTests {
 @Test func decodesEveryNativeNameMember() throws {
  let decoder = JSONDecoder()
  decoder.keyDecodingStrategy = .convertFromSnakeCase
  let base = #"{"country":"DE","state":"BY","name":"Munich","continent":"EU","language":"de","direction":"ltr","date":"2026-12-25","type":"public","regions":[],"substitute":false,"id":"city_test","distance":0,"distance_mi":0}"#
  for suffix in [#","name_local":"München"}"#, #","name_local":null}"#, "}"] {
   let data = Data((String(base.dropLast()) + suffix).utf8)
   let expected: String? = suffix.contains("München") ? "München" : nil
   #expect(try decoder.decode(Country.self, from: data).nameLocal == expected)
   #expect(try decoder.decode(State.self, from: data).nameLocal == expected)
   #expect(try decoder.decode(City.self, from: data).nameLocal == expected)
   #expect(try decoder.decode(CityNearest.self, from: data).nameLocal == expected)
   #expect(try decoder.decode(Language.self, from: data).nameLocal == expected)
   #expect(try decoder.decode(Holiday.self, from: data).nameLocal == expected)
   #expect(try decoder.decode(PointCity.self, from: data).nameLocal == expected)
  }
 }
}
