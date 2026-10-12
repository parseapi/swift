import Foundation

public struct CurrencyRateDates: Codable, Sendable { public let base: [String]?; public let quote: [String]? }
public struct CurrencyRateUnits: Codable, Sendable { public let base: String?; public let quote: String? }
public struct CurrencyMissingQuote: Codable, Sendable {
	public let quote: String
	public let reason: String
}
public struct CurrencyHistoryMissing: Codable, Sendable {
	public let requestedDate: String
	public let quote: String
	public let reason: String
}
public struct CurrencyQuote: Codable, Sendable {
 public let rate: Double
 public let date: String
 public let converted: Double?
 public let stale: Bool?
 public let dates: CurrencyRateDates?
 public let units: CurrencyRateUnits?
}
public struct CurrencyObservation: Codable, Sendable {
 public let requestedDate: String
 public let rate: Double
 public let date: String
 public let converted: Double?
 public let stale: Bool?
 public let dates: CurrencyRateDates?
 public let units: CurrencyRateUnits?
}
public struct CurrencyQuoteObservation: Codable, Sendable {
 public let quote: String
 public let requestedDate: String
 public let rate: Double
 public let date: String
 public let converted: Double?
 public let stale: Bool?
 public let dates: CurrencyRateDates?
 public let units: CurrencyRateUnits?
}
public struct CurrencyRates: Codable, Sendable {
 public let base: String
 public let amount: Double?
 public let requestedDate: String?
 public let rates: [String: CurrencyQuote]
 public let missing: [CurrencyMissingQuote]
}
public struct CurrencyHistory: Codable, Sendable {
 public let base: String
 public let quote: String
 public let from: String
 public let to: String
 public let amount: Double?
 public let data: [CurrencyObservation]
 public let missing: [String]
 public let interval: String?
}
public struct CurrencyRatesHistory: Codable, Sendable {
 public let base: String
 public let quotes: [String]
 public let from: String
 public let to: String
 public let amount: Double?
 public let data: [CurrencyQuoteObservation]
 public let missing: [CurrencyHistoryMissing]
 public let interval: String?
}


public struct CurrencyResource: Codable, Sendable {
 public let currency: String
 public let name: String?
 public let symbol: String?
 public let symbolNative: String?
 public let digits: Int?
 public let deep: CurrencyDeep?
 public let unit: String?
}
public struct CurrencyList: Codable, Sendable {
 public let data: [CurrencyResource]

}

public struct CurrencySummaryRow: Codable, Sendable {
 public let quote: String
 public let from: String
 public let to: String
 public let average: Double
 public let min: Double
 public let max: Double
 public let observationCount: Int
 public let firstDate: String
 public let lastDate: String
 public let missingDayCount: Int
 public let stale: Bool?
 public let units: CurrencyRateUnits?
}
public struct CurrencySummaryMissing: Codable, Sendable {
 public let quote: String
 public let from: String
 public let to: String
 public let reason: String
 public let missingDayCount: Int
}
public struct CurrencyRatesSummary: Codable, Sendable {
 public let data: [CurrencySummaryRow]
 public let missing: [CurrencySummaryMissing]
 public let base: String
 public let quotes: [String]
 public let from: String
 public let to: String
 public let interval: String
}
