import Foundation
import Testing
@testable import ParseAPI

@Test func currentAndFrozenNetworkContractsDecode() throws {
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
        let scope: String = result.scope
        let pages: Int = result.pages
        #expect(scope == "" && pages == 0 && result.partial == nil)
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
    #expect(oldFields["scope"] as? String == "site" && oldFields["pages"] as? Int == 2 && oldFields["partial"] as? Bool == false)
    let roundtrip = try decoder.decode(Stack.self, from: oldEncoded)
    #expect(roundtrip.cms?.first?.technology == "wordpress" && roundtrip.frameworks?.isEmpty == true && roundtrip.analytics == nil)
    let domain = try read(Domain.self, "domain_unregistered")
    #expect(domain.available == true && domain.deep?.registration?.registered == false && domain.deep?.registration?.dnssec == nil)
}
