import Foundation
import Testing
@testable import ParseAPI
@Test func capitalCoordinateWireCompatibility() throws {
 for capital in [#"{"name":"Example","lat":0,"lon":null}"#,#"{"name":"Example","latitude":0,"longitude":null}"#,#"{"name":"Example","lat":99,"lon":99,"latitude":0,"longitude":null}"#,#"{"name":"Example","latitude":0,"longitude":null,"lat":99,"lon":99}"#] {
  let data=Data(("{\"country\":\"XX\",\"state\":\"X\",\"name\":\"Example\",\"capital\":"+capital+"}").utf8)
  let country=try JSONDecoder().decode(Country.self,from:data);let state=try JSONDecoder().decode(State.self,from:data)
  let c=try #require(country.capital);let s=try #require(state.capital)
  #expect(c.latitude==0 && c.longitude==nil && s.latitude==0 && s.longitude==nil)
  let encoder=JSONEncoder()
  for encoded in [try encoder.encode(c),try encoder.encode(s)] {
   let raw=try #require(JSONSerialization.jsonObject(with:encoded) as? [String:Any])
   #expect(Set(raw.keys)==["name","latitude","longitude"]);#expect(raw["latitude"] as? Double==0);#expect(raw["longitude"] is NSNull)
  }
 }
}
