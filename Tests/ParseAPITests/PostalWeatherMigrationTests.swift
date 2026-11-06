import Foundation
import Testing
@testable import ParseAPI

@Suite struct PostalWeatherMigration {
    private func decode<T: Decodable>(_ type: T.Type, _ body: String) throws -> T {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(type, from: Data(body.utf8))
    }

    @Test func compactPostalTaxPreservesFactsWithoutInventingMetadata() throws {
        for amount in [0.0, 3210.5] {
            let value = try decode(PostalDeep.self, "{\"currency\":\"USD\",\"property_tax\":{\"annual_median\":\(amount)}}")
 #expect(value.propertyTax?.annualMedian == amount)
 #expect(value.currency == "USD")
 #expect(value.propertyTax?.currency == nil && value.propertyTax?.period == nil)
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            let tax = try JSONSerialization.jsonObject(with: encoder.encode(value.propertyTax!)) as! [String: Any]
 #expect(Set(tax.keys) == ["annual_median"])
        }
        let legacy = #"{"property_tax":{"annual_median":0,"currency":"USD","period":"2020-2024"}}"#
        let postal = try decode(PostalDeep.self, legacy)
 #expect(postal.propertyTax?.currency == "USD" && postal.propertyTax?.period == "2020-2024")
        let district = try decode(DistrictDeep.self, legacy)
 #expect(district.propertyTax?.currency == "USD" && district.propertyTax?.period == "2020-2024")
        for body in ["{}", #"{"property_tax":null}"#] {
 #expect(try decode(PostalDeep.self, body).propertyTax == nil)
        }
    }

    @Test func minuteRateReadersWorkAcrossRolloutAndCanonicalNullWins() throws {
        let cases: [(String, Double?, Double?)] = [
            (#"{"precipitation":2.54,"precipitation_in":0.1}"#, 2.54, 0.1),
            (#"{"precipitation_rate":0,"precipitation_rate_in":0}"#, 0, 0),
            (#"{"precipitation_rate":-1,"precipitation_rate_in":-0.1}"#, -1, -0.1),
            (#"{"precipitation":99,"precipitation_in":99,"precipitation_rate":2.54,"precipitation_rate_in":0.1}"#, 2.54, 0.1),
            (#"{"precipitation_rate":2.54,"precipitation_rate_in":0.1,"precipitation":99,"precipitation_in":99}"#, 2.54, 0.1),
            (#"{"precipitation_rate":null,"precipitation_rate_in":null,"precipitation":99,"precipitation_in":99}"#, nil, nil),
            (#"{"precipitation":99,"precipitation_in":99,"precipitation_rate":null,"precipitation_rate_in":null}"#, nil, nil),
            ("{}", nil, nil),
        ]
        for (body, metric, imperial) in cases {
            let minute = try decode(WeatherMinute.self, body)
 #expect(minute.precipitationRate == metric && minute.precipitationRateIn == imperial)
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            let encoded = try JSONSerialization.jsonObject(with: encoder.encode(minute)) as! [String: Any]
 #expect(encoded["precipitation"] == nil && encoded["precipitation_in"] == nil)
 #expect(encoded["precipitation_rate"] as? Double == metric)
 #expect(encoded["precipitation_rate_in"] as? Double == imperial)
        }
        let history = try decode(WeatherHistory.self, #"{"precipitation":2.54,"precipitation_in":0.1}"#)
 #expect(history.precipitation == 2.54 && history.precipitationIn == 0.1)
    }
}
