import Foundation
import Testing
@testable import ParseAPI

struct ISONamingTests {
 private func decode<T:Decodable>(_ type:T.Type,_ fields:String)throws->T {
  let decoder=JSONDecoder();decoder.keyDecodingStrategy = .convertFromSnakeCase
  return try decoder.decode(type,from:Data(fields.utf8))
 }
 @Test func releasedAndCanonicalNamesPreserveNativeMembers()throws {
  for fields in [#""iso3":"USA","numeric":840"#,#""iso_alpha3":"USA","iso_numeric":840"#] {
   let value=try decode(Country.self,#"{"country":"US","name":"United States","languages":[],"# + fields + "}")
   #expect(value.iso3=="USA" && value.numeric==840)
   let encoder=JSONEncoder();encoder.keyEncodingStrategy = .convertToSnakeCase
   let encoded=try JSONSerialization.jsonObject(with:encoder.encode(value)) as! [String:Any]
   #expect(encoded["iso_alpha3"] as? String == "USA" && encoded["iso_numeric"] as? Int == 840)
   #expect(encoded["iso3"]==nil && encoded["numeric"]==nil)
   let deep=try decode(CountryDeep.self,"{"+fields+"}");#expect(deep.iso3=="USA" && deep.numeric==840)
  }
  for fields in [#""iso3":"hrv""#,#""iso_alpha3":"hrv""#] {
   let value=try decode(Language.self,#"{"language":"hr","name":"Croatian","direction":"ltr","# + fields + "}")
   #expect(value.iso3=="hrv")
  }
  for fields in [#""iso":"US-CA""#,#""iso_3166_2":"US-CA""#,#""iso_subdivision":"US-CA""#] {
   let value=try decode(State.self,#"{"state":"CA","name":"California","country":"US","timezones":[],"# + fields + "}")
   #expect(value.iso=="US-CA")
  }
 }
 @Test func releasedDeepMembersRemainReadable()throws {
  let language=try decode(LanguageDeep.self,#"{"iso3":"eng","countries":["US"]}"#)
  #expect(language.iso3=="eng" && language.countries==["US"])
  let state=try decode(StateDeep.self,#"{"fips":"06","capital":"Sacramento","area_codes":["916"],"tax":"Sales tax","tax_rate":0}"#)
  #expect(state.fips=="06" && state.capital=="Sacramento" && state.areaCodes==["916"])
  #expect(state.tax?.name=="Sales tax" && state.taxRate==0)
  let encoder=JSONEncoder();encoder.keyEncodingStrategy = .convertToSnakeCase
  let raw=try JSONSerialization.jsonObject(with:encoder.encode(state)) as! [String:Any]
  #expect(raw["fips"]==nil && raw["capital"]==nil && raw["area_codes"]==nil && raw["tax_rate"]==nil)
 }
 @Test func canonicalNullWinsInEitherKeyOrder()throws {
  for fields in [#""iso_alpha3":null,"iso_numeric":null,"iso3":"USA","numeric":840"#,#""iso3":"USA","numeric":840,"iso_alpha3":null,"iso_numeric":null"#] {
   let value=try decode(Country.self,#"{"country":"US","name":"United States","languages":[],"# + fields + "}")
   #expect(value.iso3==nil && value.numeric==nil)
   let deep=try decode(CountryDeep.self,"{"+fields+"}");#expect(deep.iso3==nil && deep.numeric==nil)
  }
  let language=try decode(Language.self,#"{"language":"hr","name":"Croatian","direction":"ltr","iso_alpha3":null,"iso3":"hrv"}"#)
  #expect(language.iso3==nil)
  let state=try decode(State.self,#"{"state":"CA","name":"California","country":"US","timezones":[],"iso_subdivision":null,"iso":"US-CA","iso_3166_2":"US-TX"}"#)
  #expect(state.iso==nil)
 }
}
