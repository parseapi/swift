import Foundation

/// An address with its recorded role; role does not imply mailing validity or headquarters.
public struct CompanyProfileAddress: Codable, Sendable {
	public let type: String
	public let street: String?
	public let city: String?
	public let state: String?
	public let postal: String?
	public let country: String?
}

/// A reported exchange/symbol pair. No listings does not establish private ownership.
public struct CompanyProfileListing: Codable, Sendable {
	public let exchange: String
	public let symbol: String
}

/// Recorded registration jurisdiction, separate from address or operating location.
public struct CompanyProfileJurisdiction: Codable, Sendable {
	public let country: String
	public let state: String?
}

/// Another associated hostname and its recorded URL, when known.
public struct CompanyProfileWebsite: Codable, Sendable {
	public let domain: String
	public let url: String?
}

/// An authority-scoped identifier; values preserve leading zeros.
public struct CompanyProfileIdentifier: Codable, Sendable {
	public let type: String
	public let authority: String
	public let value: String
}

/// A reported classification; type is an open scheme string.
public struct CompanyProfileIndustry: Codable, Sendable {
	public let type: String
	public let code: String
	public let name: String?
}

/// Reported founding value and precision (year, month or day), distinct from incorporation.
public struct CompanyProfileFounding: Codable, Sendable {
	public let value: String
	/// Open string; currently year, month or day. Preserve the source value without padding.
	public let precision: String
}

/// Reported total headcount at its explicit measurement date.
public struct CompanyProfileEmployees: Codable, Sendable {
	public let count: Int
	public let asOf: String
	/// Open string, currently legal_entity or consolidated_group.
	public let scope: String
	/// Open string, currently reported.
	public let method: String
	public let approximate: Bool
}

/// Legal form recorded by a register; codes remain open strings.
public struct CompanyProfileRegistrationLegalForm: Codable, Sendable {
	public let code: String
	public let name: String
}

/// Recorded principal-address components, not inferred ISO codes or headquarters.
public struct CompanyProfileRegistrationAddress: Codable, Sendable {
	public let kind: String
	public let line1: String?
	public let line2: String?
	public let city: String?
	public let state: String?
	public let postal: String?
	public let countryRaw: String?
}

/// Registry-scoped legal facts, not an operation or tax-exemption verdict.
public struct CompanyProfileRegistration: Codable, Sendable {
	public let authority: String
	public let number: String
	public let jurisdiction: CompanyProfileJurisdiction
	public let role: String
	public let legalForm: CompanyProfileRegistrationLegalForm
	public let status: String
	/// This register's reported entity-form date, not universal incorporation or founding.
	public let formationDate: String?
	public let address: CompanyProfileRegistrationAddress?
}

/// Attribution only for the named selected enrichment fields; observation is not a source update.
public struct CompanyProfileSource: Codable, Sendable {
	public let type: String
	public let url: String
	public let fields: [String]
	/// Artifact observation timestamp.
	public let observedAt: String
	/// Explicit source update timestamp, or null. Measurement dates belong to employees.as_of.
	public let updatedAt: String?
}

/// Optional directory detail. Every member may be missing or null; existing releases may omit enrichment fields.
public struct CompanyProfileDeep: Codable, Sendable {
	public let legalName: String?
	public let aliases: [String]?
	public let jurisdiction: CompanyProfileJurisdiction?
	/// Recorded legal status; not an operating or compliance verdict.
	public let status: String?
	public let websites: [CompanyProfileWebsite]?
	public let identifiers: [CompanyProfileIdentifier]?
	public let incorporated: String?
	public let addresses: [CompanyProfileAddress]?
	public let industries: [CompanyProfileIndustry]?
	public let parent: String?
	public let description: String?
	/// Reported asset URL; the client does not fetch or license the asset.
	public let logo: String?
	/// Selected company account URLs; an empty array does not prove no accounts exist.
	public let socials: [String]?
	public let founded: CompanyProfileFounding?
	public let employees: CompanyProfileEmployees?
	public let registrations: [CompanyProfileRegistration]?
	/// Attribution for projected enrichment fields only, not the entire legal profile.
	public let sources: [CompanyProfileSource]?
}

/// Search match evidence. Open strings permit future fields and identifier/listing namespaces.
public struct CompanyMatch: Codable, Sendable {
	public let field: String?
	public let value: String?
	public let type: String?
	public let authority: String?
	public let exchange: String?
}

/// A directory profile, distinct from national company-number validation.
public struct CompanyProfile: Codable, Sendable {
	public let id: String
	public let name: String
	public let country: String?
	public let website: String?
	public let listings: [CompanyProfileListing]
	public let address: CompanyProfileAddress?
	public let deep: CompanyProfileDeep?
}

/// A directory search profile with match evidence; a match is not proof of legal identity.
public struct CompanyCandidate: Codable, Sendable {
	public let id: String
	public let name: String
	public let country: String?
	public let website: String?
	public let listings: [CompanyProfileListing]
	public let address: CompanyProfileAddress?
	public let deep: CompanyProfileDeep?
	public let match: CompanyMatch
}

/// One page of company candidates. Reuse next with the same selector, filters and limit.
public struct CompanySearch: Codable, Sendable {
	public let companies: [CompanyCandidate]
	public let next: String?
}

/// Counts for this directory edition, not complete country or worldwide coverage.
public struct CompanyCoverage: Codable, Sendable {
	public let scope: String
	public let label: String
	public let description: String
	public let snapshotAt: String
	public let companies: Int
	public let countries: [String]
	public let withWebsite: Int
	public let withListings: Int
	public let withAddress: Int
}
