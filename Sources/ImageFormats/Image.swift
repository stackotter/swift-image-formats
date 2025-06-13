import Foundation
import JPEG
import LibPNG
import WebP

public enum ImageLoadingError: Error, Sendable {
    case unknownMagicBytes
    case unknownImageFileExtension(String)
    case pngError(code: Int, message: String)
}

// Constant macro values taken from libpng (macros aren't accessible
// from Swift so we just need to use the raw values).
private let pngFormatRGBA: png_uint_32 = 3
private let pngImageVersion: png_uint_32 = 1

public struct Image<Pixel: BytesConvertible>: Hashable, Sendable {
    public var width: Int
    public var height: Int
    public var bytes: [UInt8]

    public var pixels: [Pixel] {
        var pixels: [Pixel] = []
        pixels.reserveCapacity(width * height)
        for i in 0..<(width * height) {
            let start = bytes.startIndex.advanced(by: i * Pixel.stride)
            let end = start.advanced(by: Pixel.stride)
            let pixel = Pixel.decode(bytes[start..<end])
            pixels.append(pixel)
        }
        return pixels
    }

    public struct Row {
        public var width: Int
        public var bytes: ArraySlice<UInt8>

        public subscript(column column: Int) -> Pixel {
            precondition(0 <= column && column <= width, "column out of bounds")
            let start = bytes.startIndex.advanced(by: column * Pixel.stride)
            let end = start.advanced(by: Pixel.stride)
            return Pixel.decode(bytes[start..<end])
        }
    }

    public subscript(row row: Int) -> Row {
        precondition(0 <= row && row <= height, "row out of bounds")
        let start = bytes.startIndex.advanced(by: row * width * Pixel.stride)
        let end = start.advanced(by: width * Pixel.stride)
        return Row(width: width, bytes: bytes[start..<end])
    }

    public init(width: Int, height: Int, bytes: [UInt8]) {
        // Probably a bit of a redundant precondition, but Pixel.stride could
        // technically be negative cause it's user implementable, so I'll leave
        // this here.
        precondition(0 <= width && 0 <= height, "negative dimensions")
        precondition(
            bytes.count == width * height * Pixel.stride,
            "incorrect number of bytes"
        )
        self.width = width
        self.height = height
        self.bytes = bytes
    }

    public init(width: Int, height: Int, pixels: [Pixel]) {
        precondition(0 <= width && 0 <= height, "negative dimensions")
        precondition(pixels.count == width * height, "incorrect number of pixels")

        self.width = width
        self.height = height

        bytes = [UInt8](repeating: 0, count: Pixel.stride * pixels.count)
        for (i, pixel) in pixels.enumerated() {
            let start = i * Pixel.stride
            pixel.encode(to: &bytes, startingAt: start)
        }
    }

    public func map(_ transform: (Pixel) -> Pixel) -> Self {
        var newBytes = [UInt8](repeating: 0, count: bytes.count)
        for index in 0..<(width * height) {
            let start = index * Pixel.stride
            let end = start + Pixel.stride
            let pixel = Pixel.decode(bytes[start..<end])
            let newPixel = transform(pixel)
            newPixel.encode(to: &newBytes, startingAt: start)
        }
        return Image(width: width, height: height, bytes: newBytes)
    }
}

extension Image<RGBA> {
    public static func loadPNG(from data: [UInt8]) throws -> Self {
        var image = png_image()
        memset(&image, 0, MemoryLayout<png_image>.size)
        image.version = pngImageVersion

        guard png_image_begin_read_from_memory(&image, data, data.count) != 0 else {
            throw ImageLoadingError.pngError(
                code: Int(image.warning_or_error),
                message: image.swiftMessage
            )
        }

        image.format = pngFormatRGBA

        // The PNG_IMAGE_SIZE macro isn't available to Swift, but the calculation
        // it performs is pretty standard so it *should* be safe enough to just
        // do it ourselves and hope libpng never changes it.
        let rgbaByteCount = Int(image.width * image.height * 4)
        var rgbaBytes = [UInt8](repeating: 0, count: rgbaByteCount)

        guard png_image_finish_read(&image, nil, &rgbaBytes, 0, nil) != 0 else {
            throw ImageLoadingError.pngError(
                code: Int(image.warning_or_error),
                message: image.swiftMessage
            )
        }

        return Image(
            width: Int(image.width),
            height: Int(image.height),
            bytes: rgbaBytes
        )
    }

    public static func loadWebP(from data: [UInt8]) throws -> Self {
        let image = try WebP.decode(data)
        return Image(
            width: image.width,
            height: image.height,
            bytes: image.rgba
        )
    }

