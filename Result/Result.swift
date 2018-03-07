//  Copyright (c) 2015 Rob Rix. All rights reserved.

/// An enum representing either a failure with an explanatory error, or a success with a result value.
public enum Result<Value>: ResultProtocol, CustomStringConvertible, CustomDebugStringConvertible {
	case success(Value)
	case failure(Swift.Error)

	// MARK: Constructors

	/// Constructs a success wrapping a `value`.
	public init(value: Value) {
		self = .success(value)
	}

	/// Constructs a failure wrapping an `error`.
	public init(error: Swift.Error) {
		self = .failure(error)
	}

	/// Constructs a result from an `Optional`, failing with `Error` if `nil`.
	public init(_ value: Value?, failWith: @autoclosure () -> Swift.Error) {
		self = value.map(Result.success) ?? .failure(failWith())
	}

	/// Constructs a result from a function that uses `throw`, failing with `Error` if throws.
	public init(_ f: @autoclosure () throws -> Value) {
		self.init(attempt: f)
	}

	/// Constructs a result from a function that uses `throw`, failing with `Error` if throws.
	public init(attempt f: () throws -> Value) {
		do {
			self = .success(try f())
		} catch let error {
			self = .failure(error)
		}
	}

	// MARK: Deconstruction

	/// Returns the value from `success` Results or `throw`s the error.
	public func dematerialize() throws -> Value {
		switch self {
		case let .success(value):
			return value
		case let .failure(error):
			throw error
		}
	}

	/// Case analysis for Result.
	///
	/// Returns the value produced by applying `ifFailure` to `failure` Results, or `ifSuccess` to `success` Results.
	public func analysis<Result>(ifSuccess: (Value) -> Result, ifFailure: (Error) -> Result) -> Result {
		switch self {
		case let .success(value):
			return ifSuccess(value)
		case let .failure(value):
			return ifFailure(value)
		}
	}

	// MARK: Errors

	/// The domain for errors constructed by Result.
	public static var errorDomain: String { return "com.antitypical.Result" }

	/// The userInfo key for source functions in errors constructed by Result.
	public static var functionKey: String { return "\(errorDomain).function" }

	/// The userInfo key for source file paths in errors constructed by Result.
	public static var fileKey: String { return "\(errorDomain).file" }

	/// The userInfo key for source file line numbers in errors constructed by Result.
	public static var lineKey: String { return "\(errorDomain).line" }

	/// Constructs an error.
	public static func error(_ message: String? = nil, function: String = #function, file: String = #file, line: Int = #line) -> NSError {
		var userInfo: [String: Any] = [
			functionKey: function,
			fileKey: file,
			lineKey: line,
		]

		if let message = message {
			userInfo[NSLocalizedDescriptionKey] = message
		}

		return NSError(domain: errorDomain, code: 0, userInfo: userInfo)
	}


	// MARK: CustomStringConvertible

	public var description: String {
		switch self {
		case let .success(value): return ".success(\(value))"
		case let .failure(error): return ".failure(\(error))"
		}
	}


	// MARK: CustomDebugStringConvertible

	public var debugDescription: String {
		return description
	}

	// MARK: ResultProtocol
	public var result: Result<Value> {
		return self
	}
}


#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)


#endif

// MARK: -

import Foundation
