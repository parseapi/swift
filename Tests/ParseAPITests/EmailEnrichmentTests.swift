import Foundation
import Testing
@testable import ParseAPI

@Suite struct EmailEnrichment {
	@Test func preservesFalseAndFutureCodes() async throws {
		let body = #"{"email":"jane.doe+news@example.com","valid":true,"role":false,"disposable":false,"deep": {"first_name":"Jane","no_reply":false,"tag":"news","mail_provider":"future-provider","deliverable":true,"catchall":false,"status":"future-status","reason":"future_reason"},"future":true}"#
		let result = try await makeClient(StubTransport(body: body)).email("jane.doe+news@example.com", deep: true)
		#expect(result.deep?.firstName == "Jane" && result.deep?.noReply == false && result.deep?.tag == "news" && result.deep?.mailProvider == "future-provider")
		#expect(result.deep?.status == "future-status" && result.deep?.reason == "future_reason")
	}

	@Test func oldNullAndLockedResults() async throws {
		for extra in ["", #", "deep": {}"#, #", "deep": {"first_name": null, "no_reply": null, "tag": null, "mail_provider": null, "status": null, "reason": null}"#, #", "deep": {"deliverable": false, "catchall": true}"#] {
			let body = #"{"email":"a@example.com","valid":true,"role":false,"disposable":false"# + extra + "}"
			let result = try await makeClient(StubTransport(body: body)).email("a@example.com")
			#expect(result.deep?.firstName == nil && result.deep?.noReply == nil && result.deep?.tag == nil && result.deep?.mailProvider == nil)
			#expect(result.deep?.status == nil && result.deep?.reason == nil)
			#expect(extra.isEmpty ? result.deep == nil : result.deep != nil)
		}
	}
}
