import Foundation

// Response types for the parseAPI public API. Shapes are append-only
// upstream, so these only ever grow. Nullable fields are optionals.
// Deep objects follow the triad: nil when not requested, empty when
// requested but locked, populated when unlocked, so every field inside
// a deep type is optional. Unknown fields are ignored by Codable.
// JSON keys are snake_case and decode with convertFromSnakeCase.

public struct IPDeep: Codable, Sendable {
	public let state: String?
	public let city: String?
	public let registry: String?
	public let datacenter: Bool?
	public let relay: Bool?
	public let tor: Bool?
	public let vpn: Bool?
	public let provider: String?
}

public struct IP: Codable, Sendable {
	public let ip: String
	public let country: String?
	public let countryName: String?
	public let continent: String?
	public let asn: String?
	public let asnName: String?
	public let deep: IPDeep?
}

public struct Continent: Codable, Sendable {
	public let continent: String
	public let name: String
	public let region: String
	public let subregion: String
	public let population: Int?
	public let area: Double?
	public let emoji: String
}

public struct ContinentCountryItem: Codable, Sendable {
	public let country: String
	public let name: String
	public let emoji: String?
	public let callingCode: String?
}

public struct ContinentCountries: Codable, Sendable {
	public let continent: String
	public let countries: [ContinentCountryItem]
}

public struct Country: Codable, Sendable {
	public let country: String
	public let iso3: String
	public let numeric: Int
	public let name: String
	public let fullName: String?
	public let localName: String?
	public let demonym: String?
	public let capital: String?
	public let capitalLat: Double?
	public let capitalLon: Double?
	public let continent: String
	public let region: String?
	public let subregion: String?
	public let population: Int?
	public let area: Double?
	public let currency: String?
	public let currencyName: String?
	public let currencySymbol: String?
	public let tld: String?
	public let callingCode: String?
	public let emoji: String?
	public let languages: [String]
	public let borders: [String]
}

public struct CountryStateItem: Codable, Sendable {
	public let state: String
	public let name: String
	public let type: String?
}

public struct CountryStates: Codable, Sendable {
	public let country: String
	public let states: [CountryStateItem]
}

public struct State: Codable, Sendable {
	public let state: String
	public let name: String
	public let localName: String?
	public let type: String?
	public let country: String
	public let countryName: String?
	public let latitude: Double?
	public let longitude: Double?
	public let population: Int?
	public let area: Double?
	public let timezone: String?
	public let timezones: [String]
	public let iso31662: String?
	public let fips: String?
	public let capital: String?
	public let areaCodes: [String]
	public let tax: String?
	public let taxRate: Double?
}

public struct StateDistrictItem: Codable, Sendable {
	public let district: String
	public let name: String
	public let type: String?
}

public struct StateDistricts: Codable, Sendable {
	public let state: String
	public let stateName: String?
	public let country: String
	public let countryName: String?
	public let districts: [StateDistrictItem]
}

public struct District: Codable, Sendable {
	public let district: String
	public let name: String
	public let type: String?
	public let state: String?
	public let stateName: String?
	public let country: String
	public let countryName: String?
	public let latitude: Double?
	public let longitude: Double?
	public let population: Int?
	public let landArea: Double?
	public let waterArea: Double?
	public let seat: String?
	public let timezone: String?
	public let timezones: [String]
}

public struct City: Codable, Sendable {
	public let name: String
	public let localName: String?
	public let type: String?
	public let capital: String?
	public let state: String?
	public let stateName: String?
	public let district: String?
	public let districtName: String?
	public let country: String
	public let countryName: String?
	public let latitude: Double?
	public let longitude: Double?
	public let elevation: Double?
	public let elevationFt: Double?
	public let population: Int?
	public let landArea: Double?
	public let waterArea: Double?
	public let timezone: String?
	/// Minted parse id (city_ + 12 chars). Stable pin via cityId().
	public let id: String
}

/// Nearest-city lookups add the distance from the query point.
public struct CityNearest: Codable, Sendable {
	public let name: String
	public let localName: String?
	public let type: String?
	public let capital: String?
	public let state: String?
	public let stateName: String?
	public let district: String?
	public let districtName: String?
	public let country: String
	public let countryName: String?
	public let latitude: Double?
	public let longitude: Double?
	public let elevation: Double?
	public let elevationFt: Double?
	public let population: Int?
	public let landArea: Double?
	public let waterArea: Double?
	public let timezone: String?
	public let id: String
	public let distance: Double
	public let distanceMi: Double
}

