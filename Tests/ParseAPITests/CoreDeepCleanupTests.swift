import Foundation
import Testing
@testable import ParseAPI
struct CoreDeepCleanupTests {
 private struct Responses:Decodable{let language:Language;let state:State;let postal:Postal}
 @Test func reviewedCoreDeepResponsesDecode()throws{
 let decoder=JSONDecoder();decoder.keyDecodingStrategy = .convertFromSnakeCase
 let data=try decoder.decode(Responses.self,from:Data(#"{"language":{"language":"hr","name":"Croatian","name_local":"hrvatski","script":"Latn","direction":"ltr","countries":["BA","HR"],"iso_alpha3":"hrv"},"state":{"state":"CA","name":"California","name_local":null,"type":"state","country":"US","country_name":"United States","latitude":36.701463,"longitude":-118.755997,"timezones":["America/Los_Angeles"],"fips":"06","area_codes":["209","213","279","310","323","341","408","415","424","442","510","530","559","562","619","626","628","650","657","661","669","707","714","747","760","805","818","820","831","840","858","909","916","925","949","951"],"capital":{"name":"Sacramento","latitude":null,"longitude":null},"population":39431263,"area":423970,"tax":{"name":"Sales tax","rate":7.25},"iso_subdivision":"US-CA"},"postal":{"postal":"10001","city":"New York","city_local":null,"district":"36061","district_name":"New York","district_name_local":null,"state":"NY","state_name":"New York","state_name_local":null,"country":"US","country_name":"United States","latitude":40.750649,"longitude":-73.997298,"timezone":"America/New_York","type":"standard","localities":null,"elevation":20,"elevation_ft":66,"population":30511,"area":1.62,"land_area":1.62,"water_area":0,"tax":{"name":"Sales tax","rate":8.875,"rate_state":4,"rate_county":null,"rate_city":4.5,"rate_special":0.375},"property_tax":null,"metros":[{"code":"35620","name":"New York-Newark-Jersey City, NY-NJ","type":"metropolitan","share_percent":100}],"currency":"USD","neighbors":["10199","10119","10018","10011","10036","10110","10173","10165"]}}"#.utf8))
 #expect(data.state.fips=="06" && data.state.iso=="US-CA" && data.state.capital?.name=="Sacramento" && data.state.capital?.latitude==nil)
 #expect(data.state.tax?.rate==7.25)
 #expect(data.postal.tax?.rate==8.875 && data.postal.tax?.rateCounty==nil)
 #expect(data.postal.waterArea==0 && data.postal.currency=="USD" && data.postal.neighbors?.count==8)
 #expect(data.language.iso3=="hrv" && data.language.countries?.count==2 && data.language.iso3 != nil)
 }
}
