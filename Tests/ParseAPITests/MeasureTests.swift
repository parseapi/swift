import Foundation
import Testing
@testable import ParseAPI

@Suite struct MeasureTests {
 @Test func preservesPrecisionAndEncodesInput() async throws {
  let stub = StubTransport(body: #"{"measure":"5 ft 11 in","valid":true,"type":"future-type","amount":"180.34000000000000000001","unit":"cm","reason":null,"choices":[],"future":null}"#)
  let c = try makeClient(stub)
  let result = try await c.measure("5 ft 11 in", to: "cm", locale: "en-US", system: "us")
  #expect(result.amount == "180.34000000000000000001")
  #expect(result.type == "future-type")
  #expect(stub.requests[0].url!.absoluteString == "https://api.parseapi.com/measure/5%20ft%2011%20in?to=cm&locale=en-US&system=us")
  _ = try await c.measure("1 kg/m^3", to: "g/L")
  #expect(stub.requests[1].url!.absoluteString == "https://api.parseapi.com/measure/1%20kg%2Fm%5E3?to=g%2FL")
 }
 @Test func ambiguityAndDiscovery() async throws {
  let stub = StubTransport([
   (200, #"{"measure":"1 gallon","valid":false,"type":null,"amount":null,"unit":null,"reason":"ambiguous_unit","choices":[{"unit":"us_gal","name":"US liquid gallon"}]}"#, [:]),
   (200, #"{"units":[{"unit":"m","name":"metre","type":"length","aliases":["meter"],"future":true}]}"#, [:])
  ])
  let c = try makeClient(stub)
  let invalid = try await c.measure("1 gallon")
  #expect(!invalid.valid && invalid.amount == nil && invalid.type == nil)
  #expect(invalid.reason == "ambiguous_unit" && invalid.choices[0].unit == "us_gal")
  let catalog = try await c.measureUnits(query: "US gallon", type: "volume", unit: "L")
  #expect(catalog.units[0].aliases == ["meter"])
  #expect(stub.requests[1].url!.absoluteString == "https://api.parseapi.com/measure/units?q=US%20gallon&type=volume&unit=L")
  _ = try await c.measureUnits()
  #expect(stub.requests[2].url!.absoluteString == "https://api.parseapi.com/measure/units")
 }
 @Test func targetErrorsUseNormalAPIError() async throws {
  let stub = StubTransport(status: 400, body: #"{"code":"bad_request","message":"Incompatible units","request_id":"req_measure"}"#)
  do {
   _ = try await makeClient(stub).measure("1 m", to: "kg")
   Issue.record("Expected API error")
  } catch let error as ParseAPIError {
   #expect(error.code == "bad_request")
   #expect(stub.requests.count == 1)
  }
 }
}