public struct CitySearch: Codable, Sendable {
	public let q: String
	public let country: String?
	public let state: String?
	public let cities: [City]
}

public struct CityNearby: Codable, Sendable {
	public let city: String
	public let state: String?
	public let country: String
	public let radius: Double
	public let unit: String
	public let nearby: [CityNearest]
}

public struct Postal: Codable, Sendable {
	public let postal: String
	public let city: String?
	public let cityLocal: String?
	public let district: String?
	public let districtName: String?
	public let districtNameLocal: String?
	public let state: String?
	public let stateName: String?
	public let stateNameLocal: String?
	public let country: String
	public let countryName: String?
	public let latitude: Double?
	public let longitude: Double?
	public let elevation: Double?
	public let elevationFt: Double?
	public let population: Int?
	public let landArea: Double?
	public let waterArea: Double?
	public let timezone: String?
	public let currency: String?
	public let neighbors: [String]
}

public struct PostalNearbyItem: Codable, Sendable {
	public let postal: String
	public let city: String?
	public let state: String?
	public let country: String
	public let distance: Double
	public let distanceMi: Double
}

public struct PostalNearby: Codable, Sendable {
	public let postal: String
	public let country: String
	public let radius: Double
	public let unit: String
	public let nearby: [PostalNearbyItem]
}

public struct PostalDistanceEnd: Codable, Sendable {
	public let postal: String
	public let city: String?
}

public struct PostalDistance: Codable, Sendable {
	public let country: String
	public let from: PostalDistanceEnd
	public let to: PostalDistanceEnd
	public let distance: Double
	public let distanceMi: Double
}

public struct EmailDeep: Codable, Sendable {
	public let deliverable: Bool?
	public let catchall: Bool?
}

public struct Email: Codable, Sendable {
	public let email: String
	/// Suggested full address when the host is a known misspelling. Never a guess.
	public let didyoumean: String?
	public let valid: Bool
	public let domain: String?
	public let domainValid: Bool?
	public let role: Bool
	public let disposable: Bool
	public let deep: EmailDeep?
}

public struct VatAddress: Codable, Sendable {
	public let street: String?
	public let city: String?
	public let postal: String?
	public let country: String?
}

public struct VatDeep: Codable, Sendable {
	public let registered: Bool?
	public let name: String?
	public let address: VatAddress?
	public let consultation: String?
	public let consulted: String?
}

public struct Vat: Codable, Sendable {
	public let vat: String?
	public let valid: Bool
	public let country: String?
	public let from: String?
	public let deep: VatDeep?
}

/// Always empty. The metered proves are their own endpoints: carrier, caller, hlr.
public struct PhoneDeep: Codable, Sendable {}

public struct Phone: Codable, Sendable {
	public let phone: String?
	public let valid: Bool
	/// What the numbering plan can see: mobile, landline, toll_free, unknown.
	/// Never voip (that is the carrier field's word). Present when valid.
	public let type: String?
	/// NPA-derived state code (US/CA). Present when valid.
	public let state: String?
	public let stateName: String?
	public let country: String?
	public let national: String?
	public let international: String?
	public let deep: PhoneDeep?
}

public struct Carrier: Codable, Sendable {
	public let phone: String?
	public let valid: Bool
	public let country: String?
	/// The network's word, including voip. Present when valid.
	public let type: String?
	/// Current carrier display name. Nil when the probe had no answer.
	public let carrier: String?
	/// Carrier is a known burner number app. Nil when carrier is unknown.
	public let burner: Bool?
	/// Issuing rate-center city.
	public let city: String?
	public let state: String?
	public let stateName: String?
}

public struct Caller: Codable, Sendable {
	public let phone: String?
	public let valid: Bool
	public let country: String?
	/// CNAM record verbatim (all-caps telco artifact). Nil when no record
	/// or outside NANP. Present when valid.
	public let caller: String?
}

