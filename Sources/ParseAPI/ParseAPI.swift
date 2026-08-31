import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Every non-2xx response from the API. Branch on `code`, never on `message`.
public struct ParseAPIError: Error, LocalizedError, Sendable {
	/// HTTP status. 0 for a construction error.
	public let status: Int
	/// Machine-readable error code, e.g. "not_found", "invalid_api_key", "rate_limited".
	public let code: String
	public let message: String
	/// Link to the docs section for this error.
	public let docs: String?
	/// Send this if you contact support.
	public let requestId: String?

	public var errorDescription: String? { message }
}

/// Transport hook for tests and instrumentation. Takes the prepared request,
/// returns the raw body and response.
public typealias ParseAPITransport = @Sendable (URLRequest) async throws -> (Data, HTTPURLResponse)

/// parseAPI client. One instance keeps one connection pool alive.
///
///     let parse = try ParseAPI("parse_app_...")
///     let ip = try await parse.ip("8.8.8.8")
public final class ParseAPI: Sendable {
	static let version = "0.1.0"
	private static let retryStatus: Set<Int> = [429, 500, 502, 503, 504]
	private static let retryAfterCapSeconds: Double = 5

	private let key: String
	private let appId: String?
	private let baseURL: String
	private let timeout: TimeInterval
	private let retries: Int
	private let transport: ParseAPITransport

	/// - Parameters:
	///   - key: API key. Falls back to the PARSEAPI_KEY environment variable.
	///   - appId: App identity sent as X-App-Id, matched against the key's app-id
	///     list for app keys. Defaults to the bundle identifier. Secret keys ignore it.
	///   - baseURL: Override https://api.parseapi.com (tests, canaries).
	///     Also read from PARSEAPI_BASE_URL.
	///   - timeout: Per-attempt timeout in seconds. Default 10.
	///   - retries: Retries after the first attempt on network errors / 429 / 5xx.
	///     Default 2, 0 disables.
	///   - transport: Custom transport (tests, instrumentation).
	public init(
		_ key: String? = nil,
		appId: String? = Bundle.main.bundleIdentifier,
		baseURL: String? = nil,
		timeout: TimeInterval = 10,
		retries: Int = 2,
		transport: ParseAPITransport? = nil
	) throws {
		guard let resolved = key ?? Self.env("PARSEAPI_KEY"), !resolved.isEmpty else {
			throw ParseAPIError(
				status: 0,
				code: "missing_api_key",
				message: "ParseAPI: missing API key. Pass one or set PARSEAPI_KEY.",
				docs: nil,
				requestId: nil
			)
		}
		self.key = resolved
		self.appId = appId
		var base = baseURL ?? Self.env("PARSEAPI_BASE_URL") ?? "https://api.parseapi.com"
		while base.hasSuffix("/") { base.removeLast() }
		self.baseURL = base
		self.timeout = timeout
		self.retries = retries
		if let transport {
			self.transport = transport
		} else {
			let session = URLSession(configuration: .ephemeral)
			self.transport = { request in
				let (data, response) = try await session.data(for: request)
				guard let http = response as? HTTPURLResponse else {
					throw URLError(.badServerResponse)
				}
				return (data, http)
			}
		}
	}

	// Live read via getenv so tests can set and unset between constructions.
	private static func env(_ name: String) -> String? {
		guard let raw = getenv(name) else { return nil }
		return String(cString: raw)
	}

	// MARK: - Methods (mirror routes exactly, flattened like Go)

	public func ip(_ ip: String, deep: Bool = false) async throws -> IP {
		try await get("/ip/\(enc(ip))", query: deepQuery(deep))
	}

	/// Bare /ip: the caller's own IP record. The SDK always sends its key,
	/// so this rides the keyed path.
	public func ipSelf(deep: Bool = false) async throws -> IP {
		try await get("/ip", query: deepQuery(deep))
	}

	public func continent(_ code: String) async throws -> Continent {
		try await get("/continent/\(enc(code))")
	}

	public func continentCountries(_ code: String) async throws -> ContinentCountries {
		try await get("/continent/\(enc(code))/countries")
	}

	public func country(_ code: String) async throws -> Country {
		try await get("/country/\(enc(code))")
	}

	public func countryStates(_ code: String) async throws -> CountryStates {
		try await get("/country/\(enc(code))/states")
	}

	public func state(_ code: String, country: String? = nil) async throws -> State {
		try await get("/state/\(enc(code))", query: [("country", country)])
	}

	public func stateDistricts(_ code: String, country: String? = nil) async throws -> StateDistricts {
		try await get("/state/\(enc(code))/districts", query: [("country", country)])
	}

	public func district(_ code: String, country: String? = nil, state: String? = nil) async throws -> District {
		try await get("/district/\(enc(code))", query: [("country", country), ("state", state)])
	}

	public func city(_ name: String, country: String? = nil, state: String? = nil) async throws -> City {
		try await get("/city/\(enc(name))", query: [("country", country), ("state", state)])
	}

