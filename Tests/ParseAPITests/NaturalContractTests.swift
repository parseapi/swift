import Foundation
import Testing
@testable import ParseAPI
@Suite struct NaturalContract {
 @Test func approvedPayloadsDecodeAtNaturalHomes() throws {
  let url=URL(fileURLWithPath:#filePath).deletingLastPathComponent().appendingPathComponent("Fixtures/approved-2.1.json")
  let rows=try JSONSerialization.jsonObject(with:Data(contentsOf:url)) as! [[String:Any]]
  let decoder=JSONDecoder();decoder.keyDecodingStrategy = .convertFromSnakeCase
  let encoder=JSONEncoder();encoder.keyEncodingStrategy = .convertToSnakeCase
  func field(_ value:Any,_ path:String)->Any? {var item:Any?=value;for key in path.split(separator:"."){item=(item as? [String:Any])?[String(key)]};return item is NSNull ? nil : item}
  for row in rows {
   let body=row["body"] as! [String:Any];let data=try JSONSerialization.data(withJSONObject:body)
   let encoded:Data
   switch row["product"] as! String {
case "ip": encoded=try encoder.encode(decoder.decode(IP.self,from:data))
case "country": encoded=try encoder.encode(decoder.decode(Country.self,from:data))
case "state": encoded=try encoder.encode(decoder.decode(State.self,from:data))
case "postal": encoded=try encoder.encode(decoder.decode(Postal.self,from:data))
case "email": encoded=try encoder.encode(decoder.decode(Email.self,from:data))
case "carrier": encoded=try encoder.encode(decoder.decode(Carrier.self,from:data))
case "hlr": encoded=try encoder.encode(decoder.decode(HLR.self,from:data))
case "useragent": encoded=try encoder.encode(decoder.decode(Useragent.self,from:data))
case "weather": encoded=try encoder.encode(decoder.decode(Weather.self,from:data))
default:throw CocoaError(.coderReadCorrupt)
   }
   let actual=try JSONSerialization.jsonObject(with:encoded) as! [String:Any]
   #expect(actual["deep"] == nil)
   for key in row["fields"] as! [String] {
    let want=field(body,key),got=field(actual,key)
    if want==nil { #expect(got==nil) } else { #expect((got as? NSObject)?.isEqual(want)==true,Comment(rawValue:"\(row["id"]!):\(key)")) }
   }
  }
 }
}

@Test func emailVerificationIsExplicitPostAndDoesNotAutomaticallyRetry() async throws {
 let stub=StubTransport(body:#"{"email":"a+tag@example.com","valid":true,"free":false,"disposable":false,"role":false,"deliverable":false,"catchall":null}"#)
 let client=try ParseAPI("fixture",baseURL:"https://api.parseapi.com",transport:stub.transport)
 let result=try await client.emailVerify("a+tag@example.com")
 #expect(result.deliverable==false && result.catchall==nil)
 #expect(stub.requests[0].httpMethod=="POST" && stub.requests[0].url?.path=="/email/verify")
 let body=try #require(stub.requests[0].httpBody)
 #expect(try JSONSerialization.jsonObject(with:body) as? [String:String] == ["email":"a+tag@example.com"])
 let failure=StubTransport([(503,#"{"code":"service_unavailable","message":"pending"}"#,[:]),(503,"{}",[:]),(503,"{}",[:])])
 let failing=try ParseAPI("fixture",baseURL:"https://api.parseapi.com",transport:failure.transport)
 do { _ = try await failing.emailVerify("a@example.com"); Issue.record("Expected a service error") } catch { }
 #expect(failure.requests.count==1)
}
