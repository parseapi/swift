import Foundation
import Testing
@testable import ParseAPI

@Suite struct LocationStatistics {
 @Test func preservesUnknownZeroAndOpenReasons() throws {
  let decoder = JSONDecoder()
  decoder.keyDecodingStrategy = .convertFromSnakeCase
  for body in [#"{}"#, #"{"population":null,"population_period":null,"property_tax":null}"#] {
   let place = try decoder.decode(PostalDeep.self, from: Data(body.utf8))
   #expect(place.propertyTax == nil && place.populationPeriod == nil && place.population == nil)
  }
  let body = Data(#"{"population":0,"population_period":"2020-2024","property_tax":{"annual_median":0,"currency":"USD","period":"2020-2024"}}"#.utf8)
  let place = try decoder.decode(PostalDeep.self, from: body)
  #expect(place.population == 0 && place.populationPeriod == "2020-2024")
  #expect(place.propertyTax?.annualMedian == 0 && place.propertyTax?.currency == "USD" && place.propertyTax?.period == "2020-2024")
  let district = try decoder.decode(DistrictDeep.self, from: body)
  #expect(district.propertyTax?.period == "2020-2024")
  for body in [#"{"q":"a","addresses":[]}"#, #"{"q":"a","addresses":[],"reason":null}"#] {
   #expect(try decoder.decode(AddressSearch.self, from: Data(body.utf8)).reason == nil)
  }
  let result = try decoder.decode(AddressSearch.self, from: Data(#"{"q":"a","addresses":[],"reason":"future_reason"}"#.utf8))
  #expect(result.reason == "future_reason")
 }
}
