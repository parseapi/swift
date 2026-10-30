import Foundation
import Testing
@testable import ParseAPI

@Test func currentAndFrozenNetworkContractsDecode() async throws {
    let url = URL(fileURLWithPath: #filePath).deletingLastPathComponent().appendingPathComponent("Fixtures/NetworkContracts.json")
    let objects = try JSONSerialization.jsonObject(with: Data(contentsOf: url)) as! [String: Any]
    let decoder = JSONDecoder(); decoder.keyDecodingStrategy = .convertFromSnakeCase
    func read<T: Decodable>(_ type: T.Type, _ key: String) throws -> T {
        try decoder.decode(type, from: JSONSerialization.data(withJSONObject: objects[key]!))
    }
    for name in ["ip_current", "ip_frozen", "ip_locked"] {
        let deep = try read(IP.self, name).deep!
        if name == "ip_current" {
            #expect(deep.district == "27053" && deep.districtName == "Hennepin County")
            #expect(deep.censusDivision == "West North Central" && deep.censusRegion == "Midwest")
        } else { #expect(deep.district == nil && deep.censusRegion == nil) }
    }
    let encoder = JSONEncoder(); encoder.keyEncodingStrategy = .convertToSnakeCase
    for name in ["stack_success", "stack_unavailable", "stack_empty"] {
        let result = try read(Stack.self, name)
        if name == "stack_unavailable" { #expect(result.cms == nil && result.checkedAt == nil) }
        else { #expect(result.cms != nil && result.frameworks != nil) }
        let encoded = try JSONSerialization.jsonObject(with: encoder.encode(result)) as! [String: Any]
        #expect(encoded["scope"] == nil && encoded["pages"] == nil && encoded["partial"] == nil)
    }
    var oldBody = objects["stack_success"] as! [String: Any]
    oldBody["scope"] = "site"; oldBody["pages"] = 2; oldBody["partial"] = false
    oldBody["analytics"] = NSNull()
    let oldResult = try decoder.decode(Stack.self, from: JSONSerialization.data(withJSONObject: oldBody))
    let oldEncoded = try encoder.encode(oldResult)
    let oldFields = try JSONSerialization.jsonObject(with: oldEncoded) as! [String: Any]
    #expect(oldFields["scope"] == nil && oldFields["pages"] == nil && oldFields["partial"] == nil)
    let roundtrip = try decoder.decode(Stack.self, from: oldEncoded)
    #expect(roundtrip.cms?.first?.technology == "wordpress" && roundtrip.frameworks?.isEmpty == true && roundtrip.analytics == nil)
    let stateStub = StubTransport(body: String(data: try JSONSerialization.data(withJSONObject: objects["state_current"]!), encoding: .utf8)!)
    let state = try await makeClient(stateStub).state("CA", country: "US")
    #expect(state.timezones == ["America/Los_Angeles"])
    #expect(stateStub.requests.count == 1)
    #expect(stateStub.requests[0].url!.absoluteString.hasSuffix("/state/CA?country=US"))
    let districtStub = StubTransport(body: String(data: try JSONSerialization.data(withJSONObject: objects["district_current"]!), encoding: .utf8)!)
    let district = try await makeClient(districtStub).district("36061", country: "US", state: "NY")
    #expect(district.timezones == ["America/New_York"])
    #expect(districtStub.requests.count == 1)
    #expect(districtStub.requests[0].url!.absoluteString.hasSuffix("/district/36061?country=US&state=NY"))
    let domain = try read(Domain.self, "domain_unregistered")
    #expect(domain.available == true && domain.deep?.registration?.registered == false && domain.deep?.registration?.dnssec == nil)
}
