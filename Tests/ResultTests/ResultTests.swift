//  Copyright (c) 2015 Rob Rix. All rights reserved.

final class ResultTests: XCTestCase {
	func testMapTransformsSuccesses() {
		XCTAssertEqual(success.map { $0.count } ?? 0, 7)
	}

	func testMapRewrapsFailures() {
		XCTAssertEqual(failure.map { $0.count } ?? 0, 0)
	}

	func testInitOptionalSuccess() {
		XCTAssert(Result("success" as String?, failWith: error) == success)
	}

	func testInitOptionalFailure() {
		XCTAssert(Result(nil, failWith: error) == failure)
	}

	func testFanout() {
		let resultSuccess = success.fanout(success)
		if let (x, y) = resultSuccess.value {
			XCTAssertTrue(x == "success" && y == "success")
		} else {
			XCTFail()
		}

		let resultFailureBoth = failure.fanout(failure2)
		XCTAssert(resultFailureBoth.error as! Error == error)

		let resultFailureLeft = failure.fanout(success)
		XCTAssert(resultFailureLeft.error as! Error == error)

		let resultFailureRight = success.fanout(failure2)
		XCTAssert(resultFailureRight.error as! Error == error2)
	}

	

	// MARK: Errors

	func testErrorsIncludeTheSourceFile() {
		let file = #file
		XCTAssert(Result<()>.error().file == file)
	}

	func testErrorsIncludeTheSourceLine() {
		let (line, error) = (#line, Result<()>.error())
		XCTAssertEqual(error.line ?? -1, line)
	}

	func testErrorsIncludeTheCallingFunction() {
		let function = #function
		XCTAssert(Result<()>.error().function == function)
	}

	func testAnyErrorDelegatesLocalizedDescriptionToUnderlyingError() {
		XCTAssertEqual(error.errorDescription, "localized description")
		XCTAssertEqual(error.localizedDescription, "localized description")
		//XCTAssertEqual(error3.errorDescription, "localized description")
		XCTAssertEqual(error3.localizedDescription, "localized description")
	}

	func testAnyErrorDelegatesLocalizedFailureReasonToUnderlyingError() {
		XCTAssertEqual(error.failureReason, "failure reason")
	}

	func testAnyErrorDelegatesLocalizedRecoverySuggestionToUnderlyingError() {
		XCTAssertEqual(error.recoverySuggestion, "recovery suggestion")
	}

	func testAnyErrorDelegatesLocalizedHelpAnchorToUnderlyingError() {
		XCTAssertEqual(error.helpAnchor, "help anchor")
	}

	// MARK: Try - Catch
	
	func testTryCatchProducesSuccesses() {
		let result: Result<String> = Result(try tryIsSuccess("success"))
		XCTAssert(result == success)
	}
	
	func testTryCatchProducesFailures() {
		let result: Result<String> = Result(try tryIsSuccess(nil))
		XCTAssert(result.error as! Error == error)
	}

	func testTryCatchWithFunctionProducesSuccesses() {
		let function = { try tryIsSuccess("success") }

		let result: Result<String> = Result(attempt: function)
		XCTAssert(result == success)
	}

	func testTryCatchWithFunctionCatchProducesFailures() {
		let function = { try tryIsSuccess(nil) }

		let result: Result<String> = Result(attempt: function)
		XCTAssert(result.error as! Error == error)
	}

	func testTryCatchWithFunctionThrowingNonAnyErrorCanProducesAnyErrorFailures() {
		let nsError = NSError(domain: "", code: 0)
		let function: () throws -> String = { throw nsError }

		let result: Result<String> = Result(attempt: function)
		XCTAssert(result.error! as NSError == nsError)
	}

	func testMaterializeProducesSuccesses() {
		let result1: Result<String> = Result(try tryIsSuccess("success"))
		XCTAssert(result1 == success)

		let result2: Result<String> = Result(attempt: { try tryIsSuccess("success") })
		XCTAssert(result2 == success)
	}

	func testMaterializeProducesFailures() {
		let result1: Result<String> = Result(try tryIsSuccess(nil))
		XCTAssert(result1.error as! Error == error)

		let result2: Result<String> = Result(attempt: { try tryIsSuccess(nil) })
		XCTAssert(result2.error as! Error == error)
	}

	func testMaterializeInferrence() {
		let result = Result(attempt: { try tryIsSuccess(nil) })
		XCTAssert((type(of: result) as Any.Type) is Result<String>.Type)
	}

	// MARK: Recover

	func testRecoverProducesLeftForLeftSuccess() {
		let left = Result<String>.success("left")
		XCTAssertEqual(left.recover("right"), "left")
	}

	func testRecoverProducesRightForLeftFailure() {
		let left = Result<String>.failure(Error.a)
		XCTAssertEqual(left.recover("right"), "right")
	}

	// MARK: Recover With

	func testRecoverWithProducesLeftForLeftSuccess() {
		let left = Result<String>.success("left")
		let right = Result<String>.success("right")

		XCTAssertEqual(left.recover(with: right).value, "left")
	}

	func testRecoverWithProducesRightSuccessForLeftFailureAndRightSuccess() {
		struct Error: Swift.Error {}

		let left = Result<String>.failure(Error())
		let right = Result<String>.success("right")

		XCTAssertEqual(left.recover(with: right).value, "right")
	}

	func testRecoverWithProducesRightFailureForLeftFailureAndRightFailure() {
		enum Error: Swift.Error { case left, right }

		let left = Result<String>.failure(Error.left)
		let right = Result<String>.failure(Error.right)

		XCTAssertEqual(left.recover(with: right).error as? Error, Error.right)
	}

	func testTryMapProducesSuccess() {
		let result = success.tryMap(tryIsSuccess)
		XCTAssert(result == success)
	}

	func testTryMapProducesFailure() {
		let result = Result<String>.success("fail").tryMap(tryIsSuccess)
		XCTAssert(result == failure)
	}
}


// MARK: - Fixtures

enum Error: Swift.Error, LocalizedError {
	case a, b

