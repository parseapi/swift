// Live smoke against the edge. Canary-ready: env-driven, clean exit codes.
//   PARSEAPI_KEY       required (secret key)
//   PARSEAPI_BASE_URL  optional override
//   PARSEAPI_APP_KEY   optional app key (parse_app_): runs the X-App-Id fence checks
//   PARSEAPI_APP_ID    app id listed on that key (required with PARSEAPI_APP_KEY)
// Run: swift run smoke

import Foundation
import ParseAPI

var failures = 0
var total = 0

@MainActor
func check(_ name: String, _ ok: Bool, _ detail: String = "") {
	total += 1
	if !ok { failures += 1 }
	print("\(ok ? "ok  " : "FAIL") \(name)\(detail.isEmpty ? "" : " (\(detail))")")
}

@MainActor
func expectOk<T>(_ name: String, _ call: () async throws -> T, _ assert: (T) -> String?) async {
	do {
		let result = try await call()
		let problem = assert(result)
		check(name, problem == nil, problem ?? "")
	} catch let error as ParseAPIError {
		check(name, false, "\(error.status) \(error.code)")
	} catch {
		check(name, false, String(describing: error))
	}
}

@MainActor
func expectError<T>(_ name: String, _ call: () async throws -> T, code: String) async {
	do {
		_ = try await call()
		check(name, false, "expected error, got 200")
	} catch let error as ParseAPIError {
		check(name, error.code == code, "got \(error.code)")
	} catch {
		check(name, false, String(describing: error))
	}
}

let parse: ParseAPI
do {
	parse = try ParseAPI(appId: nil)
} catch {
	print("FAIL missing PARSEAPI_KEY")
	exit(1)
}

await expectOk("ip", { try await parse.ip("8.8.8.8") }) { $0.ip == "8.8.8.8" ? nil : "wrong ip" }
await expectOk("ipSelf", { try await parse.ipSelf() }) { $0.ip.isEmpty ? "no ip" : nil }
await expectOk("continent", { try await parse.continent("NA") }) { $0.name == "North America" ? nil : "wrong name" }
await expectOk("continentCountries", { try await parse.continentCountries("NA") }) { $0.countries.isEmpty ? "no countries" : nil }
await expectOk("country", { try await parse.country("US") }) { $0.iso3 == "USA" ? nil : "wrong iso3" }
await expectOk("countryStates", { try await parse.countryStates("US") }) { $0.states.count >= 50 ? nil : "too few states" }
await expectOk("state", { try await parse.state("NC", country: "US") }) { $0.name == "North Carolina" ? nil : "wrong name" }
await expectOk("stateDistricts", { try await parse.stateDistricts("NC", country: "US") }) { $0.districts.isEmpty ? "no districts" : nil }
await expectOk("district", { try await parse.district("37081") }) { $0.name.contains("Guilford") ? nil : "wrong district" }

var cityId: String? = nil
await expectOk("city", { try await parse.city("charlotte", country: "US") }) {
	if $0.name != "Charlotte" { return "wrong city" }
	if !$0.id.hasPrefix("city_") { return "missing id" }
	cityId = $0.id
	return nil
}
if let cityId {
	await expectOk("cityId", { try await parse.cityId(cityId) }) { $0.id == cityId && $0.name == "Charlotte" ? nil : "id mismatch" }
} else {
	check("cityId", false, "skipped, no id from city")
}

