public struct RGB: BytesConvertible, RGBAConvertible, Equatable {
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

    public func encode(to slice: inout ArraySlice<UInt8>) {
        let startIndex = slice.startIndex
        slice[startIndex] = red
        slice[startIndex.advanced(by: 1)] = green
        slice[startIndex.advanced(by: 2)] = blue
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
