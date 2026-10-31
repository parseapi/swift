import Foundation
import Testing
@testable import ParseAPI
@Test func currencyRestorationPreservesUnknownZeroAndServerPrecision() throws {
 let url=URL(fileURLWithPath:#filePath).deletingLastPathComponent().appendingPathComponent("Fixtures/CurrencyCompatibility.json")
 let rows=try JSONSerialization.jsonObject(with:Data(contentsOf:url)) as! [String:Any]
 let codec=JSONDecoder();codec.keyDecodingStrategy = .convertFromSnakeCase
 func get<T:Decodable>(_ name:String,_ type:T.Type)throws->T{try codec.decode(type,from:JSONSerialization.data(withJSONObject:rows[name]!))}
 let p=try get("profile",Currency.self);#expect(p.digits==0);#expect(p.symbol==nil);#expect(p.countries==["JP"])
 for name in ["locked","nulls"]{let p=try get(name,Currency.self);#expect(p.deep != nil);#expect(p.isoNumeric==nil);#expect(p.namePlural==nil);#expect(p.countries==nil)}
 let r=try get("rate",CurrencyRate.self);#expect(r.rate==158.33550065);#expect(r.amount==1.005);#expect(r.converted==1)
 let z=try get("zero",CurrencyRate.self);#expect(z.rate==0);#expect(z.amount==0);#expect(z.converted==0)
}
