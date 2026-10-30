import Foundation
import Testing
@testable import ParseAPI

@Suite struct CurrentStackWireTests {
 @Test func capturedCurrentWireUsesOneRequest() async throws {
  let path=URL(fileURLWithPath:#filePath).deletingLastPathComponent().appendingPathComponent("Fixtures/current-stack.json")
  let body=try String(contentsOf:path,encoding:.utf8)
  let stub=StubTransport(body:body)
  let client=try makeClient(stub)
  let result=try await client.stack("stripe.com",pretty:true)
  #expect(stub.requests.count==1)
  #expect(stub.requests[0].url!.absoluteString=="https://api.parseapi.com/stack/stripe.com?pretty=true")
  #expect(result.checkedAt != nil && result.cms?.isEmpty==true && result.servers?.count==1)
  let encoded=try JSONEncoder().encode(result)
  let fields=try #require(JSONSerialization.jsonObject(with:encoded) as? [String:Any])
  #expect(fields["scope"]==nil && fields["pages"]==nil && fields["partial"]==nil)
 }
}
