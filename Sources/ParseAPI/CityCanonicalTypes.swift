import Foundation

/// Evidence for an explicitly matched City search result.
public struct CityMatch: Codable, Sendable {
    public let type: String
    public let source: String
    public let value: String
    public let language: String?
    public let editDistance: Int?

    private enum CodingKeys: String, CodingKey { case type, source, value, language, editDistance }
    public init(from decoder: any Decoder) throws {
        let fields = try decoder.container(keyedBy: CodingKeys.self)
        type = try fields.decode(String.self, forKey: .type)
        source = try fields.decodeIfPresent(String.self, forKey: .source) ?? ""
        value = try fields.decode(String.self, forKey: .value)
        language = try fields.decodeIfPresent(String.self, forKey: .language)
        editDistance = try fields.decodeIfPresent(Int.self, forKey: .editDistance)
    }
    public func encode(to encoder: any Encoder) throws {
        var fields = encoder.container(keyedBy: CodingKeys.self)
        try fields.encode(type, forKey: .type)
        if !source.isEmpty { try fields.encode(source, forKey: .source) }
        try fields.encode(value, forKey: .value)
        try fields.encodeIfPresent(language, forKey: .language)
        try fields.encodeIfPresent(editDistance, forKey: .editDistance)
    }
}

/// Complete City Core facts. Unknown facts remain nil; requested detail is optional.
public struct CityResource: Codable, Sendable {
    public let nameRomanized: String?
    public let romanizationLanguage: String?
    public let match: CityMatch?
    public let id: String
    public let object: String
    public let name: String?
    public let nameLocal: String?
    public let country: String?
    public let countryName: String?
    public let state: String?
    public let stateName: String?
    public let county: String?
    public let countyName: String?
    public let type: String?
    public let grain: String?
    public let latitude: Double?
    public let longitude: Double?
    public let timezone: String?
    public let distance: Double?
    public let distanceMi: Double?
    public let parent: CityParent?
	public let capitalOf: String?
	public let elevation: Double?
	public let elevationFt: Double?
	public let population: Int?
	public let populationPeriod: String? = nil
	public let populationObservedOn: String?
	public let populationBasis: String?
	public let area: Double?
	public let landArea: Double?
	public let waterArea: Double?

    /// Legacy source spelling. The encoded response uses only county.
    public var district: String? { county }
    /// Legacy source spelling. The encoded response uses only countyName.
    public var districtName: String? { countyName }
    private enum CodingKeys: String, CodingKey { case nameRomanized, romanizationLanguage, match, id, object, name, nameLocal, country, countryName, state, stateName, county, countyName, type, grain, latitude, longitude, timezone, distance, distanceMi, parent, capitalOf, elevation, elevationFt, population, populationObservedOn, populationBasis, area, landArea, waterArea }
    public init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        nameRomanized = try values.decodeIfPresent(String.self, forKey: .nameRomanized)
        romanizationLanguage = try values.decodeIfPresent(String.self, forKey: .romanizationLanguage)
        match = try values.decodeIfPresent(CityMatch.self, forKey: .match)
        id = try values.decode(String.self, forKey: .id)
        object = try values.decode(String.self, forKey: .object)
        name = try values.decodeIfPresent(String.self, forKey: .name)
        nameLocal = try values.decodeIfPresent(String.self, forKey: .nameLocal)
        country = try values.decodeIfPresent(String.self, forKey: .country)
        countryName = try values.decodeIfPresent(String.self, forKey: .countryName)
        state = try values.decodeIfPresent(String.self, forKey: .state)
        stateName = try values.decodeIfPresent(String.self, forKey: .stateName)
        county = try decodeCountyWire(String.self, from: decoder, canonical: "county", legacy: "district")
        countyName = try decodeCountyWire(String.self, from: decoder, canonical: "countyName", legacy: "districtName")
        type = try values.decodeIfPresent(String.self, forKey: .type)
        grain = try values.decodeIfPresent(String.self, forKey: .grain)
        latitude = try values.decodeIfPresent(Double.self, forKey: .latitude)
        longitude = try values.decodeIfPresent(Double.self, forKey: .longitude)
        timezone = try values.decodeIfPresent(String.self, forKey: .timezone)
        distance = try values.decodeIfPresent(Double.self, forKey: .distance)
        distanceMi = try values.decodeIfPresent(Double.self, forKey: .distanceMi)
        parent = try values.decodeIfPresent(CityParent.self, forKey: .parent)
        capitalOf = try values.decodeIfPresent(String.self, forKey: .capitalOf)
        elevation = try values.decodeIfPresent(Double.self, forKey: .elevation)
        elevationFt = try values.decodeIfPresent(Double.self, forKey: .elevationFt)
        population = try values.decodeIfPresent(Int.self, forKey: .population)
        populationObservedOn = try values.decodeIfPresent(String.self, forKey: .populationObservedOn)
        populationBasis = try values.decodeIfPresent(String.self, forKey: .populationBasis)
        area = try values.decodeIfPresent(Double.self, forKey: .area)
        landArea = try values.decodeIfPresent(Double.self, forKey: .landArea)
        waterArea = try values.decodeIfPresent(Double.self, forKey: .waterArea)
    }
}

/// Safe bounded identities on HTTP409 ambiguous_city; no Deep fields.
public struct CityAmbiguityCandidate: Codable, Sendable {
    public let id: String
    public let object: String
    public let name: String?
    public let nameLocal: String?
    public let country: String?
    public let countryName: String?
    public let state: String?
    public let stateName: String?
    public let type: String?
}

/// Reviewed relationships only. Empty data does not prove no relatives exist.
public struct CityRelations: Codable, Sendable {
    public let object: String
    public let data: [CityResource]
    public let hasMore: Bool?
    public let url: String?
    public let nextCursor: String?
    public let cityId: String
    public let relationship: String
    public let coverage: String
    public let parentId: String?
}

public struct CityDistance: Codable, Sendable {
    public let object: String
    public let from: String
    public let to: String
    public let distance: Double?
    public let distanceMi: Double?
    public let method: String
}

public struct CityRelationsOptions: Sendable {
    public let limit: Int?
    public let cursor: String?
    public let romanized: Bool
    public let hierarchy: Bool
    public let deep: Bool
    public let lang: String?
    public init(limit: Int? = nil, cursor: String? = nil, hierarchy: Bool = false, deep: Bool = false, lang: String? = nil, romanized: Bool = false) {
        self.limit = limit; self.cursor = cursor
        self.hierarchy = hierarchy; self.deep = deep; self.lang = lang; self.romanized = romanized
    }
}

public struct CityAncestorsOptions: Sendable {
    public let romanized: Bool
    public let hierarchy: Bool
    public let deep: Bool
    public let lang: String?
    public init(hierarchy: Bool = false, deep: Bool = false, lang: String? = nil, romanized: Bool = false) {
        self.hierarchy = hierarchy; self.deep = deep; self.lang = lang; self.romanized = romanized
    }
}
