```swift
// Package.swift dependencies
.package(url: "https://github.com/parseapi/swift", from: "0.3.0")
```

```swift
import ParseAPI

let parse = try ParseAPI("parse_app_...")
let ip = try await parse.ip("8.8.8.8")
```

Get a key at [parseapi.com](https://parseapi.com). In an app, mint an App key on the dashboard and list your bundle identifier on it. The client sends your bundle identifier as `X-App-Id` automatically. A missing key falls back to the `PARSEAPI_KEY` environment variable.

## Calls

One method per endpoint, named after the route. Async throughout.

```swift
try await parse.ip("8.8.8.8")
try await parse.ipSelf()
try await parse.email("hello@gmail.com")
try await parse.vat("DE136695976")
try await parse.iban("DE89370400440532013000")
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
try await parse.timezone("America/New_York")
try await parse.timezoneAt(40.7128, -74.006)
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
try await parse.useragent(uaString)
try await parse.vin("1HGCM82633A004352")
try await parse.tariff("8471.30.01.00")
try await parse.tariffSearch("sunglasses")
try await parse.emoji("rocket")
try await parse.emojiSearch("fire")
try await parse.address("123 Main St", country: "US")
try await parse.addressSearch("123 Main", country: "US", postal: "28202")
try await parse.company("01234567", country: "GB")
```

Every response is a typed struct. Nullable fields are optionals. Unknown response fields are ignored.

Reuse a client across calls. Each method performs its own lookup and returns data. `countryStates("US")` fetches the states directly. It does not fetch the country first.

`carrier`, `caller`, and `hlr` are metered lookups for secret keys on a server. App keys answer them with a 403.

## Deep

Pass `deep: true` to include the nested deep object with richer fields.

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