await expectOk("citySearch", { try await parse.citySearch("char", country: "US", limit: 5) }) { $0.cities.isEmpty ? "no results" : nil }
await expectOk("cityNearest", { try await parse.cityNearest(35.2271, -80.8431) }) { $0.distance >= 0 ? nil : "no distance" }
await expectOk("postal", { try await parse.postal("28202", country: "US") }) { $0.city == "Charlotte" ? nil : "wrong city" }
await expectOk("postalNearby", { try await parse.postalNearby("28202", country: "US", radius: 40) }) { $0.nearby.isEmpty ? "no nearby" : nil }
await expectOk("postalDistance", { try await parse.postalDistance("28202", "10001", country: "US") }) { $0.distance > 800 && $0.distance < 1000 ? nil : "distance \($0.distance)" }
await expectOk("email", { try await parse.email("hello@gmail.com") }) { $0.valid ? nil : "not valid" }
await expectOk("vat", { try await parse.vat("DE136695976") }) { $0.valid && $0.country == "DE" ? nil : "not valid DE" }
await expectOk("iban", { try await parse.iban("DE89370400440532013000") }) {
	$0.valid && $0.country == "DE" && $0.bank == "37040044" ? nil : "not valid DE"
}
await expectOk("iban junk", { try await parse.iban("hello") }) { $0.valid ? "expected invalid" : nil }
await expectOk("npi", { try await parse.npi("1881018208") }) {
	$0.valid && $0.registered == true ? nil : "not registered"
}
await expectOk("npi junk", { try await parse.npi("hello") }) { $0.valid ? "expected invalid" : nil }
await expectOk("phone", { try await parse.phone("+14155552671") }) { $0.phone == "+14155552671" ? nil : "wrong phone" }
// Metered core siblings: junk numbers answer 200 valid false, free, no vendor dip.
await expectOk("carrier junk free", { try await parse.carrier("555-0100") }) { $0.valid == false ? nil : "expected invalid" }
await expectOk("caller junk free", { try await parse.caller("555-0100") }) { $0.valid == false ? nil : "expected invalid" }
await expectOk("hlr junk free", { try await parse.hlr("555-0100") }) { $0.valid == false ? nil : "expected invalid" }
await expectOk("domain", { try await parse.domain("gmail.com") }) { $0.available == false ? nil : "gmail available?" }
await expectOk("mx", { try await parse.mx("gmail.com") }) { $0.mx.isEmpty ? "no mx" : nil }
await expectOk("useragent", { try await parse.useragent("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36") }) { $0.browser == "Chrome" ? nil : "browser \($0.browser ?? "nil")" }
await expectOk("vin", { try await parse.vin("1HGCM82633A004352") }) {
	$0.valid && $0.make == "Honda" && $0.year == 2003 ? nil : "wrong decode"
}
await expectOk("vin junk", { try await parse.vin("1HGCM82613A004352") }) { $0.valid ? "expected invalid" : nil }
await expectOk("currency", { try await parse.currency("USD") }) { $0.symbol == "$" ? nil : "wrong symbol" }
await expectOk("currencyRate", { try await parse.currencyRate("USD", "EUR") }) { $0.rate > 0 && $0.rate < 10 ? nil : "rate \($0.rate)" }
await expectOk("language", { try await parse.language("en") }) { $0.language == "en" && $0.name == "English" ? nil : "wrong language" }
await expectOk("name", { try await parse.name("BILLY O'SHALL") }) { $0.name == "Billy O'Shall" && $0.valid && $0.gender == "male" ? nil : "wrong name" }
await expectOk("ofac", { try await parse.ofac("AEROCARIBBEAN AIRLINES") }) { $0.sanctioned && $0.matches.first?.list == "sdn" ? nil : "expected sdn match" }
await expectOk("ofac clean", { try await parse.ofac("Jane Smith") }) { !$0.sanctioned && $0.matches.isEmpty ? nil : "expected no match" }
await expectOk("timezone", { try await parse.timezone("America/New_York") }) { $0.offsetMinutes == -240 || $0.offsetMinutes == -300 ? nil : "offset \($0.offsetMinutes.map(String.init) ?? "nil")" }
await expectOk("timezoneAt", { try await parse.timezoneAt(40.7128, -74.006) }) { $0.timezone == "America/New_York" ? nil : "zone \($0.timezone ?? "nil")" }
await expectOk("holiday", { try await parse.holiday("US") }) { $0.holidays.count > 5 ? nil : "too few holidays" }
await expectOk("holidayDate", { try await parse.holidayDate("US", "2026-12-25") }) { $0.holiday?.name == "Christmas Day" ? nil : "not christmas" }
await expectOk("holiday null (not a holiday)", { try await parse.holidayDate("US", "2026-08-12") }) { $0.holiday == nil ? nil : "expected nil" }
await expectOk("elevation", { try await parse.elevation(35.2271, -80.8431) }) { $0.elevation != nil ? nil : "no elevation" }
await expectOk("point", { try await parse.point(36.0726, -79.792) }) { $0.country == "US" ? nil : "country \($0.country ?? "nil")" }
await expectOk("weather", { try await parse.weather(40.7128, -74.006) }) { $0.station?.id != nil ? nil : "no station" }
await expectOk("emoji", { try await parse.emoji("rocket") }) { $0.emoji == "\u{1F680}" ? nil : "wrong emoji" }
await expectOk("emojiSearch", { try await parse.emojiSearch("fire", limit: 5) }) { $0.emojis.isEmpty ? "no results" : nil }

// Deep triad: asked on a free-deep endpoint always yields an object.
await expectOk("point deep triad", { try await parse.point(36.0726, -79.792, deep: true) }) { $0.deep != nil ? nil : "deep missing" }

// Honest 404 and auth errors.
await expectError("honest 404", { try await parse.city("notarealcityxyz") }, code: "not_found")
await expectError("bogus key 401", {
	try await (try ParseAPI("parse_bogusbogusbogus0", appId: nil, retries: 0)).country("US")
}, code: "invalid_api_key")

// App key fence, when an app key is in the env. Good id 200, missing or
// wrong id 403, metered core 403, email deep locked to {}.
let env = ProcessInfo.processInfo.environment
if let appKey = env["PARSEAPI_APP_KEY"], let goodAppId = env["PARSEAPI_APP_ID"] {
	let app = try! ParseAPI(appKey, appId: goodAppId)
	await expectOk("app key good id", { try await app.country("US") }) { $0.iso3 == "USA" ? nil : "wrong iso3" }
	await expectOk("app key wedge lookup", { try await app.postal("28202", country: "US") }) { $0.city == "Charlotte" ? nil : "wrong city" }

	let noId = try! ParseAPI(appKey, appId: nil, retries: 0)
	await expectError("app key missing id 403", { try await noId.country("US") }, code: "permission_denied")

	let wrongId = try! ParseAPI(appKey, appId: "com.wrong.app", retries: 0)
	await expectError("app key wrong id 403", { try await wrongId.country("US") }, code: "permission_denied")

	await expectError("app key metered 403", { try await app.carrier("555-0100") }, code: "permission_denied")

	await expectOk("app key email deep locked", { try await app.email("hello@gmail.com", deep: true) }) {
		guard let deep = $0.deep else { return "deep missing" }
		return deep.deliverable == nil && deep.catchall == nil ? nil : "deep not locked"
	}
} else {
	print("note app key fence checks skipped (set PARSEAPI_APP_KEY + PARSEAPI_APP_ID)")
}

print("\n\(total - failures)/\(total) passed")
exit(failures == 0 ? 0 : 1)
