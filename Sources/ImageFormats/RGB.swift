public struct RGB: BytesConvertible, RGBAConvertible, Hashable, Sendable {
    public static let stride = 3

    public var red: UInt8
    public var green: UInt8
    public var blue: UInt8

    public var rgba: RGBA {
        RGBA(red, green, blue, 255)
    }

    public init(_ red: UInt8, _ green: UInt8, _ blue: UInt8) {
        self.red = red
        self.green = green
        self.blue = blue
    }

    public init(from rgba: RGBA) {
        red = rgba.red
        green = rgba.green
        blue = rgba.blue
    }

    public func encode(to array: inout [UInt8], startingAt offset: Int) {
        array[offset] = red
        array[offset + 1] = green
        array[offset + 2] = blue
    }

    public static func decode(_ bytes: ArraySlice<UInt8>) -> RGB {
        let startIndex = bytes.startIndex
        return RGB(
            bytes[startIndex],
            bytes[startIndex.advanced(by: 1)],
            bytes[startIndex.advanced(by: 2)]
        )
    }
}
