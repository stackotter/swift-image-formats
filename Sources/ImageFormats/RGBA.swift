public struct RGBA: BytesConvertible, RGBAConvertible, Hashable, Sendable {
    public static let stride = 4

    public var red: UInt8
    public var green: UInt8
    public var blue: UInt8
    public var alpha: UInt8

    public var rgba: RGBA {
        self
    }

    public var rgb: RGB {
        RGB(red, green, blue)
    }

    public init(_ red: UInt8, _ green: UInt8, _ blue: UInt8, _ alpha: UInt8) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }

    public init(from rgba: RGBA) {
        self = rgba
    }

    public init(grayscale value: UInt8, alpha: UInt8) {
        self.init(value, value, value, alpha)
    }

    public init(grayscale value: UInt8) {
        self.init(value, value, value, .max)
    }

    public func encode(to array: inout [UInt8], startingAt offset: Int) {
        array[offset] = red
        array[offset + 1] = green
        array[offset + 2] = blue
        array[offset + 3] = alpha
    }

    public static func decode(_ bytes: ArraySlice<UInt8>) -> RGBA {
        let startIndex = bytes.startIndex
        return RGBA(
            bytes[startIndex],
            bytes[startIndex.advanced(by: 1)],
            bytes[startIndex.advanced(by: 2)],
            bytes[startIndex.advanced(by: 3)]
        )
    }
}

extension RGBA: InterpolatableConvertible {
    public var interpolatable: ContinuousRGBA {
        ContinuousRGBA(
            red: Double(red),
            green: Double(green),
            blue: Double(blue),
            alpha: Double(alpha)
        )
    }

    public init(from interpolatable: ContinuousRGBA) {
        self.init(
            UInt8(clamp(interpolatable.red, to: 0...Double(UInt8.max - 1))),
            UInt8(clamp(interpolatable.green, to: 0...Double(UInt8.max - 1))),
            UInt8(clamp(interpolatable.blue, to: 0...Double(UInt8.max - 1))),
            UInt8(clamp(interpolatable.alpha, to: 0...Double(UInt8.max - 1)))
        )
    }
}

public struct ContinuousRGBA: Interpolatable {
    public static let zero = Self(red: 0, green: 0, blue: 0, alpha: 0)

    public var red: Double
    public var green: Double
    public var blue: Double
    public var alpha: Double

    public static func + (lhs: Self, rhs: Self) -> Self {
        Self(
            red: lhs.red + rhs.red,
            green: lhs.green + rhs.green,
            blue: lhs.blue + rhs.blue,
            alpha: lhs.alpha + rhs.alpha
        )
    }

    public static func - (lhs: Self, rhs: Self) -> Self {
        Self(
            red: lhs.red - rhs.red,
            green: lhs.green - rhs.green,
            blue: lhs.blue - rhs.blue,
            alpha: lhs.alpha - rhs.alpha
        )
    }

    public static func * (lhs: Self, rhs: Double) -> Self {
        Self(
            red: lhs.red * rhs,
            green: lhs.green * rhs,
            blue: lhs.blue * rhs,
            alpha: lhs.alpha * rhs
        )
    }
}
