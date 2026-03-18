import LibPNG

/// A pixel format that is supported by the PNG file format. The `pngFormatId`
/// is the format's value in libpng. E.g. the value of `PNG_FORMAT_RGBA`.
protocol PNGSupportedFormat {
    static var pngFormatId: png_uint_32 { get }
}

extension RGBA: PNGSupportedFormat {
    static let pngFormatId = png_uint_32(3)
}

extension ARGB: PNGSupportedFormat {
    static let pngFormatId = png_uint_32(35)
}
