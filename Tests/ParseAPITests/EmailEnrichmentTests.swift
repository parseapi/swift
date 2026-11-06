import Foundation
import Testing
@testable import ParseAPI

@Suite struct EmailEnrichment {
	@Test func preservesFalseAndFutureCodes() async throws {
		let body = #"{"free":false,"email":"jane.doe+news@example.com","valid":true,"role":false,"disposable":false,"future":true,"first_name":"Jane","no_reply":false,"tag":"news","mail_provider":"future-provider","deliverable":true,"catchall":false,"status":"future-status","reason":"future_reason"}"#
		let result = try await makeClient(StubTransport(body: body)).email("jane.doe+news@example.com", deep: true)
 #expect(result.firstName == "Jane" && result.noReply == false && result.tag == "news" && result.mailProvider == "future-provider")
 #expect(result.status == "future-status" && result.reason == "future_reason")
	}

	@Test func oldNullAndLockedResults() async throws {
		for extra in ["", #", "deep": {}"#, #", "deep": {"first_name": null, "no_reply": null, "tag": null, "mail_provider": null, "status": null, "reason": null}"#, #", "deep": {"deliverable": false, "catchall": true}"#] {
			let body = #"{"free":false,"email":"a@example.com","valid":true,"role":false,"disposable":false"# + extra + "}"
			let result = try await makeClient(StubTransport(body: body)).email("a@example.com")
 #expect(result.firstName == nil && result.noReply == nil && result.tag == nil && result.mailProvider == nil)
 #expect(result.status == nil && result.reason == nil)
					}
	}
}
