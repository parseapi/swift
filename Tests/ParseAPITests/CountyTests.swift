import Foundation
import Testing
@testable import ParseAPI

@Test func countyRoutesAndHistoricalReaders() async throws {
 let stub=StubTransport(body: #"{"county":"08031","name":"Denver County","country":"US","type":"county","timezones":["America/Denver"],"population":0}"#)
 let county=try await makeClient(stub).county("Denver County",country:"US",state:"CO",deep:true)
 #expect(county.county=="08031" && county.district=="08031" && county.population==0)
 #expect(stub.requests.count==1)
 #expect(stub.requests[0].url!.absoluteString.hasSuffix("/county/Denver%20County?country=US&state=CO&deep=true"))
 #expect(stub.requests[0].value(forHTTPHeaderField:"X-API-Version")=="2.2.0")
 let listStub=StubTransport(body: #"{"state":"CO","country":"US","counties":[{"county":"08031","name":"Denver County","population":0}]}"#)
 let list=try await makeClient(listStub).stateCounties("CO",country:"US")
 #expect(list.counties.first?.county=="08031" && list.districts.first?.district=="08031")
 #expect(listStub.requests[0].url!.absoluteString.hasSuffix("/state/CO/counties?country=US"))
 let decoder=JSONDecoder();decoder.keyDecodingStrategy = .convertFromSnakeCase
 let old=try decoder.decode(County.self,from:Data(#"{"district":"75","name":"Paris","country":"FR","type":"department"}"#.utf8))
 #expect(old.county=="75" && old.type=="department")
 let postal=try decoder.decode(Postal.self,from:Data(#"{"postal":"08001","country":"US","district":"08031","district_name":"Denver","district_name_local":null}"#.utf8))
 #expect(postal.county=="08031" && postal.districtName=="Denver" && postal.countyNameLocal==nil)
 let ip=try decoder.decode(IP.self,from:Data(#"{"ip":"8.8.8.8","county":null,"district":"bad","county_name":null,"district_name":"bad"}"#.utf8))
 #expect(ip.county==nil && ip.district==nil && ip.countyName==nil)
 let encoder=JSONEncoder();encoder.keyEncodingStrategy = .convertToSnakeCase
 let fields=try JSONSerialization.jsonObject(with:encoder.encode(postal)) as! [String:Any]
 #expect(fields["county"] as? String == "08031" && fields["district"]==nil)
}
