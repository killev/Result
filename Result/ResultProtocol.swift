//  Copyright (c) 2015 Rob Rix. All rights reserved.

/// A protocol that can be used to constrain associated types as `Result`.
import Foundation

public protocol ResultProtocol {
	associatedtype Value
	
	init(value: Value)
	init(error: Error)
	
	var result: Result<Value> { get }
}

public extension Result {
	/// Returns the value if self represents a success, `nil` otherwise.
	public var value: Value? {
		switch self {
		case let .success(value): return value
		case .failure: return nil
		}
	}
	
	/// Returns the error if self represents a failure, `nil` otherwise.
	public var error: Error? {
		switch self {
		case .success: return nil
		case let .failure(error): return error
		}
	}

	/// Returns a new Result by mapping `Success`es’ values using `transform`, or re-wrapping `Failure`s’ errors.
	public func map<U>(_ transform: (Value) -> U) -> Result<U> {
		return flatMap { .success(transform($0)) }
	}

	/// Returns the result of applying `transform` to `Success`es’ values, or re-wrapping `Failure`’s errors.
	public func flatMap<U>(_ transform: (Value) -> Result<U>) -> Result<U> {
		switch self {
		case let .success(value): return transform(value)
		case let .failure(error): return .failure(error)
		}
	}

	/// Returns a Result with a tuple of the receiver and `other` values if both
	/// are `Success`es, or re-wrapping the error of the earlier `Failure`.
	public func fanout<U>(_ other: @autoclosure () -> Result<U>) -> Result<(Value, U)> {
		return self.flatMap { left in other().map { right in (left, right) } }
	}

	/// Returns a new Result by mapping `Failure`'s values using `transform`, or re-wrapping `Success`es’ values.
//	public func mapError<Error2>(_ transform: (Error) -> Error2) -> Result<Value> {
//		return flatMapError { .failure(transform($0)) }
//	}

	/// Returns the result of applying `transform` to `Failure`’s errors, or re-wrapping `Success`es’ values.
//	public func flatMapError<Error2>(_ transform: (Error) -> Result<Value, Error2>) -> Result<Value, Error2> {
//		switch self {
//		case let .success(value): return .success(value)
//		case let .failure(error): return transform(error)
//		}
//	}
}

public extension Result {

	// MARK: Higher-order functions

	/// Returns `self.value` if this result is a .Success, or the given value otherwise. Equivalent with `??`
	public func recover(_ value: @autoclosure () -> Value) -> Value {
		return self.value ?? value()
	}

	/// Returns this result if it is a .Success, or the given result otherwise. Equivalent with `??`
	public func recover(with result: @autoclosure () -> Result<Value>) -> Result<Value> {
		switch self {
		case .success: return self
		case .failure: return result()
		}
	}
}

public extension Result {

	/// Returns the result of applying `transform` to `Success`es’ values, or wrapping thrown errors.
	public func tryMap<U>(_ transform: (Value) throws -> U) -> Result<U> {
		return flatMap { value in
			do {
				return .success(try transform(value))
			}
			catch {
				return .failure(error)
			}
		}
	}
}

// MARK: - Operators

extension Result where Value: Equatable {
	/// Returns `true` if `left` and `right` are both `Success`es and their values are equal, or if `left` and `right` are both `Failure`s and their errors are equal.
	public static func ==(left: Result<Value>, right: Result<Value>) -> Bool {
		if let left = left.value, let right = right.value {
			return left == right
		} else if let left = left.error, let right = right.error {
			return left as NSError == right as NSError
		}
		return false
	}

	/// Returns `true` if `left` and `right` represent different cases, or if they represent the same case but different values.
	public static func !=(left: Result<Value>, right: Result<Value>) -> Bool {
		return !(left == right)
	}
}

extension Result {
	/// Returns the value of `left` if it is a `Success`, or `right` otherwise. Short-circuits.
	public static func ??(left: Result<Value>, right: @autoclosure () -> Value) -> Value {
		return left.recover(right())
	}

	/// Returns `left` if it is a `Success`es, or `right` otherwise. Short-circuits.
	public static func ??(left: Result<Value>, right: @autoclosure () -> Result<Value>) -> Result<Value> {
		return left.recover(with: right())
	}
}