	var errorDescription: String? {
		return "localized description"
	}

	var failureReason: String? {
		return "failure reason"
	}

	var helpAnchor: String? {
		return "help anchor"
	}

	var recoverySuggestion: String? {
		return "recovery suggestion"
	}
}

let success = Result<String>.success("success")
let error = Error.a
let error2 = Error.b
let error3 = NSError(domain: "Result", code: 42, userInfo: [NSLocalizedDescriptionKey: "localized description"])
let failure = Result<String>.failure(error)
let failure2 = Result<String>.failure(error2)

// MARK: - Helpers

func tryIsSuccess(_ text: String?) throws -> String {
	guard let text = text, text == "success" else {
		throw error
	}

	return text
}

extension NSError {
	var function: String? {
		return userInfo[Result<()>.functionKey] as? String
	}
	
	var file: String? {
		return userInfo[Result<()>.fileKey] as? String
	}

	var line: Int? {
		return userInfo[Result<()>.lineKey] as? Int
	}
}

extension ResultTests {
	static var allTests: [(String, (ResultTests) -> () throws -> Void)] {
		return [
			("testMapTransformsSuccesses", testMapTransformsSuccesses),
			("testMapRewrapsFailures", testMapRewrapsFailures),
			("testInitOptionalSuccess", testInitOptionalSuccess),
			("testInitOptionalFailure", testInitOptionalFailure),
			("testFanout", testFanout),
			("testErrorsIncludeTheSourceFile", testErrorsIncludeTheSourceFile),
			("testErrorsIncludeTheSourceLine", testErrorsIncludeTheSourceLine),
			("testErrorsIncludeTheCallingFunction", testErrorsIncludeTheCallingFunction),
			("testTryCatchProducesSuccesses", testTryCatchProducesSuccesses),
			("testTryCatchProducesFailures", testTryCatchProducesFailures),
			("testTryCatchWithFunctionProducesSuccesses", testTryCatchWithFunctionProducesSuccesses),
			("testTryCatchWithFunctionCatchProducesFailures", testTryCatchWithFunctionCatchProducesFailures),
			("testMaterializeProducesSuccesses", testMaterializeProducesSuccesses),
			("testMaterializeProducesFailures", testMaterializeProducesFailures),
			("testRecoverProducesLeftForLeftSuccess", testRecoverProducesLeftForLeftSuccess),
			("testRecoverProducesRightForLeftFailure", testRecoverProducesRightForLeftFailure),
			("testRecoverWithProducesLeftForLeftSuccess", testRecoverWithProducesLeftForLeftSuccess),
			("testRecoverWithProducesRightSuccessForLeftFailureAndRightSuccess", testRecoverWithProducesRightSuccessForLeftFailureAndRightSuccess),
			("testRecoverWithProducesRightFailureForLeftFailureAndRightFailure", testRecoverWithProducesRightFailureForLeftFailureAndRightFailure),
			("testTryMapProducesSuccess", testTryMapProducesSuccess),
			("testTryMapProducesFailure", testTryMapProducesFailure),
			("testAnyErrorDelegatesLocalizedDescriptionToUnderlyingError", testAnyErrorDelegatesLocalizedDescriptionToUnderlyingError),
			("testAnyErrorDelegatesLocalizedFailureReasonToUnderlyingError", testAnyErrorDelegatesLocalizedFailureReasonToUnderlyingError),
			("testAnyErrorDelegatesLocalizedRecoverySuggestionToUnderlyingError", testAnyErrorDelegatesLocalizedRecoverySuggestionToUnderlyingError),
			("testAnyErrorDelegatesLocalizedHelpAnchorToUnderlyingError", testAnyErrorDelegatesLocalizedHelpAnchorToUnderlyingError),
		]
	}
}

import Foundation
import Result
import XCTest
