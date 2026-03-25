/// A value with the operations necessary for interpolation.
public protocol Interpolatable: AdditiveArithmetic, InterpolatableConvertible {
    /// Multiplication by a scalar.
    static func * (_ value: Self, _ scalar: Double) -> Self
}

extension Interpolatable {
    /// Multiplication by a scalar.
    public static func * (_ scalar: Double, _ value: Self) -> Self {
        value * scalar
    }
}

extension Interpolatable {
    /// Division by a scalar.
    public static func / (_ value: Self, _ scalar: Double) -> Self {
        value * (1 / scalar)
    }
}

/// Interpolatable types are trivially convertible to interpolatable types.
extension Interpolatable {
    public init(from interpolatable: Self) {
        self = interpolatable
    }

    public var interpolatable: Self {
        self
    }
}
