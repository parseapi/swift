import Foundation
import Testing
@testable import ParseAPI
@Test func coreConnectorDecodingPreservesDeepAndOlderResponses() throws {
 let url=URL(fileURLWithPath:#filePath).deletingLastPathComponent().appendingPathComponent("Fixtures/CoreConnectors.json")
 let objects=try JSONSerialization.jsonObject(with:Data(contentsOf:url)) as! [String:Any]
 let decoder=JSONDecoder();decoder.keyDecodingStrategy = .convertFromSnakeCase
 func read<T:Decodable>(_ type:T.Type,_ key:String)throws->T {try decoder.decode(type,from:JSONSerialization.data(withJSONObject:objects[key]!))}
 let c=try read(Country.self,"country");#expect(c.iso3=="USA"&&c.capitalLat==0&&c.borders==["CA","MX"])
 let l=try read(Language.self,"language");#expect(l.iso3=="eng"&&l.countries==["GB","US"])
 let u=try read(Currency.self,"currency");#expect(u.countries==["US"])
 let p=try read(Postal.self,"postal");#expect(p.currency=="USD"&&p.postal=="00501")
 let point=try read(Point.self,"point");#expect(point.city?.id=="city_7aj899nvwyku")
 #expect(p.country=="US"&&p.neighbors==["00544"]&&p.currency != nil)
 var oldPoint=objects["point"] as! [String:Any];oldPoint["city_id"]="unpublished-alias"
 #expect(try decoder.decode(Point.self,from:JSONSerialization.data(withJSONObject:oldPoint)).city?.id=="city_7aj899nvwyku")
 var oldPostal=objects["postal"] as! [String:Any];oldPostal.removeValue(forKey:"neighbors")
 #expect(try decoder.decode(PostalDeep.self,from:JSONSerialization.data(withJSONObject:oldPostal)).neighbors==nil)
 oldPostal["neighbors"]=NSNull();#expect(try decoder.decode(PostalDeep.self,from:JSONSerialization.data(withJSONObject:oldPostal)).neighbors==nil)
 oldPostal["neighbors"]=[] as [String];#expect(try decoder.decode(PostalDeep.self,from:JSONSerialization.data(withJSONObject:oldPostal)).neighbors==[])
 let n=try read(Industry.self,"industry");#expect(n.children?.first?.naics=="111")
 let search=try read(NAICSSearch.self,"industry_search");#expect(search.results.first?.naics=="722515"&&search.results.first?.match?.text=="Coffee shops, on premise brewing")
 let e=try read(Emoji.self,"emoji");#expect(e.base=="👍"&&e.variants?.first?.emoji=="👍🏽")
 let co=try read(CompanyProfile.self,"company");#expect(co.identifiers?.first?.value=="0000320193"&&co.phoneNumbers?.first?.country=="US"&&co.phoneNumbers?.first?.e164=="+14089961010")
 var old=objects["country"] as! [String:Any];for key in ["iso_alpha3","borders","capital"]{old.removeValue(forKey:key)}
 let older=try decoder.decode(Country.self,from:JSONSerialization.data(withJSONObject:old));#expect(older.iso3==nil&&older.borders==nil)
 var unknown=objects["language"] as! [String:Any];unknown["countries"]=NSNull()
 #expect(try decoder.decode(Language.self,from:JSONSerialization.data(withJSONObject:unknown)).countries==nil)
 unknown["countries"]=[] as [String]
 #expect(try decoder.decode(Language.self,from:JSONSerialization.data(withJSONObject:unknown)).countries==[])
}
