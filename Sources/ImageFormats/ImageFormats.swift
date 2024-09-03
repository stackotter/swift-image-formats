import Foundation
import JPEG
import PNG
import WebP

public enum ImageLoadingError: LocalizedError {
    case unknownMagicBytes
    case unknownImageFileExtension(String)
}

public struct Image<Pixel: BytesConvertible> {
    public var width: Int
    public var height: Int
    public var data: [UInt8]

    public var pixels: [Pixel] {
        var pixels: [Pixel] = []
        pixels.reserveCapacity(width * height)
        for i in 0..<(width * height) {
            let start = data.startIndex.advanced(by: i * Pixel.stride)
            let end = start.advanced(by: Pixel.stride)
            let pixel = Pixel.decode(data[start..<end])
            pixels.append(pixel)
        }
        return pixels
    }

    public struct Row {
        public var width: Int
        public var data: ArraySlice<UInt8>

        public subscript(column column: Int) -> Pixel {
            get {
                precondition(0 <= column && column <= width, "column out of bounds")
                let start = data.startIndex.advanced(by: column * Pixel.stride)
                let end = start.advanced(by: Pixel.stride)
                return Pixel.decode(data[start..<end])
            }
            set {
                precondition(0 <= column && column <= width, "column out of bounds")
                let start = data.startIndex.advanced(by: column * Pixel.stride)
                let end = start.advanced(by: Pixel.stride)
                newValue.encode(to: &data[start..<end])
            }
        }
    }

    public subscript(row row: Int) -> Row {
        precondition(0 <= row && row <= height, "row out of bounds")
        let start = data.startIndex.advanced(by: row * width * Pixel.stride)
        let end = start.advanced(by: width * Pixel.stride)
        return Row(width: width, data: data[start..<end])
    }
}

public protocol BytesConvertible {
    static var stride: Int { get }
    static func decode(_ bytes: ArraySlice<UInt8>) -> Self
    func encode(to slice: inout ArraySlice<UInt8>)
}

public protocol RGBAConvertible {
    init(from rgba: RGBA)
    var rgba: RGBA { get }
}

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

    public func encode(to slice: inout ArraySlice<UInt8>) {
        let startIndex = slice.startIndex
        slice[startIndex] = red
        slice[startIndex.advanced(by: 1)] = green
        slice[startIndex.advanced(by: 2)] = blue
        slice[startIndex.advanced(by: 3)] = alpha
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

final class Stream: PNG.BytestreamSource, JPEG.Bytestream.Source {
    let buffer: [UInt8]
    var index: Int

    init(_ buffer: [UInt8]) {
        self.buffer = buffer
        index = 0
    }

    func read(count: Int) -> [UInt8]? {
        guard index < buffer.count else {
            return nil
        }

        let stride = min(count, buffer.count - index)
        let slice = buffer[index..<(index + stride)]
        index += stride
        return Array(slice)
    }
}

extension Image<RGBA> {
    public static func loadPNG(from data: [UInt8]) throws -> Self {
        var stream = Stream(data)
        let image = try PNG.Image.decompress(stream: &stream)
        // TODO: Optimise [RGBA] -> [UInt8] conversions (or remove need for conversions)
        return Image(
            width: image.size.x,
            height: image.size.y,
            data: image.unpack(as: PNG.RGBA<UInt8>.self).flatMap { pixel in
                [pixel.r, pixel.g, pixel.b, pixel.a]
            }
        )
    }

    public static func loadWebP(from data: [UInt8]) throws -> Self {
        let image = try WebP.decode(data)
        return Image(
            width: image.width,
            height: image.height,
            data: image.rgba
        )
    }
}

extension Image<RGB> {
    public static func loadJPEG(from data: [UInt8]) throws -> Self {
        var stream = Stream(data)
        let image = try JPEG.Data.Rectangular<JPEG.Common>.decompress(stream: &stream)
        let pixels: [JPEG.RGB] = image.unpack(as: JPEG.RGB.self)
        return Image(
            width: image.size.x,
            height: image.size.y,
            data: pixels.flatMap { pixel in
                [pixel.r, pixel.g, pixel.b]
            }
        )
    }
}

extension Image where Pixel: RGBAConvertible {
    public func convert<NewPixelFormat: RGBAConvertible>(
        to format: NewPixelFormat.Type
    ) -> Image<NewPixelFormat> {
        var data = [UInt8](repeating: 0, count: NewPixelFormat.stride * width * height)
        for (i, pixel) in pixels.enumerated() {
            let start = i * NewPixelFormat.stride
            let end = start + NewPixelFormat.stride
            NewPixelFormat(from: pixel.rgba).encode(to: &data[start..<end])
        }
        return Image<NewPixelFormat>(
            width: width,
            height: height,
            data: data
        )
    }

    public static func load(from data: [UInt8], as format: ImageFormat) throws -> Self {
        switch format {
            case .png:
                return try Image<RGBA>.loadPNG(from: data).convert(to: Pixel.self)
            case .jpeg:
                return try Image<RGB>.loadJPEG(from: data).convert(to: Pixel.self)
            case .webp:
                return try Image<RGBA>.loadWebP(from: data).convert(to: Pixel.self)
        }
    }

    public static func load(from data: [UInt8]) throws -> Self {
        guard let format = detectFormat(of: data) else {
            throw ImageLoadingError.unknownMagicBytes
        }

        return try load(from: data, as: format)
    }

    public static func load(
        from data: [UInt8],
        usingFileExtension fileExtension: String
    ) throws -> Self {
        guard let format = ImageFormat(fromExtension: fileExtension) else {
            throw ImageLoadingError.unknownImageFileExtension(fileExtension)
        }

        return try load(from: data, as: format)
    }

    public static func detectFormat(of data: [UInt8]) -> ImageFormat? {
        let pngMagicBytes: [UInt8] = [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]

        let jpegMagicBytes: [[UInt8]] = [
            [0xff, 0xd8, 0xff, 0xdb],
            [0xff, 0xd8, 0xff, 0xee],
            [0xff, 0xd8, 0xff, 0xe1],
            [0xff, 0xd8, 0xff, 0xe0],
        ]

        let webPMagicBytes: [UInt8?] = [
            0x52, 0x49, 0x46, 0x46, nil, nil, nil, nil, 0x57, 0x45, 0x42, 0x50,
        ]

        if data.starts(with: pngMagicBytes) {
            return .png
        } else if jpegMagicBytes.contains(where: { bytes in
            data.starts(with: bytes)
        }) {
            return .jpeg
        } else if data.count >= webPMagicBytes.count
            && zip(webPMagicBytes, data).allSatisfy({
                $0 == nil || $0 == $1
            })
        {
            return .webp
        } else {
            return nil
        }
    }
}

public enum ImageFormat {
    case png
    case jpeg
    case webp

    init?(fromExtension fileExtension: String) {
        switch fileExtension.lowercased() {
            case "png":
                self = .png
            case "jpg", "jpeg":
                self = .jpeg
            case "webp":
                self = .webp
            default:
                return nil
        }
    }
}