	/// Pin or refetch a city by its minted id (city_ + 12 chars).
	public func cityId(_ id: String) async throws -> City {
		try await get("/city/id/\(enc(id))")
	}

	public func citySearch(_ q: String, country: String? = nil, state: String? = nil, limit: Int? = nil) async throws -> CitySearch {
		try await get("/city", query: [("q", q), ("country", country), ("state", state), ("limit", limit.map(String.init))])
	}

	public func cityNearest(_ lat: Double, _ lon: Double) async throws -> CityNearest {
		try await get("/city", query: [("lat", num(lat)), ("lon", num(lon))])
	}

	public func cityNearby(_ name: String, radius: Double? = nil, unit: String? = nil, country: String? = nil, state: String? = nil, limit: Int? = nil) async throws -> CityNearby {
		try await get("/city/\(enc(name))/nearby", query: [
			("radius", radius.map(num)),
			("unit", unit),
			("country", country),
			("state", state),
			("limit", limit.map(String.init)),
		])
	}

	/// One language by BCP 47 shortest code (en) or ISO 639-3 (eng).
	public func language(_ code: String) async throws -> Language {
		try await get("/language/\(enc(code))")
	}

	/// Parse a person's name. Junk input returns valid false, never an error.
	public func name(_ name: String) async throws -> Name {
		try await get("/name/\(enc(name))")
	}

	public func postal(_ code: String, country: String? = nil) async throws -> Postal {
		try await get("/postal/\(enc(code))", query: [("country", country)])
	}

	public func postalNearby(_ code: String, country: String? = nil, radius: Double? = nil, unit: String? = nil) async throws -> PostalNearby {
		try await get("/postal/\(enc(code))/nearby", query: [("country", country), ("radius", radius.map(num)), ("unit", unit)])
	}

	public func postalDistance(_ from: String, _ to: String, country: String? = nil) async throws -> PostalDistance {
		try await get("/postal/\(enc(from))/distance/\(enc(to))", query: [("country", country)])
	}

	public func email(_ email: String, deep: Bool = false) async throws -> Email {
		try await get("/email/\(enc(email))", query: deepQuery(deep))
	}

	/// Format and checksum on every call. Deep asks the live EU registry.
	public func vat(_ number: String, country: String? = nil, from: String? = nil, deep: Bool = false) async throws -> Vat {
		try await get("/vat/\(enc(number))", query: [("country", country), ("from", from)] + deepQuery(deep))
	}

	/// Checksum and structure. bank and branch are codes inside the number, not names.
	public func iban(_ iban: String, country: String? = nil) async throws -> Iban {
		try await get("/iban/\(enc(iban))", query: [("country", country)])
	}

	public func phone(_ number: String, country: String? = nil, deep: Bool = false) async throws -> Phone {
		try await get("/phone/\(enc(number))", query: [("country", country)] + deepQuery(deep))
	}

	/// Metered core. Not available on app keys, use a secret key server-side.
	public func carrier(_ number: String, country: String? = nil) async throws -> Carrier {
		try await get("/carrier/\(enc(number))", query: [("country", country)])
	}

	/// Metered core, NANP only. Not available on app keys.
	public func caller(_ number: String, country: String? = nil) async throws -> Caller {
		try await get("/caller/\(enc(number))", query: [("country", country)])
	}

	/// Metered core, worldwide. Not available on app keys.
	public func hlr(_ number: String, country: String? = nil) async throws -> HLR {
		try await get("/hlr/\(enc(number))", query: [("country", country)])
	}

	public func domain(_ domain: String, deep: Bool = false) async throws -> Domain {
		try await get("/domain/\(enc(domain))", query: deepQuery(deep))
	}

	public func mx(_ domain: String) async throws -> MX {
		try await get("/mx/\(enc(domain))")
	}

	/// Parses the given user agent string. It is sent as the User-Agent
	/// header for this one request.
	public func useragent(_ ua: String, deep: Bool = false) async throws -> Useragent {
		try await get("/useragent", query: deepQuery(deep), userAgent: ua)
	}

	/// Decodes a 17-character VIN. Deep adds open recall campaigns on paid plans.
	public func vin(_ vin: String, deep: Bool = false) async throws -> Vin {
		try await get("/vin/\(enc(vin))", query: deepQuery(deep))
	}

	public func currency(_ code: String) async throws -> Currency {
		try await get("/currency/\(enc(code))")
	}

	/// Daily official reference cross rate. Pass date for a past day, amount to convert.
	public func currencyRate(_ base: String, _ quote: String, date: String? = nil, amount: Double? = nil) async throws -> CurrencyRate {
		try await get("/currency/\(enc(base))/\(enc(quote))", query: [("date", date), ("amount", amount.map(num))])
	}

	public func timezone(_ id: String, at: String? = nil) async throws -> Timezone {
		try await get("/timezone/\(enc(id))", query: [("at", at)])
	}

