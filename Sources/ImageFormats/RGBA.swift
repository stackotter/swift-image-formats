public struct RGBA: BytesConvertible, RGBAConvertible, Equatable {
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
