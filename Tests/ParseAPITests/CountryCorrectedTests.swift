import Foundation
import Testing
@testable import ParseAPI
private func countryFixture(_ name:String)throws->Data{try Data(contentsOf:URL(fileURLWithPath:#filePath).deletingLastPathComponent().appendingPathComponent("Fixtures/"+name))}
private func countryCodec()->JSONDecoder{let codec=JSONDecoder();codec.keyDecodingStrategy = .convertFromSnakeCase;return codec}
@Test func correctedCountryFieldsDecode() throws {
 let c=try countryCodec().decode(Country.self,from:countryFixture("CountryCorrected.json"))
 #expect(c.nameFull=="United States of America" && c.demonym=="American")
 #expect(c.gdpPerCapitaUsd==90026.52 && c.elevationAverage==760 && c.population != nil && c.area != nil)
 let encoder=JSONEncoder();encoder.keyEncodingStrategy = .convertToSnakeCase
 let raw=try #require(JSONSerialization.jsonObject(with:encoder.encode(c)) as? [String:Any])
 #expect(raw["name_full"] as? String=="United States of America")
 #expect(raw["deep"]==nil && raw["full_name"]==nil)
}
@Test func countryCanonicalNullAndZero() throws {
 let c=try countryCodec().decode(Country.self,from:Data(#"{"country":"US","name":"US","languages":[],"name_full":null,"demonym":null,"capital":{"name":null,"latitude":0,"longitude":null},"tax":{"name":null,"rate":0},"population":0}"#.utf8))
 #expect(c.nameFull==nil && c.demonym==nil && c.population==0)
 #expect(c.capital?.latitude==0 && c.capital?.longitude==nil && c.tax?.rate==0)
}
@Test func countryNestedObjectsAndFlag() throws {
 let us=try countryCodec().decode(Country.self,from:countryFixture("CountryCorrected.json"))
 #expect(us.flag=="🇺🇸" && us.capital?.name=="Washington, D.C." && us.capital?.latitude==38.89 && us.capital?.longitude == -77.05)
 let de=try countryCodec().decode(Country.self,from:countryFixture("CountryDE.json"))
 #expect(de.tax?.name=="VAT" && de.tax?.rate==19)
}
@Test func countryActualAntarctica() throws {
 let c=try countryCodec().decode(Country.self,from:countryFixture("CountryAQ.json"))
 #expect(c.currency==nil && c.currencyName==nil && c.currencySymbol==nil && c.population==0 && c.nameFull=="Antarctica")
}
@Test func countryCoreKeepsDetailUnknown() throws {
 let core=try countryCodec().decode(Country.self,from:Data(#"{"country":"US","name":"US","languages":[]}"#.utf8))
 #expect(core.population==nil && core.tax==nil)
}
