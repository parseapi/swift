import Foundation
import Testing
@testable import ParseAPI

private let directoryProfileJSON = #"{"id":"co_222222222222","name":"Example","country":"US","website":null,"listings":[{"exchange":"Future Exchange","symbol":"A/B"}],"address":null,"deep":{"legal_name":"Example Inc.","aliases":[],"jurisdiction":{"country":"US","state":null},"status":"future-status","websites":[{"domain":"example.com","url":null}],"identifiers":[{"type":"registration","authority":"future:registry","value":"0000123"}],"incorporated":null,"addresses":[{"type":"future-role","street":null,"city":"Example City","state":null,"postal":null,"country":"US"}],"industries":[{"type":"future-scheme","code":"001","name":null}],"parent":null,"description":null,"logo":null,"socials":[],"founded":{"value":"2006","precision":"year"},"sources":[{"type":"website","url":"https://example.com/","fields":["founded"],"observed_at":"2026-09-23T17:35:06.956Z","updated_at":null,"future":true}],"future":true},"future":true}"#
private let directorySearchJSON = #"{"companies":[{"id":"co_222222222222","name":"Example","country":"US","website":null,"listings":[{"exchange":"Future Exchange","symbol":"A/B"}],"address":null,"deep":{"legal_name":"Example Inc.","aliases":[],"jurisdiction":{"country":"US","state":null},"status":"future-status","websites":[{"domain":"example.com","url":null}],"identifiers":[{"type":"registration","authority":"future:registry","value":"0000123"}],"incorporated":null,"addresses":[{"type":"future-role","street":null,"city":"Example City","state":null,"postal":null,"country":"US"}],"industries":[{"type":"future-scheme","code":"001","name":null}],"parent":null,"description":null,"logo":null,"socials":[],"founded":{"value":"2006","precision":"year"},"sources":[{"type":"website","url":"https://example.com/","fields":["founded"],"observed_at":"2026-09-23T17:35:06.956Z","updated_at":null,"future":true}],"future":true},"future":true,"match":{"field":"future-field","value":"0000123","type":"future-scheme","authority":null,"exchange":null,"future":true}}],"next":"opaque+/="}"#
private let directoryCoverageJSON = #"{"scope":"sample","label":"Company directory","description":"Edition profiles","snapshot_at":"2026-09-23T17:35:06.956Z","companies":0,"countries":[],"with_website":0,"with_listings":0,"with_address":0,"future":true}"#