    public func encodeToPNG() throws -> [UInt8] {
        var image = png_image()
        image.width = png_uint_32(width)
        image.height = png_uint_32(height)
        image.format = pngFormatRGBA
        image.version = pngImageVersion

        var size: png_alloc_size_t = 0
        guard
            png_image_write_to_memory(
                &image, nil, &size, 0, bytes,
                0, nil
            ) != 0
        else {

            throw ImageLoadingError.pngError(
                code: Int(image.warning_or_error),
                message: image.swiftMessage
            )
        }

        var outputBuffer = [UInt8](repeating: 0, count: Int(size))
        guard
            png_image_write_to_memory(
                &image, &outputBuffer, &size, 0,
                bytes, 0, nil
            ) != 0
        else {
            print("Failed to write to memory")
            throw ImageLoadingError.pngError(
                code: Int(image.warning_or_error),
                message: image.swiftMessage
            )
        }

        return outputBuffer
    }

    public func encodeToWebP(quality: Float = 0.9) throws -> [UInt8] {
        let webp = WebP(width: width, height: height, rgba: bytes)
        return try webp.encode(quality: quality)
    }
}

extension Image<RGB> {
    public static func loadJPEG(from data: [UInt8]) throws -> Self {
        var stream = InMemoryStream(data)
        let image = try JPEG.Data.Rectangular<JPEG.Common>.decompress(stream: &stream)
        let pixels: [JPEG.RGB] = image.unpack(as: JPEG.RGB.self)
        return Image(
            width: image.size.x,
            height: image.size.y,
            bytes: pixels.flatMap { pixel in
                [pixel.r, pixel.g, pixel.b]
            }
        )
    }

    public func encodeToJPEG(compression: Double = 0.75) throws -> [UInt8] {
        let layout = JPEG.Layout<JPEG.Common>(
            format: .ycc8,
            process: .baseline,
            components: [
                1: (factor: (2, 2), qi: 0),
                2: (factor: (1, 1), qi: 1),
                3: (factor: (1, 1), qi: 1),
            ],
            scans: [
                .sequential((1, \.0, \.0), (2, \.1, \.1), (3, \.1, \.1))
            ]
        )
        let jfif: JPEG.JFIF = .init(version: .v1_2, density: (72, 72, .inches))
        let image = JPEG.Data.Rectangular<JPEG.Common>.pack(
            size: (x: width, y: height),
            layout: layout,
            metadata: [.jfif(jfif)],
            pixels: pixels.map { pixel in
                JPEG.RGB(pixel.red, pixel.green, pixel.blue)
            }
        )

        var stream = InMemoryStream([])
        try image.compress(
            stream: &stream,
            quanta: [
                0: JPEG.CompressionLevel.luminance(compression).quanta,
                1: JPEG.CompressionLevel.chrominance(compression).quanta,
            ]
        )

        return stream.buffer
    }
}

extension Image where Pixel: RGBAConvertible {
    public func convert<NewPixelFormat: RGBAConvertible>(
        to format: NewPixelFormat.Type
    ) -> Image<NewPixelFormat> {
        // Short-circuit if the image is already in the desired format
        if let image = self as? Image<NewPixelFormat> {
            return image
        }

        var data = [UInt8](
            repeating: 0,
            count: NewPixelFormat.stride * width * height
        )
        for (i, pixel) in pixels.enumerated() {
            let start = i * NewPixelFormat.stride
            NewPixelFormat(from: pixel.rgba).encode(to: &data, startingAt: start)
        }
        return Image<NewPixelFormat>(
            width: width,
            height: height,
            bytes: data
        )
    }

    /// Encodes the image using the given format. Uses the default settings
    /// used by each underlying encoding function.
    public func encode(to format: ImageFormat) throws -> [UInt8] {
        switch format {
            case .png:
                return try convert(to: RGBA.self).encodeToPNG()
            case .jpeg:
                return try convert(to: RGB.self).encodeToJPEG()
            case .webp:
                return try convert(to: RGBA.self).encodeToWebP()
        }
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

private final class InMemoryStream:
    JPEG.Bytestream.Source,
    JPEG.Bytestream.Destination
{
    var buffer: [UInt8]
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

    func write(_ buffer: [UInt8]) -> Void? {
        self.buffer += buffer
    }
}

extension png_image {
    var swiftMessage: String {
        withUnsafePointer(to: message) { pointer in
            pointer.withMemoryRebound(to: CChar.self, capacity: 1) { pointer in
                String(cString: pointer)
            }
        }
    }
}