public struct HLR: Codable, Sendable {
	public let phone: String?
	public let valid: Bool
	public let country: String?
	/// Assigned to a subscriber. Present when valid.
	public let live: Bool?
	/// Handset reachable right now. Nil means unconfirmed, never no.
	public let connected: Bool?
	/// The six network extras fill on live HLR dips only. Nil elsewhere (NANP, failover).
	public let roaming: Bool?
	public let roamingNetwork: String?
	/// ISO2, uppercase.
	public let roamingCountry: String?
	/// Current serving network name.
	public let network: String?
	public let originalNetwork: String?
	public let mcc: String?
	public let mnc: String?
}

public struct MXRecord: Codable, Sendable {
	public let priority: Int
	public let host: String
}

public struct DomainRegistration: Codable, Sendable {
	public let registered: Bool?
	public let created: String?
	public let updated: String?
	public let expires: String?
	public let registrar: String?
	public let status: [String]?
	public let dnssec: Bool?
}

public struct DomainDeep: Codable, Sendable {
	public let a: [String]?
	public let aaaa: [String]?
	public let ns: [String]?
	public let mx: [MXRecord]?
	public let txt: [String]?
	/// The brand behind the MX (Google, Microsoft).
	public let mailhost: String?
	public let registration: DomainRegistration?
}

public struct Domain: Codable, Sendable {
	public let domain: String
	public let available: Bool
	public let deep: DomainDeep?
}

public struct MX: Codable, Sendable {
	public let domain: String
	public let mx: [MXRecord]
}

public struct UseragentDeviceDeep: Codable, Sendable {
	public let type: String?
	public let brand: String?
	public let model: String?
	public let cpu: String?
	public let touchscreen: Bool?
}

public struct UseragentOSDeep: Codable, Sendable {
	public let name: String?
	public let version: String?
	public let platform: String?
}

public struct UseragentBrowserBrand: Codable, Sendable {
	public let brand: String
	public let version: String
}

public struct UseragentBrowserDeep: Codable, Sendable {
	public let name: String?
	public let version: String?
	public let type: String?
	public let brands: [UseragentBrowserBrand]?
}

public struct UseragentEngineDeep: Codable, Sendable {
	public let name: String?
	public let version: String?
}

public struct UseragentBot: Codable, Sendable {
	public let name: String?
	public let category: String?
	public let vendor: String?
	public let url: String?
}

public struct UseragentDeep: Codable, Sendable {
	public let device: UseragentDeviceDeep?
	public let os: UseragentOSDeep?
	public let browser: UseragentBrowserDeep?
	public let engine: UseragentEngineDeep?
	public let headless: Bool?
	public let bot: UseragentBot?
	public let ai: Bool?
}

public struct Useragent: Codable, Sendable {
	public let useragent: String
	public let device: String?
	public let os: String?
	public let browser: String?
	public let bot: Bool
	public let mobile: Bool
	public let deep: UseragentDeep?
}

public struct Currency: Codable, Sendable {
	public let currency: String
	public let numeric: Int?
	public let name: String
	public let namePlural: String?
	public let symbol: String?
	public let symbolNative: String?
	public let digits: Int?
	public let countries: [String]
}

/// One language by BCP 47 shortest code (en) or ISO 639-3 (eng). Codes are lowercase.
public struct Language: Codable, Sendable {
	public let language: String
	public let iso3: String?
	public let name: String
	public let localName: String?
	public let script: String?
	public let direction: String
	public let countries: [String]
}

/// A parsed person name. Junk input returns valid false, never an error.
/// Gender comes from dictionary data and is nil when the data does not decide.
public struct Name: Codable, Sendable {
	public let name: String
	public let valid: Bool
	public let prefix: String?
	public let first: String?
	public let middle: String?
	public let last: String?
	public let suffix: String?
	public let gender: String?
	public let salutation: String?
}

public struct CurrencyRate: Codable, Sendable {
	public let base: String
	public let quote: String
	public let rate: Double
	public let date: String
	public let source: String?
}

public struct TimezoneNextDST: Codable, Sendable {
	public let at: String
	public let dst: Bool
	public let offset: String
	public let abbreviation: String
}

public struct Timezone: Codable, Sendable {
	/// Echoed on coordinate lookups only.
	public let latitude: Double?
	public let longitude: Double?
	public let timezone: String?
	public let name: String?
	public let abbreviation: String?
	public let offset: String?
	public let offsetMinutes: Int?
	public let dst: Bool?
	public let nextDst: TimezoneNextDST?
}