	/// Coords in, zone out.
	public func timezoneAt(_ lat: Double, _ lon: Double, at: String? = nil) async throws -> Timezone {
		try await get("/timezone", query: [("lat", num(lat)), ("lon", num(lon)), ("at", at)])
	}

	public func holiday(_ country: String, year: Int? = nil) async throws -> HolidayYear {
		try await get("/holiday/\(enc(country))", query: [("year", year.map(String.init))])
	}

	/// One date. A covered date that is not a holiday answers holiday nil.
	public func holidayDate(_ country: String, _ date: String) async throws -> HolidayDate {
		try await get("/holiday/\(enc(country))/\(enc(date))")
	}

	public func elevation(_ lat: Double, _ lon: Double) async throws -> Elevation {
		try await get("/elevation", query: [("lat", num(lat)), ("lon", num(lon))])
	}

	public func point(_ lat: Double, _ lon: Double, deep: Bool = false) async throws -> Point {
		try await get("/point", query: [("lat", num(lat)), ("lon", num(lon))] + deepQuery(deep))
	}

	public func weather(_ lat: Double, _ lon: Double, deep: Bool = false) async throws -> Weather {
		try await get("/weather", query: [("lat", num(lat)), ("lon", num(lon))] + deepQuery(deep))
	}

	public func emoji(_ emoji: String) async throws -> Emoji {
		try await get("/emoji/\(enc(emoji))")
	}

	public func emojiSearch(_ q: String, limit: Int? = nil) async throws -> EmojiSearch {
		try await get("/emoji", query: [("q", q), ("limit", limit.map(String.init))])
	}

	// MARK: - Transport

	private func enc(_ value: String) -> String {
		value.addingPercentEncoding(withAllowedCharacters: .parseAPIUnreserved) ?? value
	}

	private func num(_ value: Double) -> String {
		// Whole numbers print without a trailing .0 so URLs stay clean.
		value == value.rounded() && abs(value) < 1e15
			? String(Int64(value))
			: String(value)
	}

	private func deepQuery(_ deep: Bool) -> [(String, String?)] {
		deep ? [("deep", "true")] : []
	}

	private func get<T: Decodable>(_ path: String, query: [(String, String?)] = [], userAgent: String? = nil) async throws -> T {
		var url = baseURL + path
		let pairs = query.compactMap { name, value in
			value.map { "\(name)=\(enc($0))" }
		}
		if !pairs.isEmpty {
			url += "?" + pairs.joined(separator: "&")
		}
		guard let requestURL = URL(string: url) else {
			throw URLError(.badURL)
		}

		var attempt = 0
		while true {
			var request = URLRequest(url: requestURL)
			request.timeoutInterval = timeout
			request.setValue(key, forHTTPHeaderField: "X-API-Key")
			request.setValue(userAgent ?? "parseapi-swift/\(Self.version)", forHTTPHeaderField: "User-Agent")
			if let appId {
				request.setValue(appId, forHTTPHeaderField: "X-App-Id")
			}

			let data: Data
			let response: HTTPURLResponse
			do {
				(data, response) = try await transport(request)
			} catch {
				if attempt < retries {
					try await Task.sleep(nanoseconds: Self.retryDelayNanos(attempt: attempt, retryAfter: nil))
					attempt += 1
					continue
				}
				throw error
			}

			if (200..<300).contains(response.statusCode) {
				let decoder = JSONDecoder()
				decoder.keyDecodingStrategy = .convertFromSnakeCase
				return try decoder.decode(T.self, from: data)
			}

			if Self.retryStatus.contains(response.statusCode), attempt < retries {
				let retryAfter = response.value(forHTTPHeaderField: "Retry-After")
				try await Task.sleep(nanoseconds: Self.retryDelayNanos(attempt: attempt, retryAfter: retryAfter))
				attempt += 1
				continue
			}

			let body = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] ?? [:]
			throw ParseAPIError(
				status: response.statusCode,
				code: body["code"] as? String ?? "unknown_error",
				message: body["message"] as? String ?? "Request failed with status \(response.statusCode)",
				docs: body["docs"] as? String,
				requestId: body["request_id"] as? String
			)
		}
	}

	private static func retryDelayNanos(attempt: Int, retryAfter: String?) -> UInt64 {
		if let retryAfter, let seconds = Double(retryAfter), seconds >= 0 {
			return UInt64(min(seconds, retryAfterCapSeconds) * 1_000_000_000)
		}
		let jitter = Double.random(in: 0..<1) * 0.25 * pow(2, Double(attempt))
		return UInt64(jitter * 1_000_000_000)
	}
}

extension CharacterSet {
	/// RFC 3986 unreserved characters. Everything else percent-encodes,
	/// including / in timezone ids, @ in emails, and + in phone numbers.
	static let parseAPIUnreserved = CharacterSet(
		charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~"
	)
}
