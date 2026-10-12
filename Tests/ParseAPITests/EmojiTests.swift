import Foundation
import Testing
@testable import ParseAPI

@Suite struct EmojiCatalogTests {
	@Test func actualArtwork() async throws {
		let path = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("Fixtures/emoji-artwork.json")
		let fixture = try #require(JSONSerialization.jsonObject(with: Data(contentsOf:path)) as? [String:Any])
		let metadataText = String(decoding: try JSONSerialization.data(withJSONObject:#require(fixture["metadata"])), as:UTF8.self)
		let emojiText = String(decoding: try JSONSerialization.data(withJSONObject:#require(fixture["emoji"])), as:UTF8.self)
		let metadata = try await makeClient(StubTransport(body:metadataText)).emojiMetadata()
		let artwork = try #require(try await makeClient(StubTransport(body:emojiText)).emoji("🔥",deep:true).deep?.artwork)
		#expect(metadata.artworkSources.count == 3 && artwork.count == 3)
		#expect(metadata.artworkSources[0].notices.isEmpty == false)
		#expect(artwork["openmoji"]?.svg == "https://cdn.parseapi.com/emoji/openmoji/17.0.0/1f680.svg")
		#expect(artwork["openmoji"]?.png?["72"] == "https://cdn.parseapi.com/emoji/openmoji/17.0.0/72/1f680.png")
	}

	@Test func catalogFiltersAndPrivateTextBody() async throws {
		let stub = StubTransport(body: #"{"q":"","emojis":[],"total":0,"next_offset":null}"#)
		let client = try makeClient(stub)
		_ = try await client.emojiSearch("face", options: .init(category:"Smileys & Emotion", version:"17.0", maxVersion:"18.0", includeSkinTones:false, offset:0))
		_ = try await client.emojiBrowse(.init(includeSkinTones:false, offset:2))
		let first = try #require(stub.requests.first?.url)
		let values = Dictionary(uniqueKeysWithValues: URLComponents(url:first,resolvingAgainstBaseURL:false)!.queryItems!.map {($0.name,$0.value!)})
		#expect(values == ["q":"face","category":"Smileys & Emotion","version":"17.0","max_version":"18.0","include_skin_tones":"false","offset":"0"])
		#expect(stub.requests[1].url?.query == "include_skin_tones=false&offset=2")
		let lookup = StubTransport(body:#"{"emoji":"🐱","name":"cat face","shortcodes":[],"deep":{}}"#)
		let resolved = try await makeClient(lookup).emoji(":cat:", shortcodeSource:"github")
		#expect(lookup.requests[0].url?.query == "shortcode_source=github")
		#expect(resolved.deep?.variants == nil && resolved.deep?.base == nil)
		let parse = StubTransport(body:#"{"emojis":[{"emoji":"👍🏿","name":"thumbs up","shortcodes":[],"category":null,"positions":[{"start":2,"end":6},{"start":7,"end":11}],"deep":{"base":"👍","variants":[{"emoji":"👍🏿","tones":["dark"]}],"shortcode_sources":{"cldr":[],"github":[],"slack":[],"discord":[]}}}]}"#)
		let result = try await makeClient(parse).emojiParse("x 👍🏿 👍🏿",deep:true,lang:"fr")
		#expect(result.emojis.count == 1 && result.emojis[0].positions[1].end == 11)
		#expect(result.emojis[0].deep?.base == "👍" && result.emojis[0].deep?.variants?.first?.tones == ["dark"])
		#expect(parse.requests[0].httpMethod == "POST")
		#expect(parse.requests[0].url?.query == "lang=fr&deep=true")
		let body = try JSONDecoder().decode([String:String].self,from:#require(parse.requests[0].httpBody))
		#expect(body == ["text":"x 👍🏿 👍🏿"])
		#expect(parse.requests[0].value(forHTTPHeaderField:"Parse-Version") == "2.0.0")
		let taxonomy = try await makeClient(StubTransport(body:#"{"categories":[{"category":"People & Body","subcategories":["hand-fingers-closed"]}]}"#)).emojiCategories()
		#expect(taxonomy.categories[0].subcategories == ["hand-fingers-closed"])
	}
	@Test func fullDownloadMetadataAndArtwork() async throws {
		let path = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("Fixtures/emoji-catalog.json")
		let text = try String(contentsOf: path, encoding: .utf8)
		let stub = StubTransport(body: text)
		let client = try makeClient(stub)
		let catalog = try await client.emojiCatalog()
		#expect(stub.requests[0].url?.query == "deep=true")
		#expect(catalog.forms["❤"] == "❤️" && catalog.shortcodes["github"]?["heart"] == ["❤️"])
		#expect(catalog.total == 1 && catalog.scope?.completeInventory == true)
		#expect(catalog.localization?.resolvedLocale == "fr" && catalog.search?.native["❤️"]?.keywords == ["love"])
		#expect(catalog.emojis[0].deep?.artwork?.isEmpty == true)
		#expect(catalog.emojis[0].deep?.artwork?["openmoji"] == nil)
		_ = try await client.emojiCatalog(.init(deep:false,maxVersion:"17.0",includeSkinTones:false))
		#expect(stub.requests[1].url?.query == "deep=false&max_version=17.0&include_skin_tones=false")
		let bundle = try #require(JSONSerialization.jsonObject(with: Data(text.utf8)) as? [String:Any])
		let metadataText = String(decoding: try JSONSerialization.data(withJSONObject: #require(bundle["metadata"])), as: UTF8.self)
		let metadataStub = StubTransport(body: metadataText)
		let metadata = try await makeClient(metadataStub).emojiMetadata()
		#expect(metadata.total == 1 && metadata.sources[0].sourceUrl == "https://unicode.org/emoji")
		#expect(metadata.notices[0].notice == "Full source notice")
		#expect(metadataStub.requests[0].url?.path == "/emoji/metadata" && metadataStub.requests[0].url?.query == nil)
	}

 @Test func privateConversion() async throws {
  let conversion=StubTransport(body:#"{"text":"🐈","total":1,"replacements":[{"emoji":"🐈","shortcode":":cat:","start":0,"end":5}],"unresolved":[]}"#)
  #expect(try await makeClient(conversion).emojiConvert(":cat:",direction:"to_emoji",shortcodeSource:"cldr").text == "🐈")
  #expect(conversion.requests[0].httpMethod == "POST")
  #expect(try JSONDecoder().decode([String:String].self,from:#require(conversion.requests[0].httpBody)) == ["text":":cat:"])
 }


}