public struct Holiday: Codable, Sendable {
	public let date: String
	public let name: String
	public let localName: String?
	/// public for an official day off, observance for cultural days.
	public let type: String
	public let regions: [String]?
	public let substitute: Bool
}

public struct HolidayYear: Codable, Sendable {
	public let country: String
	public let year: Int
	public let holidays: [Holiday]
}

public struct HolidayDate: Codable, Sendable {
	public let country: String
	public let date: String
	public let holiday: Holiday?
}

public struct Elevation: Codable, Sendable {
	public let latitude: Double
	public let longitude: Double
	public let elevation: Double?
	public let elevationFt: Double?
	public let resolution: Double?
}

public struct PointDeep: Codable, Sendable {
	public let city: CityNearest?
	public let timezone: Timezone?
}

public struct Point: Codable, Sendable {
	public let latitude: Double
	public let longitude: Double
	public let country: String?
	public let countryName: String?
	public let state: String?
	public let stateName: String?
	public let district: String?
	public let districtName: String?
	public let elevation: Double?
	public let elevationFt: Double?
	public let resolution: Double?
	public let deep: PointDeep?
}

public struct WeatherForecastPeriod: Codable, Sendable {
	public let name: String
	public let start: String?
	public let end: String?
	public let daytime: Bool?
	public let temperature: Double?
	public let temperatureF: Double?
	public let precipitationChance: Double?
	public let windSpeed: Double?
	public let windSpeedMph: Double?
	public let windDirection: Double?
	public let condition: String?
	public let conditionName: String?
	public let conditionEmoji: String?
}

public struct WeatherAlert: Codable, Sendable {
	public let event: String
	public let severity: String?
	public let urgency: String?
	public let headline: String?
	public let onset: String?
	public let expires: String?
}

public struct WeatherHour: Codable, Sendable {
	public let at: String?
	public let daytime: Bool?
	public let temperature: Double?
	public let temperatureF: Double?
	public let humidity: Double?
	public let precipitationChance: Double?
	public let windSpeed: Double?
	public let windSpeedMph: Double?
	public let windDirection: Double?
	public let condition: String?
	public let conditionName: String?
	public let conditionEmoji: String?
}

public struct WeatherDeep: Codable, Sendable {
	public let forecast: [WeatherForecastPeriod]?
	public let alerts: [WeatherAlert]?
	public let hours: [WeatherHour]?
}

public struct WeatherCurrent: Codable, Sendable {
	public let temperature: Double?
	public let temperatureF: Double?
	public let feelsLike: Double?
	public let feelsLikeF: Double?
	public let dewpoint: Double?
	public let dewpointF: Double?
	public let humidity: Double?
	public let windSpeed: Double?
	public let windSpeedMph: Double?
	public let windGust: Double?
	public let windGustMph: Double?
	public let windDirection: Double?
	public let pressure: Double?
	public let pressureInhg: Double?
	public let visibility: Double?
	public let visibilityMi: Double?
	public let condition: String?
	public let conditionName: String?
	public let conditionEmoji: String?
	public let observedAt: String?
}

public struct WeatherStation: Codable, Sendable {
	public let id: String
	public let name: String?
	public let distance: Double?
	public let distanceMi: Double?
}

public struct WeatherSource: Codable, Sendable {
	public let id: String
	public let name: String?
}

public struct Weather: Codable, Sendable {
	public let latitude: Double
	public let longitude: Double
	public let current: WeatherCurrent
	public let station: WeatherStation?
	public let source: WeatherSource
	public let deep: WeatherDeep?
}

public struct EmojiSkin: Codable, Sendable {
	public let emoji: String
	public let tone: String
	public let unicode: String?
	public let hex: String?
}

public struct Emoji: Codable, Sendable {
	public let emoji: String
	public let name: String
	public let shortcodes: [String]
	public let codepoints: [String]
	public let hex: String
	public let category: String?
	public let status: String?
	public let version: String?
	public let keywords: [String]
	public let skins: [EmojiSkin]
}

public struct EmojiSearch: Codable, Sendable {
	public let q: String
	public let emojis: [Emoji]
}
