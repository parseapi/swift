import Foundation
import Testing
@testable import ParseAPI

@Suite struct PointModelCompatibility {
	@Test func pointElectoralAndTerrainAreAvailableWithoutAnotherRequest() async throws {
		let stub = StubTransport(body: #"{"latitude":39.1,"longitude":-104.1,"country":"US","elevation":-5,"elevation_ft":-16.4,"city":null,"electoral":{"code":"0801","name":null,"congress":119}}"#)
		let point = try await makeClient(stub).point(39.1, -104.1, deep: true)
 #expect(point.electoral?.code == "0801")
 #expect(point.electoral?.name == nil)
 #expect(point.electoral?.congress == 119)
 #expect(point.elevation == -5)
 #expect(stub.requests.count == 1)
	}


	@Test func pointElectoralUnknownAndSparseMetadataRemainNullable() throws {
		let decoder = JSONDecoder()
		decoder.keyDecodingStrategy = .convertFromSnakeCase
		for body in [#"{}"#, #"{"electoral":null}"#, #"{"elevation":0}"#] {
			let deep = try decoder.decode(PointDeep.self, from: Data(body.utf8))
 #expect(deep.electoral == nil)
		}
		let sparse = try decoder.decode(PointDeep.self, from: Data(#"{"electoral":{"code":"0000","name":null,"congress":null}}"#.utf8))
 #expect(sparse.electoral?.code == "0000")
 #expect(sparse.electoral?.name == nil && sparse.electoral?.congress == nil)
	}

}
