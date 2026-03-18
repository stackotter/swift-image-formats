public struct ARGB: BytesConvertible {
    public static var stride = 4

    public var alpha: UInt8
    public var red: UInt8
    public var green: UInt8
    public var blue: UInt8

    public init(_ alpha: UInt8, _ red: UInt8, _ green: UInt8, _ blue: UInt8) {
        self.alpha = alpha
        self.red = red
        self.green = green
        self.blue = blue
    }

    public static func decode(_ bytes: ArraySlice<UInt8>) -> ARGB {
        ARGB(
            bytes[bytes.startIndex],
            bytes[bytes.startIndex.advanced(by: 1)],
            bytes[bytes.startIndex.advanced(by: 2)],
            bytes[bytes.startIndex.advanced(by: 3)]
        )
    }

    public func encode(to array: inout [UInt8], startingAt offset: Int) {
        array[offset] = alpha
        array[offset + 1] = red
        array[offset + 2] = green
        array[offset + 3] = blue
    }
}

extension ARGB: RGBAConvertible {
    public init(from rgba: ImageFormats.RGBA) {
        self.init(
            rgba.alpha,
            rgba.red,
            rgba.green,
            rgba.blue
        )
    }

    public var rgba: RGBA {
        RGBA(red, green, blue, alpha)
    }
}

extension ARGB: InterpolatableConvertible {
    public var interpolatable: ContinuousARGB {
        ContinuousARGB(
            alpha: Double(alpha),
            red: Double(red),
            green: Double(green),
            blue: Double(blue)
        )
    }

    public init(from interpolatable: ContinuousARGB) {
        self.init(
            UInt8(clamp(interpolatable.alpha, to: 0...Double(UInt8.max - 1))),
            UInt8(clamp(interpolatable.red, to: 0...Double(UInt8.max - 1))),
            UInt8(clamp(interpolatable.green, to: 0...Double(UInt8.max - 1))),
            UInt8(clamp(interpolatable.blue, to: 0...Double(UInt8.max - 1)))
        )
    }
}

public struct ContinuousARGB: Interpolatable {
    public static let zero = Self(alpha: 0, red: 0, green: 0, blue: 0)

    public var alpha: Double
    public var red: Double
    public var green: Double
    public var blue: Double

    public static func + (lhs: Self, rhs: Self) -> Self {
        Self(
            alpha: lhs.alpha + rhs.alpha,
            red: lhs.red + rhs.red,
            green: lhs.green + rhs.green,
            blue: lhs.blue + rhs.blue
        )
    }

    public static func - (lhs: Self, rhs: Self) -> Self {
        Self(
            alpha: lhs.alpha - rhs.alpha,
            red: lhs.red - rhs.red,
            green: lhs.green - rhs.green,
            blue: lhs.blue - rhs.blue
        )
    }

    public static func * (lhs: Self, rhs: Double) -> Self {
        Self(
            alpha: lhs.alpha * rhs,
            red: lhs.red * rhs,
            green: lhs.green * rhs,
            blue: lhs.blue * rhs
        )
    }
}
