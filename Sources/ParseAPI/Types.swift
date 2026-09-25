import Foundation

// Response types for the reviewed ParseAPI public API contract.
// Nullable fields are optionals; optional detail belongs to its owning entity.
// Deep objects follow the triad: nil when not requested, empty when
// requested but locked, populated when unlocked, so every field inside
// a deep type is optional. Unknown fields are ignored by Codable.
// JSON keys are snake_case and decode with convertFromSnakeCase.

// Core list fields have always represented collections. Keep their public
// types stable when a response carries null or omits an empty collection.
extension KeyedDecodingContainer {
	func decode<Element: Decodable>(_ type: [Element].Type, forKey key: Key) throws -> [Element] {
		try decodeIfPresent(type, forKey: key) ?? []
	}
}

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
	/// Reporting year or period for population (YYYY or YYYY-YYYY). Null when unknown or unverifiable.
	public let populationPeriod: String?
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
	public let name: String
	public let nameLocal: String?
	public let continent: String?
	public let currency: String?
	public let currencyName: String?
	public let currencySymbol: String?
	public let callingCode: String?
	public let emoji: String?
	public let languages: [String]
	public let deep: CountryDeep?
	public let timezones: [String]?
}

public struct Bloc: Codable, Sendable {
	public let bloc: String
	public let name: String
	public let members: Int
}

public struct BlocCountryItem: Codable, Sendable {
	public let country: String
	public let name: String
	public let emoji: String?
	public let callingCode: String?
}

public struct BlocCountries: Codable, Sendable {
	public let bloc: String
	public let countries: [BlocCountryItem]
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
	public let nameLocal: String?
	public let type: String?
	public let country: String
	public let countryName: String?
	public let latitude: Double?
	public let longitude: Double?
	public let timezone: String?
	public let timezones: [String]
	public let iso31662: String?
	public let deep: StateDeep?
}

public struct StateDistrictItem: Codable, Sendable {
	public let district: String
	public let name: String
	public let type: String?
	public let deep: StateDistrictDeep?
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
	public let timezone: String?
	public let timezones: [String]
	public let deep: DistrictDeep?
}

public struct City: Codable, Sendable {
	public let name: String
	public let nameLocal: String?
	public let type: String?
	public let state: String?
	public let stateName: String?
	public let district: String?
	public let districtName: String?
	public let country: String
	public let countryName: String?
	public let latitude: Double?
	public let longitude: Double?
	public let timezone: String?
	public let id: String?
	public let deep: CityDeep?
}

/// Nearest-city lookups add the distance from the query point.
public struct CityNearest: Codable, Sendable {
	public let name: String
	public let nameLocal: String?
	public let type: String?
	public let state: String?
	public let stateName: String?
	public let district: String?
	public let districtName: String?
	public let country: String
	public let countryName: String?
	public let latitude: Double?
	public let longitude: Double?
	public let timezone: String?
	public let id: String?
	public let distance: Double
	public let distanceMi: Double
	public let deep: CityDeep?
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

/// An area's share of ZIP addresses, with category shares measured independently.
public struct PostalMetro: Codable, Sendable {
	public let code: String
	public let name: String
	public let type: String
	public let share: Double?
	public let residentialShare: Double?
	public let businessShare: Double?
	public let otherShare: Double?
}

/// A supported Australian postcode suburb choice, independent of the scalar city.
public struct PostalLocality: Codable, Sendable {
	public let city: String
	public let state: String
	public let stateName: String
}

public struct Postal: Codable, Sendable {
	public let postal: String
	public let city: String?
	public let cityLocal: String?
	/// Nil is unknown. An empty list has no eligible choices. One choice does not imply city.
	public let localities: [PostalLocality]?
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
	public let timezone: String?
	public let deep: PostalDeep?
}

public struct PostalNearbyItem: Codable, Sendable {
	public let postal: String
	public let city: String?
	public let state: String?
	public let country: String
	public let distance: Double
	public let distanceMi: Double
	public let deep: PostalMetroDeep?
}

public struct PostalNearby: Codable, Sendable {
	public let postal: String
	public let country: String
	public let radius: Double
	public let unit: String
	public let nearby: [PostalNearbyItem]
	public let deep: PostalMetroDeep?
}

public struct PostalDistanceEnd: Codable, Sendable {
	public let postal: String
	public let city: String?
	public let deep: PostalMetroDeep?
}

public struct PostalDistance: Codable, Sendable {
	public let country: String
	public let from: PostalDistanceEnd
	public let to: PostalDistanceEnd
	public let distance: Double
	public let distanceMi: Double
}

public struct EmailDeep: Codable, Sendable {
	/// Suggested first name. Not a verified identity.
	public let firstName: String?
	public let noReply: Bool?
	public let tag: String?
	public let mailProvider: String?
	public let deliverable: Bool?
	public let catchall: Bool?
	/// Mailbox status: deliverable, undeliverable or risky. Null when unavailable.
	public let status: String?
	/// Why the address received this result, such as mailbox_full or mailbox_not_found. Null when unavailable.
	public let reason: String?
}

public struct Email: Codable, Sendable {
	public let email: String
	/// Suggested full address when the host is a known misspelling. Never a guess.
	public let didyoumean: String?
	public let valid: Bool
	public let free: Bool
	public let domain: String?
	public let domainType: String?
	public let domainValid: Bool?
	public let role: Bool
	public let disposable: Bool
	public let deep: EmailDeep?