@Suite struct CompanyDirectoryTests {
 @Test func routesSelectorsAndResponseFields() async throws {
  let stub = StubTransport([(200,directoryProfileJSON,[:]),(200,directoryProfileJSON,[:]),(200,directorySearchJSON,[:]),(200,directorySearchJSON,[:]),(200,directorySearchJSON,[:]),(200,directorySearchJSON,[:]),(200,directoryCoverageJSON,[:])])
  let c = try makeClient(stub)
  let profile = try await c.companyId("co_/ ?",deep:true)
  #expect(profile.deep?.identifiers?.first?.value == "0000123")
  #expect(profile.deep?.status == "future-status" && profile.deep?.socials?.isEmpty == true)
  #expect(profile.deep?.founded?.precision == "year" && profile.deep?.sources?.first?.updatedAt == nil)
  #expect(profile.deep?.jurisdiction?.state == nil)
  _ = try await c.companyId("co_222222222222")
  let search = try await c.companySearch(query:"A & B",country:"US",limit:2,cursor:"opaque+/=",deep:true)
  #expect(search.next == "opaque+/=" && search.companies.first?.match.field == "future-field")
  #expect(search.companies.first?.deep?.legalName == "Example Inc.")
  _ = try await c.companySearch(domain:"https://sub.example.com/a?b=1")
  _ = try await c.companySearch(ticker:"A/B",exchange:"Future Exchange")
  _ = try await c.companySearch(identifier:"0000123",authority:"future:registry")
  let coverage = try await c.companyCoverage()
  #expect(coverage.companies == 0 && coverage.countries.isEmpty)
  let expected = [
   "/company/id/co_%2F%20%3F?deep=true", "/company/id/co_222222222222",
   "/company?q=A%20%26%20B&country=US&limit=2&cursor=opaque%2B%2F%3D&deep=true",
   "/company?domain=https%3A%2F%2Fsub.example.com%2Fa%3Fb%3D1",
   "/company?ticker=A%2FB&exchange=Future%20Exchange",
   "/company?identifier=0000123&authority=future%3Aregistry", "/company/directory/coverage"
  ]
  #expect(stub.requests.count == expected.count)
  for (request,path) in zip(stub.requests,expected) {
   #expect(request.url?.absoluteString == "https://api.parseapi.com"+path)
   #expect(request.value(forHTTPHeaderField:"Parse-Version") == "2.0.0")
  }
 }
 @Test func oldEmptyPartialAndFutureDeep() throws {
  let decoder=JSONDecoder();decoder.keyDecodingStrategy = .convertFromSnakeCase
  for suffix in ["", #","deep":{}"#, #","deep":{"legal_name":"Old name"}"#, #","deep":{"socials":null,"sources":null,"description":null,"employees":null}"#] {
   let value=try decoder.decode(CompanyProfile.self,from:Data((#"{"id":"co_222222222222","name":"Example","listings":[]"#+suffix+"}").utf8))
   #expect(value.deep?.socials == nil && value.deep?.sources == nil && value.deep?.founded == nil && value.deep?.employees == nil)
   if suffix.isEmpty { #expect(value.deep == nil) }
  }
  let value=try decoder.decode(CompanyProfile.self,from:Data(#"{"id":"co_222222222222","name":"Example","listings":[],"deep":{"socials":[],"sources":[],"founded":{"value":"spring 2006","precision":"season"}}}"#.utf8))
  #expect(value.deep?.socials?.isEmpty == true && value.deep?.sources?.isEmpty == true && value.deep?.founded?.precision == "season")
  let empty=try decoder.decode(CompanySearch.self,from:Data(#"{"companies":[],"next":null}"#.utf8))
  #expect(empty.companies.isEmpty && empty.next == nil)
 }
 @Test func serverValidatesSelectorCombinations() async throws {
  let stub=StubTransport(status:400,body:#"{"code":"invalid_request","message":"Choose one selector"}"#)
  do { _ = try await makeClient(stub).companySearch(query:"Example",domain:"example.com"); Issue.record("Expected server error") }
  catch let error as ParseAPIError { #expect(error.code == "invalid_request") }
  #expect(stub.requests.count == 1)
 }
 @Test func employeeObservationsPreserveZeroFalseDatesAndOpenCodes() async throws {
  let cases: [(String,Int,String,String,String,Bool)] = [
   (#"{"count":0,"as_of":"2025-12-31","scope":"legal_entity","method":"reported","approximate":false}"#,0,"2025-12-31","legal_entity","reported",false),
   (#"{"count":12500,"as_of":"2026-06-30","scope":"consolidated_group","method":"reported","approximate":true}"#,12500,"2026-06-30","consolidated_group","reported",true),
   (#"{"count":7,"as_of":"2026-01-15","scope":"future_scope","method":"future_method","approximate":false,"future":null}"#,7,"2026-01-15","future_scope","future_method",false)
  ]
  for (json,count,date,scope,method,approximate) in cases {
   let profileJSON = #"{"id":"co_222222222222","name":"Example","deep":{"employees":"# + json + "}}"
   let searchJSON = #"{"companies":["# + profileJSON.dropLast() + #","match":{"field":"name"}}],"next":null}"#
   let stub=StubTransport([(200,profileJSON,[:]),(200,searchJSON,[:])])
   let client=try makeClient(stub)
   let profile=try await client.companyId("co_222222222222",deep:true)
   let page=try await client.companySearch(query:"Example",deep:true)
   for optional in [profile.deep?.employees,page.companies.first?.deep?.employees] {
    let value=try #require(optional)
    #expect(value.count == count && value.asOf == date)
    #expect(value.scope == scope && value.method == method && value.approximate == approximate)
   }
  }
 }

 @Test func countryAndSICDiscoveryPreservesPreviousFunctionReference() async throws {
  let payload = #"{"companies":[],"next":null}"#
  let stub = StubTransport(Array(repeating:(200,payload,[:]),count:5))
  let client = try makeClient(stub)
  let previous: (String?,String?,String?,String?,String?,String?,String?,Int?,String?,Bool) async throws -> CompanySearch = client.companySearch
  _ = try await previous("Example",nil,nil,nil,"US",nil,nil,2,"old+/=",true)
  _ = try await client.companySearch(country:"US")
  _ = try await client.companySearch(industry:"0700",industryType:"sic")
  _ = try await client.companySearch(country:"US",limit:2,cursor:"opaque+/=",deep:true,industry:"0700",industryType:"sic")
  _ = try await client.companySearch(query:"Example",deep:false,industry:"0700",industryType:"sic")
  let expected = [
   ["q":"Example","country":"US","limit":"2","cursor":"old+/=","deep":"true"],
   ["country":"US"], ["industry":"0700","industry_type":"sic"],
   ["country":"US","limit":"2","cursor":"opaque+/=","deep":"true","industry":"0700","industry_type":"sic"],
   ["q":"Example","industry":"0700","industry_type":"sic"]
  ]
  for (request,wanted) in zip(stub.requests,expected) {
   let parts=URLComponents(url:try #require(request.url),resolvingAgainstBaseURL:false)
   #expect(parts?.path == "/company")
   let values=Dictionary(uniqueKeysWithValues:(parts?.queryItems ?? []).map {($0.name,$0.value ?? "")})
   #expect(values == wanted)
  }
 }

 @Test func registrationDiscoveryPreservesBothPriorFunctionReferencesAndExactStrings() async throws {
  let stub = StubTransport(Array(repeating:(200,#"{"companies":[],"next":null}"#,[:]),count:4))
  let client = try makeClient(stub)
  let previousIndustry: (String?,String?,String?,String?,String?,String?,String?,Int?,String?,Bool,String?,String?) async throws -> CompanySearch = client.companySearch
  _ = try await previousIndustry(nil,nil,nil,nil,"US",nil,nil,2,"old+/=",false,"0700","sic")
  _ = try await client.companySearch(registrationAuthority:"ra000599")
  _ = try await client.companySearch(country:"US",limit:2,cursor:"opaque+/=",deep:true,industry:"0700",industryType:"sic",registrationAuthority:"RA000599",registrationForm:"DPC",registrationStatus:" Good Standing ")
  _ = try await client.companySearch(identifier:"00001",authority:"SEC",registrationAuthority:"RA000599",registrationForm:"future/Form",registrationStatus:"future+& status")
  let expected = [
   ["country":"US","limit":"2","cursor":"old+/=","industry":"0700","industry_type":"sic"],
   ["registration_authority":"ra000599"],
   ["country":"US","limit":"2","cursor":"opaque+/=","deep":"true","industry":"0700","industry_type":"sic","registration_authority":"RA000599","registration_form":"DPC","registration_status":" Good Standing "],
   ["identifier":"00001","authority":"SEC","registration_authority":"RA000599","registration_form":"future/Form","registration_status":"future+& status"]
  ]
  #expect(stub.requests.count == expected.count)
  for (request,wanted) in zip(stub.requests,expected) {
   let parts=URLComponents(url:try #require(request.url),resolvingAgainstBaseURL:false)
   #expect(parts?.path == "/company")
   #expect(Dictionary(uniqueKeysWithValues:(parts?.queryItems ?? []).map {($0.name,$0.value ?? "")}) == wanted)
  }
 }

 @Test func registrationsPreserveRolesZerosNullsAndUnknownFields() async throws {
  let item = #"{"authority":"RA000599","number":"0001234567","jurisdiction":{"country":"US","state":"CO"},"role":"domestic","legal_form":{"code":"DNC","name":"Domestic Non-profit Corporation"},"status":"Good Standing","formation_date":"2004-02-29","address":{"kind":"principal","line1":"12 Main St.","line2":"Suite 2","city":"Example","state":"CO","postal":"00123-0001","country_raw":"US"},"future":"retained"}"#
  for deep in ["{}",#"{"registrations":null}"#,#"{"registrations":[]}"#,#"{"registrations":["# + item + "]}"] {
   let text = #"{"id":"co_222222222222","name":"Example","listings":[],"deep":"# + deep + "}"
   let pageText = #"{"companies":["# + text.dropLast() + #","match":{"field":"identifier"}}],"next":null}"#
   let stub=StubTransport([(200,text,[:]),(200,pageText,[:])]);let client=try makeClient(stub)
   let profile=try await client.companyId("co_222222222222",deep:true);let page=try await client.companySearch(identifier:"0001234567",authority:"RA000599",deep:true)
   for rows in [profile.deep?.registrations,page.companies.first?.deep?.registrations] {
    if let r=rows?.first {#expect(r.number == "0001234567" && r.jurisdiction.country == "US" && r.formationDate == "2004-02-29");#expect(r.address?.kind == "principal" && r.address?.postal == "00123-0001")}
    if deep == #"{"registrations":[]}"# {#expect(rows?.isEmpty == true)}
   }
  }
  let itemFuture=item.replacingOccurrences(of:"domestic",with:"future_role").replacingOccurrences(of:#""formation_date":"2004-02-29""#,with:#""formation_date":null"#)
  let decoder=JSONDecoder();decoder.keyDecodingStrategy = .convertFromSnakeCase
  let future=try decoder.decode(CompanyProfileRegistration.self,from:Data(itemFuture.utf8));#expect(future.role == "future_role" && future.formationDate == nil)
 }

}
