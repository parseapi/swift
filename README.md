```swift
// Package.swift dependencies
.package(url: "https://github.com/parseapi/swift", from: "0.3.2")
```

```swift
import ParseAPI

let parse = try ParseAPI("parse_app_...")
let ip = try await parse.ip("8.8.8.8")
```

Get a key at [parseapi.com](https://parseapi.com). In an app, mint an App key on the dashboard and list your bundle identifier on it. The client sends your bundle identifier as `X-App-Id` automatically. A missing key falls back to the `PARSEAPI_KEY` environment variable.

## Weather from a postal code

Start with the postal code, then pass its coordinates to weather. Reuse the client from the example above.

```swift
let place = try await parse.postal("28202", country: "US")
if let lat = place.latitude, let lon = place.longitude {
    let weather = try await parse.weather(lat, lon)
    print(weather)
}
```

The coordinates represent the postal area. Weather is for that point. Missing coordinates skip the weather lookup. This composition performs two ordinary lookups when coordinates are available, with the retry policy below.

Run the example in your existing async task.

## Supply the context you know

Pass `country` when a postal code or national phone number needs disambiguation. A complete international phone number already carries its country context. For a numeric date such as `03/04/2026`, supply the intended `format`. Defaults resolve what the input establishes. Ambiguous input needs your context.

Results are plain data. Pass a returned code or coordinate to another operation when the task needs it. Check nullable values before composing the next call.

## Calls

One method per endpoint, named after the route. Async throughout.

```swift
try await parse.ip("8.8.8.8")
try await parse.ipSelf()
try await parse.email("hello@gmail.com")
try await parse.vat("DE136695976")
try await parse.iban("DE89370400440532013000")
try await parse.bin("424242")
try await parse.npi("1881018208")
try await parse.phone("+14155552671")
try await parse.postal("SW1A 1AA")
try await parse.postal("28202", country: "US")
try await parse.postalNearby("28202", country: "US", radius: 40)
try await parse.postalDistance("28202", "10001", country: "US")
try await parse.city("charlotte", country: "US")
try await parse.cityId("city_mb8mbqrkz8zb")
try await parse.citySearch("char", country: "US", limit: 10)
try await parse.cityNearest(35.2271, -80.8431)
try await parse.cityNearby("denver", radius: 8, unit: "mi")
try await parse.country("US")
try await parse.countryStates("US")
try await parse.state("colorado")
try await parse.state("NC", country: "US")
try await parse.stateDistricts("NC", country: "US")
try await parse.district("37081")
try await parse.continent("NA")
try await parse.continentCountries("NA")
try await parse.bloc("EU")
try await parse.blocCountries("EU")
try await parse.currency("USD")
try await parse.currencyRate("USD", "EUR")
try await parse.language("en")
try await parse.name("BILLY OSHALL")
try await parse.name("Andrea", country: "IT")
try await parse.time() // UTC now
try await parse.time("America/New_York")
try await parse.timeAt(40.7128, -74.006)
try await parse.date("03/04/2026", format: "mdy")
try await parse.dateToday()
try await parse.holiday("US", year: 2026)
try await parse.holidayDate("US", "2026-12-25")
try await parse.elevation(35.2271, -80.8431)
try await parse.point(36.0726, -79.792)
try await parse.weather(40.7128, -74.006)
try await parse.domain("example.com")
try await parse.asn("AS13335")
try await parse.mac("00:1B:63:84:45:E6")
try await parse.mx("example.com")
try await parse.dns("example.com")
try await parse.dns("_dmarc.example.com", type: "TXT")
try await parse.useragent(uaString)
try await parse.vin("1HGCM82633A004352")
try await parse.naics("541511")
try await parse.naicsSearch("coffee shop", limit: 5)
try await parse.tariff("8471.30.01.00")
try await parse.tariffSearch("sunglasses")
try await parse.emoji("rocket")
try await parse.emojiSearch("fire")
try await parse.address("123 Main St", country: "US")
try await parse.addressSearch("123 Main", country: "US", postal: "28202")
try await parse.company("01234567", country: "GB")
```

NAICS records include classification `exclusions`, each with a description and linked codes. Generic exclusions can have no linked codes. Omitted or null exclusions in older responses remain unknown. Search results also include `match`: the matched `field` (`name`, `term` or `naics`) and `text`, plus `corrections` with `from` and `to` tokens for typo fallback. Corrections are empty for exact, plural and prefix matches. Direct code lookups omit `match`. Older responses may omit it.

Every response is a typed struct. Nullable fields are optionals. Unknown response fields are ignored.

Reuse a client across calls. Each method performs its own lookup and returns data. `countryStates("US")` fetches the states directly. It does not fetch the country first.

`carrier`, `caller`, and `hlr` are metered lookups for secret keys on a server. App keys answer them with a 403.

DNS uses pooled requests on every plan. Omit `type` to check A, AAAA, CNAME, MX, NS, TXT, SOA, CAA, SRV and PTR. Records contain `name`, `type`, `ttl` in seconds and a DNS presentation `value`. TXT values retain quoting and chunk boundaries. A selected question can include its CNAME chain. Empty records mean no records. Lookup failures remain errors.

## Time

`time` returns local ISO `at` with its UTC offset and integer Unix seconds in `unix`. With `deep: true`, `deep.offsetSeconds` is the exact offset and `deep.offsetMinutes` is whole minutes. Historical offsets and ISO times can include offset seconds. Omitted `at` means now. With `to`, an offsetless `at` is source wall time. Otherwise it is UTC. Include an offset for repeated local times around a clock change. Current time and conversion use pooled requests on every plan. Coordinate clock fields can be null when the timezone is unknown. Existing `timezone` methods remain supported.

## Measurements

```swift
let result = try await parse.measure("5 ft 11 in", to: "cm")
let units = try await parse.measureUnits(unit: "m")
```

`amount` is a decimal string, such as `"180.34"`. Without `to`, the API returns the canonical unit for the measurement type. Pass `locale` for number formatting and `system` (`us` or `imperial`) when a customary unit needs context. Ambiguous input returns `valid: false`, a `reason`, and available `choices`. Invalid or incompatible target units use the normal API error.

Unit discovery accepts optional `query`, `type`, and `unit` filters. `unit` selects compatible targets. Omit the filters for the reviewed catalog. Both operations use pooled requests.

## Place statistics and optional detail

Postal and District paid profiles include `deep.property_tax` where supported. It contains `annual_median`, `currency` and `period`: median annual property tax payable on owner-occupied homes in the statistical area. The amount is adjusted to the final year of the reporting period (`YYYY-YYYY`). This is an area statistic, not a rate or an individual property bill. Unsupported, missing and censored estimates are null.

```swift
let place = try await parse.postal("28202", country: "US", deep: true)
let propertyTax = place.deep?.propertyTax
```

Read `population_period` alongside `population`: a reporting year (`YYYY`) or period (`YYYY-YYYY`), null when unknown or unverifiable. Keep missing or null values unknown and preserve a known zero. These fields belong to full place profiles. State district lists include each district's population and period. Postal nearby and distance detail remains metropolitan associations only. Continent population and its period remain in core.

Point returns the timezone ID with the core location. Its optional deep detail adds terrain and compact nearest-city context on every plan. A nearest city is null when none is within 200 km.

Weather returns current conditions by default. Paid deep adds specialist current measurements, forecasts and related detail. A past `date` is a UTC day and requires deep: it adds `deep.history` alongside current conditions. Date alone does not request history.

```swift
try await parse.weather(40.7128, -74.006, deep: true, date: "2026-08-15")
```

Tariff starts with the general schedule line. Paid deep adds units and the special and other schedule columns. An optional origin then resolves country-specific measures. The three calls below show those successive choices. Without origin, schedule detail is still returned and origin-dependent fields are null. A null effective rate is not a zero rate.

```swift
try await parse.tariff("8471.30.01.00")
try await parse.tariff("8471.30.01.00", deep: true)
try await parse.tariff("8471.30.01.00", deep: true, origin: "CN")
```

Address search uses context from the form: prefer postal, or city and state. An optional end-user `ip` is a locality hint for server-side calls. An empty result explains itself with `reason`: `more_input`, `missing_context` or `no_matches`. With suggestions, reason is null. Older responses may omit it, and future reasons remain strings. Catalog and lookup failures use the existing API errors.

HLR reports status at the last check. `live` means assigned and `connected` means reachable at that check. Cached results may be returned. Null means unconfirmed. Deep diagnostics stay within the same metered lookup.

## Deep

Choose enrichment for the question you need answered.

| Operation | What `deep` requests |
|---|---|
| IP | Richer IP fields included with a paid plan. No separate check meter. |
| Domain | Registration dates, registrar, status and DNSSEC, included with a paid plan. Use `dns` for DNS records and `mx` for mail routing. |
| Email | A metered deliverability check, using included email checks or enabled on-demand usage. |
| VAT | A metered registry check where supported, using included VAT checks or enabled on-demand usage. |
| Phone | Numbering-plan state and timezone, pooled on every plan. |
| Postal, Country, State, City, District | Geographic profiles on paid plans. Collections keep deep on each record. |
| Company, VIN, NPI, NAICS, Name, Weather | Richer reference/profile facts on paid plans. |
| Time, Date, Currency, Language, Emoji, IBAN | Optional same-question facts, pooled on every plan. |
| Point | Terrain and compact nearest-city context, pooled on every plan. The timezone ID is core. |
| Carrier, HLR | Place or network details included in the same metered lookup. |

Carrier, caller, and HLR are separate metered operations. Choose them explicitly when you need their answers. Ordinary lookups retry twice by default. Metered checks use one attempt by default. Setting retries explicitly can repeat paid usage.

Without `deep`, the response omits that key. When requested, it is an empty object if access is locked or the operation has no deep fields. Otherwise it contains the available fields. A missing or null field means unknown. Empty collections remain distinct from unknown collections. A list request never becomes a separate billable lookup for each nested record.

```swift
let place = try await parse.postal("28202", country: "US")
let profile = try await parse.postal("28202", country: "US", deep: true)
let population = profile.deep?.population
let cities = try await parse.citySearch("char", deep: true)
let cityPopulation = cities.cities.first?.deep?.population
```

Metered checks require a secret key on a server. App keys can request paid-plan enrichment when their team has access.

```swift
let ip = try await parse.ip("52.94.76.10", deep: true)
if ip.deep?.datacenter == true {
    // datacenter IP
}
```

## Errors

Every non-2xx response throws a `ParseAPIError` with `status`, `code`, `docs`, and `requestId`. Branch on `code`.

```swift
do {
    _ = try await parse.city("atlantis")
} catch let error as ParseAPIError where error.code == "not_found" {
    // no such city
}
```

## Options

```swift
let parse = try ParseAPI(
    "parse_app_...",
    appId: "com.example.weather", // sent as X-App-Id, defaults to your bundle identifier
    timeout: 10,                  // per-attempt timeout in seconds
    retries: nil                  // use the retry default for each endpoint
)
```

Ordinary lookups retry up to twice on network failures, 429, 500, 502, 503, and 504. Carrier, caller, HLR, and email/VAT deep lookups do not retry automatically. Address deep also uses zero retries, reserved for future verification. An explicit `retries` value applies to every lookup, including metered requests. A retry may count as another lookup.

Cancelled tasks stop the lookup and are not retried. Redirects are returned as errors.

Requires Swift 6.0 or later. iOS 15, macOS 12, watchOS 8, tvOS 15. Foundation only, zero dependencies.

## Docs

Full field reference for every endpoint: [parseapi.com/docs](https://parseapi.com/docs)

## Compatibility checks

Run `swift test` and `python3 scripts/check-api.py` before a release. The API check compares compiler-exported declarations with `api/ParseAPI.api`. Use `python3 scripts/check-api.py --update` only after reviewing an intentional API addition.

Pushes and pull requests run the tests on Swift 6.0 and 6.3.3. The API check uses Swift 6.3.3, the compiler used for the baseline. Device-platform validation remains a release check.

BIN lookup accepts 6-11 digits as a string, including leading zeros. Spaces and hyphens are accepted. `prefix` is the actual longest match and can be shorter than the input. Unknown reference fields are null. `deep` adds an empty object on every plan.