	public init(from decoder: Decoder) throws {
		let c = try decoder.container(keyedBy: CodingKeys.self)
		email = try c.decode(String.self, forKey: .email)
		didyoumean = try c.decodeIfPresent(String.self, forKey: .didyoumean)
		valid = try c.decode(Bool.self, forKey: .valid)
		// 1.0.0 omits free and domain_type.
		free = try c.decodeIfPresent(Bool.self, forKey: .free) ?? false
		domain = try c.decodeIfPresent(String.self, forKey: .domain)
		domainType = try c.decodeIfPresent(String.self, forKey: .domainType)
		domainValid = try c.decodeIfPresent(Bool.self, forKey: .domainValid)
		role = try c.decode(Bool.self, forKey: .role)
		disposable = try c.decode(Bool.self, forKey: .disposable)
		deep = try c.decodeIfPresent(EmailDeep.self, forKey: .deep)
	}
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
	/// Registry-provided check time, or nil when unavailable.
	public let consultedAt: String?
}

public struct Vat: Codable, Sendable {
	public let vat: String?
	public let valid: Bool
	public let country: String?
	public let from: String?
	public let deep: VatDeep?
}

public struct Bank: Codable, Sendable {
	public let iban: String?
	public let valid: Bool
	public let country: String?
	public let formatted: String?
	public let bank: String?
	public let bankName: String?
	public let bic: String?
	/// Performed IBAN checks; absent on older responses. Statuses are open strings.
	public let checks: BankChecks?
	/// Lookup findings, separate from HTTP errors. Empty when applicable checks pass.
	public let issues: [BankIssue]?
	public let deep: BankDeep?
}

public struct BankChecks: Codable, Sendable {
	public let input: String?
	public let country: String?
	public let length: String?
	public let structure: String?
	public let checksum: String?
	public let national: String?
}

public struct BankIssue: Codable, Sendable {
	public let field: String?
	public let code: String?
	public let message: String?
}

/// Raw US ACH collection input. Preserve case, separators and leading zeros.
public struct BankUsAchInput: Sendable {
	public let routing: String
	public let account: String
	public init(routing: String, account: String) {
		self.routing = routing
		self.account = account
	}
}

public struct BankDirectory: Codable, Sendable {
	public let edition: String?
	public let country: String?
	public let match: String?
}

public struct BankUsAch: Codable, Sendable {
	public let format: String?
	public let country: String?
	public let routing: String?
	public let account: String?
	public let valid: Bool
	public let bankName: String?
	public let checks: BankUsAchChecks?
	public let issues: [BankIssue]?
}

public struct BankUsAchChecks: Codable, Sendable {
	public let routingFormat: String?
	public let routingChecksum: String?
	public let accountFormat: String?
	public let accountChecksum: String?
}

public struct BankRequirements: Codable, Sendable {
	public let country: String
	public let format: String
	public let supported: Bool
	public let fields: [BankRequirementField]
	public let checks: [String: String]
	public let limitations: [String]
}

public struct BankRequirementField: Codable, Sendable {
	public let key: String
	public let label: String
	public let required: Bool
	public let type: String
	public let length: Int?
	public let minLength: Int?
	public let maxLength: Int?
	public let maxInputLength: Int?
	public let lengthUnit: String?
	public let pattern: String?
	public let normalization: String?
}

public struct ProviderTaxonomy: Codable, Sendable {
	public let taxonomy: String?
	public let specialty: String?
	public let primary: Bool?
	public let license: String?
	public let state: String?
}

public struct ProviderSource: Codable, Sendable {
	public let edition: String?
	public let publishedAt: String?
	public let through: String?
	public let importedAt: String?
}

public struct ProviderSources: Codable, Sendable {
	public let nppes: ProviderSource?
	public let leie: ProviderSource?
	public let pecos: ProviderSource?
	public let optout: ProviderSource?
}

public struct Provider: Codable, Sendable {
	public let sources: ProviderSources?
	/// Input with accepted separators removed; nil when empty. Invalid values remain visible.
	public let npi: String?
	/// Format and NPI checksum only; does not verify a provider or credentials.
	public let valid: Bool
	/// Found in the stored NPPES snapshot. Nil when input is invalid.
	public let registered: Bool?
	/// Recorded NPI activation status. Nil when unknown; not licensure or practice status.
	public let active: Bool?
	/// NPI-only match in the stored OIG LEIE file. False is not complete exclusion clearance.
	public let excluded: Bool?
	public let type: String?
	public let name: String?
	public let first: String?
	public let last: String?
	public let credential: String?
	public let specialty: String?
	public let taxonomy: String?
	public let address: String?
	public let city: String?
	public let state: String?
	public let stateName: String?
	public let postal: String?
	public let country: String?
	public let phone: String?
	public let deep: ProviderDeep?
}

public struct ProviderEnrollment: Codable, Sendable {
	/// part_a, part_b, practitioner, dme, order_refer, mdpp. Nil when unknown.
	public let type: String?
	public let specialty: String?
	public let state: String?
}

public struct ProviderDeep: Codable, Sendable {
	public let enumeratedAt: String?
	public let updatedAt: String?
	public let reactivatedAt: String?
	public let taxonomies: [ProviderTaxonomy]?
	/// Present in the stored Medicare FFS enrollment extract; not payment eligibility.
	public let medicare: Bool?
	/// NPI-only match in the stored CMS opt-out affidavit list. Nil when unavailable.
	public let optOut: Bool?
	/// Stored enrollment rows. Nil when unavailable; empty when no rows are returned.
	public let enrollments: [ProviderEnrollment]?
	/// Recorded NPI deactivation date, YYYY-MM-DD. Nil when active or unavailable.
	public let deactivatedAt: String?
}

public struct TariffMeasure: Codable, Sendable {
	public let heading: String
	public let description: String
	public let rate: String?
	public let from: String?
	public let until: String?
	public let conditional: Bool?
}

public struct TariffDeep: Codable, Sendable {
	/// Open-string explanation when effectiveRate is nil.
	public let reason: String?
	public let origin: String?
	/// Composed ad valorem percent for matched stored measures only, not complete duty or landed cost.
	public let effectiveRate: Double?
	/// Matching stored Chapter 99 schedule measures for this code and goods origin.
	public let measures: [TariffMeasure]?
	public let units: [String]?
	public let special: String?
	public let other: String?
}

public struct Tariff: Codable, Sendable {
	/// Exact edition and answering date. Older servers may omit both.
	public let edition: String?
	public let date: String?
	public let hts: String
	public let description: String
	public let lineage: [String]
	public let general: String?
	public let revision: String
	public let deep: TariffDeep?
}

public struct TariffSearchHit: Codable, Sendable {
	public let hts: String
	public let description: String
	public let general: String?
	/// Parent descriptions, outermost first. Older responses may omit this context.
	public let lineage: [String]?
}

public struct TariffSearch: Codable, Sendable {
	/// Exact edition and answering date. Older servers may omit both.
	public let edition: String?
	public let date: String?
	public let q: String
	public let revision: String
	/// Up to 20 tariff lines, best match first.
	public let lines: [TariffSearchHit]
}

public struct VinRecall: Codable, Sendable {
	/// Government campaign number.
	public let campaign: String
	/// Report date, ISO YYYY-MM-DD.
	public let date: String?
	public let component: String?
	/// The filed summary verbatim.
	public let summary: String?
}

public struct VinDeep: Codable, Sendable {
	public let recalls: [VinRecall]?
	public let series: String?
	public let doors: Int?
	public let cylinders: Int?
	public let displacement: Double?
	public let fuel: String?
	public let horsepower: Double?
	public let drive: String?
	public let transmission: String?
	public let manufacturer: String?
	public let plantCity: String?
	public let plantState: String?
	public let plantCountry: String?
	public let gvwr: String?
}

public struct Vin: Codable, Sendable {
	public let vin: String?
	public let valid: Bool
	public let year: Int?
	public let make: String?
	public let model: String?
	public let trim: String?
	public let body: String?
	public let type: String?
	public let deep: VinDeep?
}

/// Optional numbering-plan location context, pooled on every plan.
public struct PhoneDeep: Codable, Sendable {
	public let state: String?
	public let stateName: String?
	public let timezone: String?
}

public struct Phone: Codable, Sendable {
	public let phone: String?
	public let valid: Bool
	public let country: String?
	public let type: String?
	public let national: String?
	public let international: String?
	public let deep: PhoneDeep?
}

public struct Carrier: Codable, Sendable {
	public let phone: String?
	public let valid: Bool
	public let country: String?
	public let type: String?
	public let carrier: String?
	public let burner: Bool?
	public let deep: CarrierDeep?
}

public struct Caller: Codable, Sendable {
	public let phone: String?
	public let valid: Bool
	public let country: String?
	/// CNAM record verbatim (all-caps telco artifact). Nil when no record,
	/// outside NANP, or invalid.
	public let caller: String?
}

public struct HLR: Codable, Sendable {
	public let phone: String?
	public let valid: Bool
	public let country: String?
	/// Assigned to a subscriber at the last check. Nil means unconfirmed.
	public let live: Bool?
	/// Handset reachable at the last check. Nil means unconfirmed.
	public let connected: Bool?
	public let deep: HLRDeep?
}

public struct MXRecord: Codable, Sendable {
	public let priority: Int
	public let host: String
}

public struct StackTechnology: Codable, Sendable {
	public let technology: String
	public let name: String
	public let version: String?
}

public struct StackDeep: Codable, Sendable {}

public struct Stack: Codable, Sendable {
	public let domain: String
	public let url: String
	public let checkedAt: String?
	public let scope: String
	public let pages: Int
	public let partial: Bool?
	public let cms: [StackTechnology]?
	public let servers: [StackTechnology]?
	public let frameworks: [StackTechnology]?
	public let ecommerce: [StackTechnology]?
	public let analytics: [StackTechnology]?
	public let chat: [StackTechnology]?
	public let payments: [StackTechnology]?
	public let hosting: [StackTechnology]?
	public let deep: StackDeep?
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
	public let registration: DomainRegistration?
}

public struct Domain: Codable, Sendable {
	public let domain: String
	public let available: Bool
	public let deep: DomainDeep?
}

public struct ASN: Codable, Sendable {
	public let asn: UInt32
	public let name: String?
	public let country: String?
	public let countryName: String?
}

public struct MAC: Codable, Sendable {
	public let mac: String
	public let valid: Bool
	public let vendor: String?
	public let local: Bool?
	public let multicast: Bool?
}

/// Network identity. Nil brand means unknown or ambiguous.
public struct Card: Codable, Sendable {
	public let bin: String
	public let brand: String?
	public let brandName: String?
	public let logo: String
	public let deep: CardDeep?
}

/// Optional recorded issuer details. Nil fields mean unknown.
public struct CardDeep: Codable, Sendable {
	public let prefix: String?
	public let issuer: String?
	public let country: String?
	public let type: String?
	public let prepaid: Bool?
}

/// A published DNS record. Value retains DNS presentation syntax, including TXT quoting.
public struct DNSRecord: Codable, Sendable {
	public let name: String
	public let type: String
	public let ttl: UInt32
	public let value: String
}

public struct DNS: Codable, Sendable {
	public let domain: String
	public let records: [DNSRecord]
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
	public let name: String
	public let symbol: String?
	public let symbolNative: String?
	public let digits: Int?
	public let deep: CurrencyDeep?
}

/// One language by BCP 47 shortest code (en) or ISO 639-3 (eng). Codes are lowercase.
public struct Language: Codable, Sendable {
	public let language: String
	public let name: String
	public let nameLocal: String?
	public let script: String?
	public let direction: String
	public let deep: LanguageDeep?
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
	public let deep: NameDeep?
}

public struct CurrencyRate: Codable, Sendable {
	public let base: String
	public let quote: String
	public let rate: Double
	public let date: String
	public let amount: Double?
	public let converted: Double?
	public let source: String?
}

public struct TimezoneNextDST: Codable, Sendable {
	public let at: String
	public let dst: Bool
	public let offset: String
	public let abbreviation: String
}

public typealias Time = Timezone

/// Serving timezone IDs and their pinned rule edition.
public struct TimeZones: Codable, Sendable {
	public let timezoneDatabaseVersion: String
	public let timezones: [String]
	public let at: String?
	public let zones: [TimeZoneEntry]?
}

public struct Timezone: Codable, Sendable {
	public let location: TimeLocation?
	public let latitude: Double?
	public let longitude: Double?
	public let timezone: String?
	public let abbreviation: String?
	public let offset: String?
	public let dst: Bool?
	public let at: String?
	public let unix: Int64?
	public let to: TimezoneConversionTarget?
	public let targets: [TimezoneConversionTarget]?
	public let deep: TimezoneDeep?
}

public struct TimezoneConversionTarget: Codable, Sendable {
	public let timezone: String
	public let abbreviation: String?
	public let offset: String
	public let dst: Bool
	public let at: String
	public let unix: Int64?
	public let deep: TimezoneConversionTargetDeep?
}

/// Calendar facts. Ambiguous or invalid input has valid false and nil calendar fields.
public struct DateInfo: Codable, Sendable {
	public let date: String
	public let valid: Bool
	public let unix: Int64?
	public let to: String?
	public let days: Int?
	public let deep: DateInfoDeep?
}

public struct Holiday: Codable, Sendable {
	public let date: String
	public let name: String
	public let nameLocal: String?
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
	public let elevation: Double?
	public let elevationFt: Double?
	public let resolution: Double?
	public let city: PointCity?
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
	public let deep: PointDeep?
	public let timezone: String?
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
	public let feelsLike: Double?
	public let feelsLikeF: Double?
	public let windGust: Double?
	public let windGustMph: Double?
}

public struct WeatherDeep: Codable, Sendable {
	public let forecast: [WeatherForecastPeriod]?
	public let alerts: [WeatherAlert]?
	public let hours: [WeatherHour]?
	public let history: WeatherHistory?
	public let minutes: [WeatherMinute]?
	public let days: [WeatherDay]?
	public let air: WeatherAir?
	public let current: WeatherCurrentDetails?
}

public struct WeatherHistory: Codable, Sendable {
	public let date: String?
	public let high: Double?
	public let highF: Double?
	public let low: Double?
	public let lowF: Double?
	public let precipitation: Double?
	public let precipitationIn: Double?
	public let windMax: Double?
	public let windMaxMph: Double?
	public let sunrise: String?
	public let sunset: String?
	public let moonPhase: String?
	public let moonPhaseName: String?
	public let moonPhaseEmoji: String?
}

public struct WeatherCurrent: Codable, Sendable {
	public let temperature: Double?
	public let temperatureF: Double?
	public let feelsLike: Double?
	public let feelsLikeF: Double?
	public let humidity: Double?
	public let windSpeed: Double?
	public let windSpeedMph: Double?
	public let windDirection: Double?
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

public struct Weather: Codable, Sendable {
	public let latitude: Double
	public let longitude: Double
	public let current: WeatherCurrent
	public let station: WeatherStation?
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
	public let category: String?
	public let deep: EmojiDeep?
}

public struct EmojiSearch: Codable, Sendable {
	public let q: String
	public let emojis: [Emoji]
}

public struct WeatherMinute: Codable, Sendable {
	public let at: String?
	public let precipitation: Double?
	public let precipitationIn: Double?
	public let type: String?
}

public struct WeatherDay: Codable, Sendable {
	public let date: String?
	public let high: Double?
	public let highF: Double?
	public let low: Double?
	public let lowF: Double?
	public let precipitationChance: Double?
	public let condition: String?
	public let conditionName: String?
	public let conditionEmoji: String?
	public let sunrise: String?
	public let sunset: String?
	public let moonPhase: String?
	public let moonPhaseName: String?
	public let moonPhaseEmoji: String?
}

public struct WeatherAir: Codable, Sendable {
	public let aqi: Double?
	public let aqiName: String?
	public let pm25: Double?
	public let pm10: Double?
}

public struct Address: Codable, Sendable {
	public let address: String?
	public let valid: Bool
	public let registered: Bool?
	public let number: String?
	public let street: String?
	public let unit: String?
	public let city: String?
	public let district: String?
	public let districtName: String?
	public let state: String?
	public let stateName: String?
	public let postal: String?
	public let country: String?
	public let countryName: String?
	public let latitude: Double?
	public let longitude: Double?
	public let deep: AddressDeep?
}

public struct AddressSuggestion: Codable, Sendable {
	public let address: String
	public let number: String?
	public let street: String?
	public let unit: String?
	public let city: String?
	public let state: String?
	public let postal: String?
	public let latitude: Double?
	public let longitude: Double?
}

public struct AddressSearch: Codable, Sendable {
	public let q: String
	public let postal: String?
	public let city: String?
	public let state: String?
	public let country: String?
	public let addresses: [AddressSuggestion]
	/// Why suggestions are empty: more_input, missing_context or no_matches. Null with suggestions. Open to future values. Operational failures are errors.
	public let reason: String?
}

public struct CompanyCountry: Codable, Sendable {
	public let name: String?
	public let blocs: [String]
	/// Levy name, such as VAT, GST or sales tax. Null when unknown or not applicable.
	public let tax: String?
}

public struct CompanyDeep: Codable, Sendable {
	public let activity: String?
	public let stateName: String?
	public let countryName: String?
	public let vat: String?
	public let gst: Bool?
	public let acn: String?
	public let siren: String?
	public let siege: Bool?
	public let kind: String?
	public let invoice: String?
}

public struct Company: Codable, Sendable {
	public let company: String?
	public let valid: Bool
	public let registered: Bool?
	public let country: String?
	public let type: String?
	public let name: String?
	public let active: Bool?
	public let address: String?
	public let city: String?
	public let state: String?
	public let postal: String?
	public let deep: CompanyDeep?
}

public struct AddressDeep: Codable, Sendable {}

public struct MeasureChoice: Codable, Sendable {
	public let unit: String
	public let name: String
}

public struct Measure: Codable, Sendable {
	public let measure: String
	public let valid: Bool
	public let type: String?
	/// Decimal string preserving the API's precision.
	public let amount: String?
	public let unit: String?
	public let reason: String?
	public let choices: [MeasureChoice]
}

public struct MeasureUnit: Codable, Sendable {
	public let unit: String
	public let name: String
	public let type: String
	public let aliases: [String]
}

public struct MeasureUnits: Codable, Sendable {
	public let units: [MeasureUnit]
}

public struct NAICSChild: Codable, Sendable {
	public let naics: String
	public let name: String
}

/// A classification exclusion. Generic exclusions can have no linked codes.
public struct NAICSExclusion: Codable, Sendable {
	public let description: String
	public let codes: [NAICSChild]
}

/// A query token corrected only during typo fallback.
public struct NAICSCorrection: Codable, Sendable {
	public let from: String
	public let to: String
}

/// The actual title, activity term or code that matched a search.
public struct NAICSMatch: Codable, Sendable {
	/// Currently name, term or naics. Future fields remain decodable.
	public let field: String
	public let text: String
	/// Empty for exact, plural and prefix matches.
	public let corrections: [NAICSCorrection]
}

public struct NAICS: Codable, Sendable {
	public let naics: String
	public let name: String
	public let level: Int
	public let parent: String?
	public let parentName: String?
	public let year: Int
	public let country: String
	public let deep: NAICSDeep?
}

public struct NAICSSearch: Codable, Sendable {
	public let q: String
	public let year: Int
	public let country: String
	public let results: [NAICSSearchItem]
}


public struct CountryDeep: Codable, Sendable {
	public let iso3: String?
	public let numeric: Int?
	public let fullName: String?
	public let demonym: String?
	public let capital: String?
	public let capitalLat: Double?
	public let capitalLon: Double?
	public let region: String?
	public let subregion: String?
	public let population: Int?
	/// Reporting year or period for population (YYYY or YYYY-YYYY). Null when unknown or unverifiable.
	public let populationPeriod: String?
	public let area: Double?
	/// Land area in km2.
	public let landArea: Double?
	/// Water area in km2.
	public let waterArea: Double?
	/// Coastline length in km. Zero is a known landlocked coastline.
	public let coastline: Double?
	/// Mean elevation in metres above sea level.
	public let elevation: Double?
	public let lowestPoint: CountryElevationPoint?
	public let highestPoint: CountryElevationPoint?
	public let tld: String?
	public let borders: [String]?
	public let blocs: [String]?
	public let tax: String?
	public let taxRate: Double?
	public let taxIdFormat: String?
	public let taxIdRegex: String?
	public let weekStart: String?
	public let units: String?
	public let drivingSide: String?
	public let plugs: [String]?
	public let voltage: Int?
	public let frequency: Int?
	public let emergency: CountryEmergency?
	public let postalFormat: String?
	public let postalRegex: String?
	public let ioc: String?
	public let fifa: String?
	public let plate: String?
}

public struct CountryElevationPoint: Codable, Sendable {
	public let name: String?
	/// Elevation in metres above sea level. Values below sea level are negative.
	public let elevation: Double
}


public struct CountryEmergency: Codable, Sendable {
	public let police: String?
	public let ambulance: String?
	public let fire: String?
}


public struct StateDeep: Codable, Sendable {
	public let population: Int?
	/// Reporting year or period for population (YYYY or YYYY-YYYY). Null when unknown or unverifiable.
	public let populationPeriod: String?
	public let area: Double?
	public let fips: String?
	public let capital: String?
	public let areaCodes: [String]?
	public let tax: String?
	public let taxRate: Double?
}


public struct StateDistrictDeep: Codable, Sendable {
	public let population: Int?
	/// Reporting year or period for population (YYYY or YYYY-YYYY). Null when unknown or unverifiable.
	public let populationPeriod: String?

}


public struct DistrictDeep: Codable, Sendable {
	public let population: Int?
	/// Reporting year or period for population (YYYY or YYYY-YYYY). Null when unknown or unverifiable.
	public let populationPeriod: String?
	public let area: Double?
	public let landArea: Double?
	public let waterArea: Double?
	public let seat: String?
	/// Median annual property tax payable on owner-occupied homes in this statistical area. Null when unsupported, missing or censored.
	public let propertyTax: PropertyTax?
}


public struct CityDeep: Codable, Sendable {
	public let capitalOf: String?
	public let elevation: Double?
	public let elevationFt: Double?
	public let population: Int?
	/// Reporting year or period for population (YYYY or YYYY-YYYY). Null when unknown or unverifiable.
	public let populationPeriod: String?
	public let area: Double?
	public let landArea: Double?
	public let waterArea: Double?
}


public struct PostalDeep: Codable, Sendable {
	public let elevation: Double?
	public let elevationFt: Double?
	public let population: Int?
	/// Reporting year or period for population (YYYY or YYYY-YYYY). Null when unknown or unverifiable.
	public let populationPeriod: String?
	public let area: Double?
	public let landArea: Double?
	public let waterArea: Double?
	public let currency: String?
	public let neighbors: [String]?
	public let metros: [PostalMetro]?
	public let tax: String?
	public let taxRate: Double?
	public let taxRateState: Double?
	public let taxRateCounty: Double?
	public let taxRateCity: Double?
	public let taxRateSpecial: Double?
	/// Median annual property tax payable on owner-occupied homes in this statistical area. Null when unsupported, missing or censored.
	public let propertyTax: PropertyTax?
}


public struct PostalMetroDeep: Codable, Sendable {
	public let metros: [PostalMetro]?
}


public struct BankDeep: Codable, Sendable {
	/// Directory edition and match grain, when available. Match is an open string.
	public let directory: BankDirectory?
	public let checksum: String?
	public let branch: String?
	public let account: String?
}


public struct CarrierDeep: Codable, Sendable {
	public let city: String?
	public let state: String?
	public let stateName: String?
}


public struct HLRDeep: Codable, Sendable {
	public let roaming: Bool?
	public let roamingNetwork: String?
	public let roamingCountry: String?
	public let network: String?
	public let originalNetwork: String?
	public let mcc: String?
	public let mnc: String?
}


public struct CurrencyDeep: Codable, Sendable {
	public let numeric: Int?
	public let namePlural: String?
	public let countries: [String]?
}


public struct LanguageDeep: Codable, Sendable {
	public let iso3: String?
	public let countries: [String]?
}


public struct NameDeep: Codable, Sendable {
	public let gender: String?
	public let salutation: String?
	public let short: String?
	public let directory: String?
	public let initials: String?
}


public struct TimeResolutionAlternative: Codable, Sendable {
	public let at: String?
	public let unix: Int64?
	public let offset: String?
}

public struct TimeResolution: Codable, Sendable {
	public let kind: String?
	public let policy: String?
	public let adjustmentSeconds: Int?
	public let alternatives: [TimeResolutionAlternative]?
}

public struct TimezoneDeep: Codable, Sendable {
	public let standardOffset: String?
	public let standardOffsetSeconds: Int?
	public let dstOffsetSeconds: Int?
	public let season: TimeSeason?
	public let timezoneDatabaseVersion: String?
	public let resolution: TimeResolution?
	public let name: String?
	public let offsetMinutes: Int?
	public let offsetSeconds: Int?
	public let nextDst: TimezoneNextDST?
}


public struct TimezoneConversionTargetDeep: Codable, Sendable {
	public let name: String?
	public let offsetMinutes: Int?
	public let offsetSeconds: Int?
}


public struct DateInfoDeep: Codable, Sendable {
	public let year: Int?
	public let month: Int?
	public let monthName: String?
	public let day: Int?
	public let weekday: Int?
	public let weekdayName: String?
	public let week: Int?
	public let weekYear: Int?
	public let dayOfYear: Int?
	public let quarter: Int?
	public let leap: Bool?
	public let daysInMonth: Int?
}


public struct PointCity: Codable, Sendable {
	public let name: String
	public let nameLocal: String?
	public let type: String?
	public let state: String?
	public let stateName: String?
	public let country: String
	public let countryName: String?
	public let latitude: Double?
	public let longitude: Double?
	public let id: String?
	public let distance: Double
	public let distanceMi: Double
}


public struct WeatherCurrentDetails: Codable, Sendable {
	public let dewpoint: Double?
	public let dewpointF: Double?
	public let windGust: Double?
	public let windGustMph: Double?
	public let pressure: Double?
	public let pressureInhg: Double?
	public let visibility: Double?
	public let visibilityMi: Double?
}


public struct EmojiDeep: Codable, Sendable {
	public let codepoints: [String]?
	public let hex: String?
	public let status: String?
	public let version: String?
	public let keywords: [String]?
	public let skins: [EmojiSkin]?
}


public struct NAICSDeep: Codable, Sendable {
	public let description: String?
	public let children: [NAICSChild]?
	public let exclusions: [NAICSExclusion]?
}


public struct NAICSSearchItem: Codable, Sendable {
	public let naics: String
	public let name: String
	public let level: Int
	public let parent: String?
	public let parentName: String?
	public let deep: NAICSDeep?
	public let match: NAICSMatch?
}

/// Property-tax estimate for an area, not a specific property.
public struct PropertyTax: Codable, Sendable {
	/// Median annual tax payable, in currency units adjusted to the final year of period. Not a tax rate or an individual property bill.
	public let annualMedian: Double
	/// ISO 4217 currency code, currently USD.
	public let currency: String
	/// Reporting period, YYYY-YYYY. Monetary amounts use the final year of this period.
	public let period: String
}

public struct TimeZoneEntry: Codable, Sendable {
	public let timezone: String
	public let countries: [String]
	public let area: String?
	public let abbreviation: String
	public let offset: String
	public let offsetSeconds: Int
	public let dst: Bool
	public let observesDst: Bool
}
public struct TimeTransitionState: Codable, Sendable {
	public let at: String?
	public let offset: String?
	public let offsetSeconds: Int?
	public let abbreviation: String?
	public let dst: Bool?
}
public struct TimeTransition: Codable, Sendable {
	public let at: String?
	public let before: TimeTransitionState?
	public let after: TimeTransitionState?
	public let changeSeconds: Int?
}
public struct TimeSeason: Codable, Sendable {
	public let start: TimeTransition?
	public let end: TimeTransition?
}

public struct TimeLocationInput: Codable, Sendable {
	public let type: String
	public let value: String
}
public struct TimeLocationCandidate: Codable, Sendable {
	public let id: String?
	public let name: String?
	public let country: String?
	public let state: String?
	public let timezone: String?
	public let latitude: Double?
	public let longitude: Double?
}
public struct TimeLocation: Codable, Sendable {
	public let input: TimeLocationInput
	public let status: String
	public let candidates: [TimeLocationCandidate]
	public let truncated: Bool
	public let source: String
}

// Industry names for the existing US NAICS response contract.
public typealias Industry = NAICS
public typealias IndustryChild = NAICSChild
public typealias IndustryCorrection = NAICSCorrection
public typealias IndustryDeep = NAICSDeep
public typealias IndustryExclusion = NAICSExclusion
public typealias IndustryMatch = NAICSMatch
public typealias IndustrySearch = NAICSSearch

public typealias Vehicle = Vin
public typealias VehicleDeep = VinDeep
public typealias VehicleRecall = VinRecall

// Published compatibility declarations.
public struct Iban: Codable, Sendable {
	public let iban: String?
	public let valid: Bool
	public let country: String?
	public let formatted: String?
	public let bank: String?
	public let bankName: String?
	public let bic: String?
	public let deep: IbanDeep?
}


public struct Npi: Codable, Sendable {
	public let npi: String?
	public let valid: Bool
	public let registered: Bool?
	public let active: Bool?
	public let excluded: Bool?
	public let type: String?
	public let name: String?
	public let first: String?
	public let last: String?
	public let credential: String?
	public let specialty: String?
	public let taxonomy: String?
	public let address: String?
	public let city: String?
	public let state: String?
	public let stateName: String?
	public let postal: String?
	public let country: String?
	public let phone: String?
	public let deep: NpiDeep?
}


public struct NpiEnrollment: Codable, Sendable {
	/// part_a, part_b, practitioner, dme, order_refer, mdpp. Nil when unknown.
	public let type: String?
	public let specialty: String?
	public let state: String?
}


public struct NpiDeep: Codable, Sendable {
	public let medicare: Bool?
	public let optOut: Bool?
	public let enrollments: [NpiEnrollment]?
	public let deactivatedAt: String?
}


public struct BinDeep: Codable, Sendable {}

/// Card-prefix reference data. Nil means unknown.
public struct Bin: Codable, Sendable {
	public let bin: String
	/// Actual longest matched prefix, which may be shorter than the input.
	public let prefix: String?
	public let country: String?
	public let issuer: String?
	public let brand: String?
	public let brandName: String?
	public let type: String?
	public let prepaid: Bool?
	public let deep: BinDeep?
}







public struct IbanDeep: Codable, Sendable {
	public let checksum: String?
	public let branch: String?
	public let account: String?
}
