import Foundation

/// Evidence for an explicitly matched City search result.
public struct CityMatch: Codable, Sendable {
    public let type: String
    public let source: String
    public let value: String
    public let language: String?
    public let editDistance: Int?
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
    public let district: String?
    public let districtName: String?
    public let type: String?
    public let grain: String?
    public let latitude: Double?
    public let longitude: Double?
    public let timezone: String?
    public let distance: Double?
    public let distanceMi: Double?
    public let parent: CityParent?
    public let deep: CityDeep?
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
