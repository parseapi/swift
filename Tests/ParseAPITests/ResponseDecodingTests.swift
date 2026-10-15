import Foundation
import Testing
@testable import ParseAPI

private let responseFixtureRoot = URL(fileURLWithPath: #filePath).deletingLastPathComponent().appendingPathComponent("Fixtures/ResponseFixtures").path
private func responseBody(_ profile: String, _ name: String) throws -> Data { try Data(contentsOf: URL(fileURLWithPath: "\(responseFixtureRoot)/\(profile)-\(name).json")) }
private actor ResponseRecorder {
 var requests: [URLRequest] = []
 func add(_ request: URLRequest) { requests.append(request) }
 func all() -> [URLRequest] { requests }
}
@Test func responseDecodingKeepsPublishedConsumers() async throws {
  let decoder = JSONDecoder(); decoder.keyDecodingStrategy = .convertFromSnakeCase
  let profiles = ["standard", "clean"]
  for profile in profiles {
   let zones = try decoder.decode(TimeZones.self, from: responseBody(profile, "timezones"))
   let time = try decoder.decode(Timezone.self, from: responseBody(profile, "time"))
   let tariff = try decoder.decode(Tariff.self, from: responseBody(profile, "tariff"))
   let search = try decoder.decode(TariffSearch.self, from: responseBody(profile, "tariff-search"))
   let metadata = try decoder.decode(EmojiMetadata.self, from: responseBody(profile, "emoji-metadata"))
   let catalog = try decoder.decode(EmojiCatalog.self, from: responseBody(profile, "emoji-catalog"))
   let coverage = try decoder.decode(CompanyCoverage.self, from: responseBody(profile, "company-coverage"))
   let company = try decoder.decode(CompanyProfile.self, from: responseBody(profile, "company-profile"))
   precondition(!zones.timezones.isEmpty && time.unix == 1791907200)
   precondition(time.location?.candidates.first?.country == "US")
   precondition(tariff.hts == "0101.21.00.10" && !search.lines.isEmpty)
   precondition(!metadata.notices.isEmpty && !catalog.emojis.isEmpty)
   precondition(coverage.companies == 1 && company.deep?.employees?.count == 12)
   precondition(company.deep?.employees?.approximate == false)
   precondition(company.deep?.employees?.method == (profile == "standard" ? "reported" : ""))
   if profile == "standard" {
    precondition(!zones.timezoneDatabaseVersion.isEmpty && !tariff.revision.isEmpty && !search.revision.isEmpty)
    precondition(!metadata.sourceVersion.isEmpty && !coverage.snapshotAt.isEmpty)
   } else {
    precondition(zones.timezoneDatabaseVersion.isEmpty && tariff.revision.isEmpty && search.revision.isEmpty)
    precondition(metadata.sourceVersion.isEmpty && coverage.snapshotAt.isEmpty)
    precondition(time.location?.candidates.first?.id == nil && time.location?.candidates.first?.timezone == nil)
    precondition(time.location?.source == "")
   }
   print("\(profile): 8 actual-handler payloads decoded; facts, nulls, false and old getters preserved")
  }
  var malformed = try JSONSerialization.jsonObject(with: responseBody("standard", "timezones")) as! [String: Any]
  malformed["timezone_database_version"] = NSNull()
  do { _ = try decoder.decode(TimeZones.self, from: JSONSerialization.data(withJSONObject: malformed)); preconditionFailure("Explicit null metadata must fail") } catch DecodingError.valueNotFound { }
  let calls = ResponseRecorder(), standard = try responseBody("standard", "timezones")
  let transport: ParseAPITransport = { request in
   await calls.add(request)
   return (standard, HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: [:])!)
  }
  let oldCall = try ParseAPI("fixture", retries: 0, transport: transport)
  _ = try await oldCall.timeZones()
  let explicitTimeout = try ParseAPI("fixture", timeout: 10, retries: 0, transport: transport)
  _ = try await explicitTimeout.timeZones()
  for request in await calls.all() {
   precondition(request.value(forHTTPHeaderField: "Parse-Response") == nil)
   precondition(request.value(forHTTPHeaderField: "Parse-Version") == "2.0.0")
  }
  print("Existing initializer/call signatures compile; default requests omit response preference")
  let cleanCalls = ResponseRecorder(), clean = try responseBody("clean", "timezones")
  let cleanTransport: ParseAPITransport = { request in
   await cleanCalls.add(request)
   return (clean, HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: [:])!)
  }
  _ = try await ParseAPI("fixture", retries: 0, transport: cleanTransport).timeZones()
  let sent = await cleanCalls.all()
  precondition(sent.count == 1 && sent[0].value(forHTTPHeaderField: "Parse-Response") == nil)
  print("Ordinary published initializer decodes the cleaned response without configuration")
 }
