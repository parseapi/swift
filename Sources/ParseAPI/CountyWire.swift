import Foundation

private struct CountyWireKey: CodingKey {
 let stringValue: String
 let intValue: Int? = nil
 init(_ value:String) {stringValue=value}
 init?(stringValue:String){self.init(stringValue)}
 init?(intValue:Int){return nil}
}

// The configured JSONDecoder transforms snake_case keys before this reader sees them.
func decodeCountyWire<T: Decodable>(_ type:T.Type, from decoder:any Decoder, canonical:String, legacy:String) throws -> T? {
 let values=try decoder.container(keyedBy:CountyWireKey.self)
 let current=CountyWireKey(canonical)
 return try values.contains(current) ? values.decodeIfPresent(type,forKey:current) : values.decodeIfPresent(type,forKey:CountyWireKey(legacy))
}
