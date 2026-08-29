# parseapi Swift

Official parseAPI client for Swift. iOS, macOS, watchOS, tvOS.

```swift
// Package.swift dependencies
.package(url: "https://github.com/parseapi/swift", from: "0.1.0")
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
try await parse.phone("+14155552671")
try await parse.postal("28202", country: "US")
try await parse.postalNearby("28202", country: "US", radius: 40)
try await parse.postalDistance("28202", "10001", country: "US")
try await parse.city("charlotte", country: "US")
try await parse.cityId("city_mb8mbqrkz8zb")
try await parse.citySearch("char", country: "US", limit: 10)
try await parse.cityNearest(35.2271, -80.8431)
try await parse.country("US")
try await parse.countryStates("US")
try await parse.state("NC", country: "US")
try await parse.stateDistricts("NC", country: "US")
try await parse.district("37081")
try await parse.continent("NA")
try await parse.continentCountries("NA")
try await parse.currency("USD")
try await parse.currencyRate("USD", "EUR")
try await parse.language("en")
try await parse.name("BILLY OSHALL")
try await parse.timezone("America/New_York")
try await parse.timezoneAt(40.7128, -74.006)
try await parse.holiday("US", year: 2026)
try await parse.holidayDate("US", "2026-12-25")
try await parse.elevation(35.2271, -80.8431)
try await parse.point(36.0726, -79.792)
try await parse.weather(40.7128, -74.006)
try await parse.domain("example.com")
try await parse.mx("example.com")
try await parse.useragent(uaString)
try await parse.emoji("rocket")
try await parse.emojiSearch("fire")
```

Every response is a typed struct. Nullable fields are optionals.

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
    retries: 2                    // automatic retries on network errors, 429, and 5xx
)
```

Requires Swift 5.9 or later. iOS 15, macOS 12, watchOS 8, tvOS 15. Foundation only, zero dependencies.

## Docs

Full field reference for every endpoint: [parseapi.com/docs](https://parseapi.com/docs)
