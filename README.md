```swift
// Package.swift dependencies
.package(url: "https://github.com/parseapi/swift", from: "1.12.0")
```

```swift
import ParseAPI

let parse = try ParseAPI("parse_app_...")
let ip = try await parse.ip("8.8.8.8")
```

Get a key at [parseapi.com](https://parseapi.com). In an app, mint an App key on the dashboard and list your bundle identifier on it. The client sends your bundle identifier as `X-App-Id` automatically. A missing key falls back to the `PARSEAPI_KEY` environment variable.

## API versions

This SDK sends `X-API-Version: 2.1.0` on every request, including retries. Its response types match API `2.1.0`, and the client selects that contract automatically. No extra constructor setting or key change is needed. This behavior requires the matching API request-version release. The API still accepts earlier `Parse-Version` request pins.

The team setting in [Dashboard API version](https://parseapi.com/dashboard/versions) is the default for requests without a version header. This SDK's header takes precedence without changing that saved default. Existing published packages keep their documented behavior.

Test the new SDK dependency in staging, then deploy the same locked dependency with your application code and existing production key. Future major SDK upgrades can deliberately select a newer API contract, so review their migration notes before upgrading. Rolling back the code and dependency restores the contract selected by that SDK release. If the older SDK does not send a version header, its requests use the team default, which must stay unchanged through that rollback window.

Keep the package version locked in your dependency configuration or lockfile. The selected API contract stays fixed across releases within this planned SDK major. See [API versions and migration](https://parseapi.com/docs/versioning).

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

Name paid deep includes flat `short`, `directory`, and `initials` fields beside `gender`. `nameLocale` selects CLDR formatting rules and defaults to `en`. It changes formatting only. Country remains gender context, and unavailable formatting is null. Older responses may omit these fields.

## Display language

This source candidate accepts an optional language for supported display fields.
It requires the matching API localization release and data.

```swift
let country = try await parse.country("DE", lang: "fr")
print(country.name) // Allemagne
```

`lang` applies to this request. The next call uses its usual default unless it
also supplies a language. Codes, native names, numeric facts and response
structure stay unchanged. Missing translations keep the API's documented
fallback. Existing `deep` rules still apply; Date `format` retains its parsing meaning.

## Calls

One method per endpoint, named after the route. Async throughout.

```swift
try await parse.ip("8.8.8.8")
try await parse.ipSelf()
try await parse.email("hello@gmail.com")
try await parse.card("424242")
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
try await parse.currency("USD")
try await parse.currencyRate("USD", "EUR")
try await parse.language("en")
try await parse.name("BILLY OSHALL")
try await parse.name("Andrea", country: "IT")
try await parse.name("Robert James Smith", deep: true, nameLocale: "en")
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
try await parse.domain("example.com", deep: true)
try await parse.stack("example.com")
try await parse.asn("AS13335")
try await parse.mx("example.com")
try await parse.dns("example.com")
try await parse.dns("_dmarc.example.com", type: "TXT")
try await parse.useragent(uaString)
try await parse.industry("541511")
try await parse.industrySearch("coffee shop", limit: 5)
try await parse.emoji("rocket")
try await parse.emojiSearch("fire")
try await parse.address("123 Main St", country: "US")
try await parse.addressSearch("123 Main", country: "US", postal: "28202")
try await parse.company("01234567", country: "GB")
```

Industry records include classification `exclusions`, each with a description and linked codes. Generic exclusions can have no linked codes. Omitted or null exclusions in older responses remain unknown. Search results also include `match`: the matched `field` (`name`, `term` or `naics`) and `text`, plus `corrections` with `from` and `to` tokens for typo fallback. Corrections are empty for exact, plural and prefix matches. Direct code lookups omit `match`. Older responses may omit it.

Every response is a typed struct. Nullable fields are optionals. Unknown response fields are ignored.

Reuse a client across calls. Each method performs its own lookup and returns data. `countryStates("US")` fetches the states directly. It does not fetch the country first.

`carrier`, `caller`, and `hlr` are metered lookups for secret keys on a server. App keys answer them with a 403.

DNS uses pooled requests on every plan. Omit `type` to check A, AAAA, CNAME, MX, NS, TXT, SOA, CAA, SRV and PTR. Records contain `name`, `type`, `ttl` in seconds and a DNS presentation `value`. TXT values retain quoting and chunk boundaries. A selected question can include its CNAME chain. Empty records mean no records. Lookup failures remain errors.

## Company directory

`companyId` and `companySearch` retrieve directory profiles and search candidates. Existing national company-number validation stays unchanged. Use at most one of query (sent as `q`), domain, ticker or identifier, or discover by country or exact industry; country filters the candidates, exchange narrows a ticker and authority narrows an identifier. The API validates combinations. Each call makes one request and does not automatically resolve candidates or fetch linked assets.

```swift
let page = try await parse.companySearch(domain: "cloudflare.com", deep: true)
if let candidate = page.companies.first {
    let profile = try await parse.companyId(candidate.id, deep: true)
    // Optional detail fields are on profile.
}

// Continue a name search with the same selector, filters and limit.
let first = try await parse.companySearch(query: "Example", country: "US", limit: 10)
if let cursor = first.next {
    let next = try await parse.companySearch(query: "Example", country: "US", limit: 10, cursor: cursor)
}
```

Directory `deep` adds detail to each profile on paid plans in the same pooled request. Existing accounts retain their current Deep access. Omitted deep, empty deep and partial detail remain distinct; description, logo, social_profiles, phone_numbers, email_addresses, domains, founded, employees, registrations and sources may be absent on older server releases. Sources attribute only their listed selected enrichment fields. Founding precision is preserved separately from incorporation. Missing listings do not establish private ownership, and a domain match does not prove legal identity. Coverage describes the returned edition, not every company worldwide.

The public-directory service retires national-number Company lookups in both API versions. Use the directory methods with API 2.1.0.

Company directory social profiles include `platform` and `url`. Known handles are included when available; unknown handles may be omitted or returned as null by older servers. Phone and email records use `type` for the source-reported purpose. Earlier response fields remain readable by the client.

Discovery example: `try await parse.companySearch(country: "US", industry: "0700", industryType: "sic")`

Supply `industry` and `industryType` together. The supported namespace is `sic`, with an exact four-digit string such as `0700`; leading zeros are meaningful. Country-only discovery is also supported. Filters intersect and may narrow an existing selector. Country matches the profile country, not a headquarters or operating-presence claim. Unknown values do not match a requested filter. Filter-only candidates use `match.field: "filters"` and `match.value: null`; reuse the same filters and limit with a returned cursor.


## Time

`time` returns local ISO `at` with its UTC offset and integer Unix seconds in `unix`. With `deep: true`, `offsetSeconds` is the exact offset and `offsetMinutes` is whole minutes. Historical offsets and ISO times can include offset seconds. Omitted `at` means now. With `to` or `targets`, an offsetless `at` is source wall time. Otherwise it is UTC. Include an offset for repeated local times around a clock change. Current time and conversion use pooled requests on every plan. Coordinate clock fields can be null when the timezone is unknown. Existing `timezone` methods remain supported.

For an offsetless `at` with `to` or `targets`, choose how to handle a clock change with `disambiguation`. It applies to named-zone and coordinate Time calls.

| Value | Repeated time | Skipped time |
| --- | --- | --- |
| `compatible` (default) | Earlier occurrence | Shift forward by the clock change |
| `earlier` | Earlier occurrence | Shift backward by the clock change |
| `later` | Later occurrence | Shift forward by the clock change |
| `reject` | `400 ambiguous_time` | `400 nonexistent_time` |

An explicit UTC offset selects an instant directly. For example, `2026-11-01T01:30:00-04:00` and `2026-11-01T01:30:00-05:00` identify the two New York occurrences. A valid `disambiguation` value has no effect on explicit instants, current-time requests or lookups without `to` or `targets`. For user-entered appointment times, start with `reject`. Handle `ambiguous_time` or `nonexistent_time` by collecting an explicit offset or an earlier/later choice from the user. Other malformed input still uses `invalid_request`.

```swift
let result = try await parse.time("America/New_York", at: "2026-11-01T01:30:00",
    to: "UTC", disambiguation: "later")
if let target = result.to { print(target.at) } // 2026-11-01T06:30:00+00:00
```

Canonical Time `deep` includes the pinned rule edition in `timezoneDatabaseVersion` and source-wall resolution in `resolution`. Resolution records `kind` (`unique`, `overlap` or `gap`), the selected policy, signed `adjustment_seconds`, and chronological alternatives with exact `at`, Unix seconds and UTC offset. Unique times have an empty alternatives list. Explicit instants, current time and lookups without conversion omit resolution. Destination detail stays compact.

Search serving IANA IDs by city or region, or omit the query to list all (Go and Rust use an empty string). Discovery returns `timezone_database_version` and sorted `timezones`. No search matches returns `timezones: []`.

Pass `targets` to convert one instant to 1-10 zones in a single pooled request. The native list preserves order and duplicates. Use `targets` instead of `to`. The response adds `targets`, with optional detail inside each target. Unknown source coordinates return `targets: null`. An unknown destination rejects the whole request with `not_found`. Omission keeps the original response shape.

```swift
let zones = try await parse.timeZones("New York")
let result = try await parse.time("UTC", at: "2026-09-24T12:00:00Z",
    targets: ["America/New_York", "Asia/Tokyo"])
print(zones.timezones)
if let targets = result.targets {
    for target in targets { print(target.timezone, target.at) }
}
```

### Location inputs and timezone filters

`try await parse.time(source: .iata("JFK"), deep: true)` and `try await parse.timeZones(options: TimeZonesOptions(country: "US", dst: false, observesDst: true, details: true))`. `TimeSource` also has `ip`, `city`, `country`, `icao`, `unlocode` and `address` cases.

Choose one explicit location input: IP, exact city name or stable city ID, country, IATA airport, ICAO airport, port UN/LOCODE, or address. Country and state can narrow a city or address. State requires country. Address lookup requires US country context and a strict address-point match. Port lookup covers the reviewed port subset, not every assigned UN/LOCODE. IP lookup always uses the supplied IP.

Location calls add `location` with `status`, `candidates`, `truncated`, `source` and the typed input. Check `status` before using the clock: ambiguous or missing locations retain null time fields. Candidate coordinates and IDs can also be null. A country with multiple timezones does not silently choose one. Named-zone and coordinate calls retain their existing signatures.

Timezone discovery accepts country, IANA area, exact signed offset, abbreviation, DST-at-instant and observes-DST-during-year filters. `at` selects the common instant, `sort` selects timezone or offset order, and `details` adds `zones` rows plus the evaluation `at`. The default `timezones` list stays compact. False DST filters are sent explicitly. An abbreviation returns candidate zones rather than choosing one. Observes-DST uses the UTC calendar year containing `at`.

Source deep adds `standard_offset`, `standard_offset_seconds`, signed `dst_offset_seconds` and `season`. Seasonal adjustments can be negative. `season` describes the current DST-flag interval, or the next within 400 days, with actual before/after transition facts and signed `change_seconds`. Unknown boundaries remain null. These fields are optional and nullable, and destination deep stays compact.

## Place statistics and optional detail

Australian postal lookups include core `localities` with suburb choices (`city`, `state`, `stateName`) on every plan. Null or an omitted field means unknown, while `[]` means the reviewed reference has no eligible choices. `city` stays null when the source is ambiguous, even if there is only one eligible choice. Let the user select their suburb and keep manual entry available. These are geographic choices, not mailing-address verification. [G-NAF source, adaptations and licence](https://parseapi.com/legal/attribution#postal-au).

Postal paid Deep includes `currency`, `neighbors`, grouped `tax` and `property_tax: { annual_median }`. Property-tax amounts use `currency`. Tax contains `name`, `rate` and the `rate_state`, `rate_county`, `rate_city` and `rate_special` components in percent. Core provides the postal location answer.

District paid profiles include `property_tax` where supported. It contains `annual_median`, `currency` and `period`: median annual property tax payable on owner-occupied homes in the statistical area. The amount is adjusted to the final year of the reporting period (`YYYY-YYYY`). This is an area statistic, not a rate or an individual property bill. Unsupported, missing and censored estimates are null.

```swift
let place = try await parse.postal("28202", country: "US", deep: true)
let propertyTax = place?.propertyTax
```

Read `population` as the source’s count for that place boundary. Keep missing or null values unknown and preserve a known zero. State district lists include each district’s population. Postal nearby and distance detail remains metropolitan associations only. Continent population stays in core.

Point returns the timezone ID with the core location. Its optional Deep adds terrain, compact nearest-city context and supported electoral detail on paid plans. Existing accounts retain their current Deep access. A nearest city is null when none is within 200 km.

Weather returns current conditions by default. Paid deep adds specialist current measurements, forecasts and related detail. On a paid plan, a past `date` adds history for that UTC day alongside current conditions in API 2.1. Earlier contracts require an explicit detail request.

```swift
try await parse.weather(40.7128, -74.006, deep: true, date: "2026-08-15")
```


Address search uses context from the form: prefer postal, or city and state. An optional end-user `ip` is a locality hint for server-side calls. An empty result explains itself with `reason`: `more_input`, `missing_context` or `no_matches`. With suggestions, reason is null. Older responses may omit it, and future reasons remain strings. Catalog and lookup failures use the existing API errors.

HLR reports status at the last check. `live` means assigned and `connected` means reachable at that check. Cached results may be returned. Null means unconfirmed. Deep diagnostics stay within the same metered lookup.

## Deep

Call the API and get everything your plan includes. API 2.1 paid plans include their profile detail automatically; Free returns the complete everyday answer. Existing explicit `deep` options remain supported for compatibility. Mailbox verification is a separate explicit operation. An omitted or false SDK `deep` option follows the plan default; `true` remains an explicit compatibility request.

Country includes `postal_format` and `postal_regex` on every plan without requesting Deep. `postal_format` is an input hint based on one example, not a complete mask. `postal_regex` checks syntax, not whether a code exists or receives mail. Unavailable values are null.

| Operation | Included data and explicit checks |
|---|---|
| IP | Richer IP fields included with a paid plan. No separate check meter. |
| Domain | Registration dates, registrar, status and DNSSEC, included with a paid plan. Use `dns` for DNS records and `mx` for mail routing. |
| Email | Basic validation is separate. Call the explicit verification method for a metered mailbox check. |
| Phone | Numbering-plan state and timezone on paid plans in the same pooled request. Existing accounts retain their current Deep access. |
| Postal, Country, State, City, District | Geographic profiles on paid plans. Collections keep deep on each record. |
| Industry, Name, Weather | Richer reference/profile facts on paid plans. |
| Time, Date, Emoji | Optional detail on paid plans in the same pooled request. Existing accounts retain their current Deep access. |
| Language | All language facts are in Core; Deep adds no fields. |
| Point | Terrain, compact nearest-city context and supported electoral detail on paid plans in the same pooled request. Existing accounts retain their current Deep access. The timezone ID is Core. |
| Carrier, HLR | Place or network details included in the same metered lookup. |

Use `domain` for registration availability: `available` is `true`, `false`, or `nil` when unknown. Missing or null DNSSEC is unknown, while `false` is a known unsigned observation. The existing `domainResult` method and model remain available.

Explicit Email verification includes mailbox status and the reason for the result, plus a suggested first name, no-reply flag, plus-address tag and mail service. The suggested name is not a verified identity. Unavailable details are null.

Reasons include `accepted`, `invalid_format`, `invalid_domain`, `no_mail_server`, `mailbox_not_found`, `mailbox_disabled`, `mailbox_full`, `catchall`, `disposable`, `temporary_failure`, `rejected` and `unconfirmed`.

Carrier, caller, and HLR are separate metered operations. Choose them explicitly when you need their answers. Ordinary lookups retry twice by default. Metered checks use one attempt by default. Setting retries explicitly can repeat paid usage.

With `deep=true`, available extra fields appear at their natural resource homes. Without it, or without access, those optional fields are absent. Included unknown values remain null; false and zero retain their meanings. There is no `deep` response object. Empty collections remain distinct from unknown collections. A list request never becomes a separate billable lookup for each nested record.

```swift
let place = try await parse.postal("28202", country: "US")
let profile = try await parse.postal("28202", country: "US", deep: true)
let population = profile?.population
let cities = try await parse.citySearch("char", deep: true)
let cityPopulation = cities.cities.first??.population
```

Metered checks require a secret key on a server. App keys can request paid-plan enrichment when their team has access.

```swift
let ip = try await parse.ip("52.94.76.10", deep: true)
if ip?.datacenter == true {
    // datacenter IP
}
```

## Errors

Every non-2xx response throws a `ParseAPIError` with `status`, `code`, `docs`, and `requestId`, plus nullable `retryAfter` header metadata. Branch on `code`.

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

Ordinary lookups retry up to twice on network failures, 429, 500, 502, 503, and 504. Carrier, caller, HLR, and Email verification lookups do not retry automatically. Address deep also uses zero retries, reserved for future verification. An explicit `retries` value applies to every lookup, including metered requests. A retry may count as another lookup.

Automatic retries honor numeric and HTTP-date `Retry-After` values up to five seconds. A longer server wait returns the original API error immediately, with the raw header in `retryAfter`, so the application can schedule a later attempt. Missing or invalid headers use ordinary backoff.

Cancelled tasks stop the lookup and are not retried. Redirects are returned as errors.

Requires Swift 6.0 or later. iOS 15, macOS 12, watchOS 8, tvOS 15. Foundation only, zero dependencies.

## Docs

Full field reference for every endpoint: [parseapi.com/docs](https://parseapi.com/docs)

## Compatibility checks

Run `swift test` and `python3 scripts/check-api.py` before a release. The API check compares compiler-exported declarations with `api/ParseAPI.api`. Use `python3 scripts/check-api.py --update` only after reviewing an intentional API addition.

Pushes and pull requests run the tests on Swift 6.0 and 6.3.3. The API check uses Swift 6.3.3, the compiler used for the baseline. Device-platform validation remains a release check.

## Card

Send 2–11 leading digits as a string. Core returns `bin`, `brand`, `brand_name`
and a CDN SVG `logo`. Brand detection uses reviewed network rules independently
of issuer records. Unknown or ambiguous prefixes return null brand fields and a
generic logo; a known network without reviewed artwork also uses the generic logo.

Optional Deep adds `prefix`, `issuer`, `country`, `type` and `prepaid` on paid plans
in the same pooled request. Existing accounts retain their current Deep access.
Requested but locked Deep is `{}`. Six or more digits enable directory
matching. With Deep access, fewer digits return all-null Deep fields. Compare `prefix` with
`bin`: equal is an exact recorded match; shorter is broader; null is no match.
The longest row wins, including null fields. `prepaid: null` means unknown, not
false. This is partial reference data, not card validity or payment acceptance.

```swift
let card = try await parse.card("51")
print(card.logo)
let details = try await parse.card("43737400", deep: true)
print(details?.prefix as Any)
```

Leading zeros are preserved. Only ASCII spaces, tabs, CR, LF and hyphens are
removed; raw input is limited to 64 characters. Invalid prefixes are rejected
before dispatch, accepted input is forwarded unchanged. Never send a full card number.

## Stack

```swift
let result = try await parse.stack("example.com")
```

Pass a public hostname without a scheme, path, port or IP address. Stack returns the homepage URL and `checked_at` time, then eight technology arrays: `cms`, `servers`, `frameworks`, `ecommerce`, `analytics`, `chat`, `payments` and `hosting`. Each entry contains a `technology` code, name and nullable version. Multiple CMSs or servers remain separate entries. Empty arrays mean no matches on the checked homepage. An unsuccessful check returns null arrays and a null `checked_at`.

Stack checks static homepage HTML and response headers. Detections describe the checked homepage.

The complete technology result is included in the core response. The generic `deep=true` option adds only an empty object and is unnecessary for Stack. Successful checks may be reused for up to 24 hours. `pretty` optionally formats the wire JSON. Each lookup uses one request and API version 2.1.0 selected by this client.

Stack defaults to 35 seconds per attempt so a first scan has time to finish. Other lookups retain their 10-second default. An explicit client timeout takes precedence.


## Emoji catalog additions

Resolve Unicode emoji or a named shortcode, search or browse a bounded catalog,
parse emoji positions in text, and convert between Unicode and a selected shortcode source.
The ordinary lookup remains four fields:

```http
GET /emoji/rocket
```

```json
{"emoji":"🚀","name":"Rocket","shortcodes":[":rocket:","rocket"],"category":"Travel & Places"}
```

Use `deep=true` for Unicode facts, keywords, tone families and available artwork.
Artwork is keyed by style: `artwork.openmoji.svg` is the SVG URL, and
`artwork.openmoji.png["72"]` is the 72×72 PNG URL (use your language’s map
access syntax). The same shape applies to `noto` and `twemoji`. Missing styles
and formats are omitted. URLs pin immutable artwork editions and retain their bytes.
Core values stay unchanged. Text parsing returns `emojis` with UTF-16 `positions`;
conversion returns `text` and unresolved tokens with positions and reasons.

The compact JSON catalog contains offline identity, qualification-form and
shortcode indexes. Use `lang` for localized names and keywords. Metadata and
shared source notices are included in the catalog. Read an individual emoji
with Deep for its artwork links. Artwork supports Google Noto, Twemoji
and OpenMoji, with real SVG/PNG availability and immutable first-party URLs.
A device's emoji font remains the ordinary display.

These additions are a local release candidate until the matching SDK and
backend are published. Existing lookup and search contracts are preserved.


## Canonical City operations

Classic lookup, search, nearest and named-nearby methods retain their default envelopes and required-field models. Browse uses `cities` and coordinate-nearby uses `nearby`, with nullable `next_cursor` (camelCase properties in Swift/Kotlin). Keep all query options unchanged when continuing a page; no client fetches pages automatically.

```swift
let page = try await parse.citySearchList("Viena", options: CityCollectionOptions(match: "fuzzy", maxDistance: 1))
let children = try await parse.cityChildren("city_7aj899nvwyku")
let distance = try await parse.cityDistance("city_7aj899nvwyku", "city_7aj899nvwyku")
```

Explicit resource and search-list/nearby-list methods return complete City resources with `id` and `object`. Existing classic methods keep their published return types. Country inclusion/exclusion sets, timezone sets, inclusive population and meter-elevation bounds, stored-center `bbox` and signed multi-key sorting are available for collections. Unknown numeric facts do not match range filters.

Search defaults to prefix matching. Exact and fuzzy matching are explicit; fuzzy accepts maximum edit distance 1 or 2 and returns `match` evidence (`type`, `source`, `value`, `language`, `edit_distance`). Review a fuzzy choice before storing its ID.

Reviewed children, ancestors and siblings use canonical lists with partial relationship coverage. Empty data does not prove there are no geographic relatives. Children/siblings accept page controls; ancestors do not. Distance reports great-circle kilometers and miles between stored centers: zero is known zero, null is unknown, and it does not imply travel time or containment.

Strict `ambiguity=error` can return HTTP 409 `ambiguous_city` with up to two safe candidate identities. The existing error constructor and unrelated error metadata are preserved; candidates are retained only for that status/code and never contain Deep. GeoJSON is available through HTTP; these typed City list methods do not return GeoJSON.


Reviewed name forms:

```swift
let city = try await parse.cityIdResource("city_7aj899nvwyku", romanized: true)
```

Coverage by country and available fields is described at https://parseapi.com/city#coverage.

`romanized=true` requests reviewed official name forms as `name_romanized` and `romanization_language` (camelCase in Swift/Kotlin). Current reviewed forms cover 20 Japanese whole-city aliases in ja-Latn. Missing or conflicting forms stay null; ASCII folding is not substituted for an official form.


Conditional `If-None-Match` reads and GeoJSON currently use HTTP directly. A matching City ETag returns 304 without a body; ordinary billing and rate limits apply. These JSON client methods do not supply conditional-cache handling.

## ISO code fields

ISO representations use explicit JSON names. Primary codes remain `country`,
`state`, `language` and `currency`. Existing native members keep their source
compatibility through these wire mappings:

| Fact | JSON field | Native member |
| --- | --- | --- |
| Country or Language three-letter code | `iso_alpha3` | `iso3` |
| Country numeric code | `iso_numeric` | `numeric` |
| Full subdivision code, such as `US-CA` | `iso_subdivision` | `iso` |
| Currency numeric code | `iso_numeric` | `isoNumeric` |

Response decoders accept the current and earlier wire spellings. An explicit
current null keeps its meaning when an earlier spelling also appears.
JSON encoding uses the canonical ISO field names.

IP paid Deep includes supported approximate location, `state_name`, `postal`, `latitude`, `longitude`, `timezone`, routed `network`, `asn_type` and public `proxy` status. Missing facts remain null. Coordinates describe range geography, not device GPS. `asn_type` classifies the origin network, not subscriber connection technology. Proxy/VPN false means unlisted. Optional fields are omitted without the requested detail or access.

## Capital coordinate migration

Country and State capital coordinates use `latitude` and `longitude`. Update
`capital.lat` and `capital.lon` reads to `capital.latitude` and
`capital.longitude` when adopting this release.

## Postal and Weather migration

Postal `property_tax` uses `PostalPropertyTax`. Its known `annual_median`
remains available when currency and period are absent. Update explicit tax-type
annotations; optional legacy currency/period members retain supplied older facts.
Currency context stays on Postal Deep. District's full tax model is unchanged.

Weather minute rates use `precipitation_rate` / `precipitation_rate_in` in JSON
and `precipitationRate` / `precipitationRateIn` in this SDK (mm/hour and inches/hour).
Update old minute member reads. Decoders accept the earlier minute wire names
during rollout, with canonical presence and null taking priority; encoding uses
only canonical names. Historical `precipitation` / `precipitation_in` are amounts
and remain unchanged. Already installed older SDKs do not gain these reader fixes.

## API 2.1 upgrade

API 2.1 Time returns the clock first and the matched place in `location`. Read that place directly; `location.candidates` is for unresolved choices. Unused `resolution` is absent. City matches keep the match kind, text and language without the source category or spelling score. Holiday JSON keeps scope and completeness without calendar hashes; explicitly selected work-profile pins remain.

This client targets ParseAPI 2.1.0. Upgrading requires response-reader changes: optional detail now lives on its resource. Read `population` instead of `deep.population`. Deep remains an explicit request for optional detail. Without the request or access, optional fields are absent. A returned null still means unknown. User-Agent device, OS and browser are objects in every mode. Postal tax is one `tax` object. Specialist Weather measurements live in `current`. Metered Carrier and HLR return the complete purchased result without a Deep switch.

Use `try await parse.emailVerify(email)` for mailbox verification. It sends POST `/email/verify` with `{ "email": "person@example.com" }` and defaults to no automatic retries. The earlier Email deep argument is accepted only as a migration alias for that same operation. App keys receive `permission_denied`. Bulk exports retain their existing column names and saved-job recovery.

The 2.0 API is a temporary migration bridge for older installed clients. There is one maintained SDK line using the 2.1 structure.

## Upgrade to API 2.1

This version selects API `2.1.0`. Update existing `.deep` property reads to the fields at their natural homes, such as `country.population`. User-Agent identities are objects; Postal tax and Weather observations keep their documented object homes. Paid plans include their profile detail automatically in API 2.1. Free keeps its complete routine answer, and existing explicit `deep` options remain supported. Mailbox verification stays explicit.

**This minor version changes existing field reads.** Upgrade the SDK and your application reads together. Existing factories remain. Email verification is explicit and includes basic validation; Carrier/HLR need no extra detail request. Preserve missing values, `null`, `false` and `0`.
