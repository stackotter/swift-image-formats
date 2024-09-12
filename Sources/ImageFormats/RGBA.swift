import PNG

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

/// An implementation of `PNG.Color` adapted from `https://github.com/tayloraswift/swift-png/blob/4.4.5/Sources/PNG/ColorTargets/PNG.RGBA.swift`.
extension RGBA: PNG.Color {
    public typealias Aggregate = (UInt8, UInt8, UInt8, UInt8)

    public static func unpack(
        _ interleaved: [UInt8],
        of format: PNG.Format,
        deindexer: ([(r: UInt8, g: UInt8, b: UInt8, a: UInt8)]) -> (Int) -> Aggregate
    ) -> [Self] {
        let depth = format.pixel.depth
        switch format {
            case .indexed1(let palette, fill: _),
                .indexed2(let palette, fill: _),
                .indexed4(let palette, fill: _),
                .indexed8(let palette, fill: _):
                return PNG.convolve(interleaved, dereference: deindexer(palette)) {
                    (c) in .init(c.0, c.1, c.2, c.3)
                }

            case .v1(fill: _, key: nil),
                .v2(fill: _, key: nil),
                .v4(fill: _, key: nil),
                .v8(fill: _, key: nil):
                return PNG.convolve(interleaved, of: UInt8.self, depth: depth) {
                    (c: UInt8, _) in .init(grayscale: c)
                }
            case .v16(fill: _, key: nil):
                return PNG.convolve(interleaved, of: UInt16.self, depth: depth) {
                    (c: UInt8, _) in .init(grayscale: c)
                }
            case .v1(fill: _, key: let key?),
                .v2(fill: _, key: let key?),
                .v4(fill: _, key: let key?),
                .v8(fill: _, key: let key?):
                return PNG.convolve(interleaved, of: UInt8.self, depth: depth) {
                    (c: UInt8, k: UInt8) in .init(grayscale: c, alpha: k == key ? .min : .max)
                }
            case .v16(fill: _, key: let key?):
                return PNG.convolve(interleaved, of: UInt16.self, depth: depth) {
                    (c: UInt8, k: UInt16) in .init(grayscale: c, alpha: k == key ? .min : .max)
                }

            case .va8(fill: _):
                return PNG.convolve(interleaved, of: UInt8.self, depth: depth) {
                    (c: (UInt8, UInt8)) in .init(grayscale: c.0, alpha: c.1)
                }
            case .va16(fill: _):
                return PNG.convolve(interleaved, of: UInt16.self, depth: depth) {
                    (c: (UInt8, UInt8)) in .init(grayscale: c.0, alpha: c.1)
                }

            case .bgr8(palette: _, fill: _, key: nil):
                return PNG.convolve(interleaved, of: UInt8.self, depth: depth) {
                    (c: (UInt8, UInt8, UInt8), _) in .init(c.2, c.1, c.0, .max)
                }
            case .bgr8(palette: _, fill: _, key: let key?):
                return PNG.convolve(interleaved, of: UInt8.self, depth: depth) {
                    (c: (UInt8, UInt8, UInt8), k: (UInt8, UInt8, UInt8)) in
                    .init(c.2, c.1, c.0, k == key ? .min : .max)
                }

            case .rgb8(palette: _, fill: _, key: nil):
                return PNG.convolve(interleaved, of: UInt8.self, depth: depth) {
                    (c: (UInt8, UInt8, UInt8), _) in .init(c.0, c.1, c.2, .max)
                }
            case .rgb16(palette: _, fill: _, key: nil):
                return PNG.convolve(interleaved, of: UInt16.self, depth: depth) {
                    (c: (UInt8, UInt8, UInt8), _) in .init(c.0, c.1, c.2, .max)
                }
            case .rgb8(palette: _, fill: _, key: let key?):
                return PNG.convolve(interleaved, of: UInt8.self, depth: depth) {
                    (c: (UInt8, UInt8, UInt8), k: (UInt8, UInt8, UInt8)) in
                    .init(c.0, c.1, c.2, k == key ? .min : .max)
                }
            case .rgb16(palette: _, fill: _, key: let key?):
                return PNG.convolve(interleaved, of: UInt16.self, depth: depth) {
                    (c: (UInt8, UInt8, UInt8), k: (UInt16, UInt16, UInt16)) in
                    .init(c.0, c.1, c.2, k == key ? .min : .max)
                }

            case .bgra8(palette: _, fill: _):
                return PNG.convolve(interleaved, of: UInt8.self, depth: depth) {
                    (c: (UInt8, UInt8, UInt8, UInt8)) in .init(c.2, c.1, c.0, c.3)
                }

            case .rgba8(palette: _, fill: _):
                return PNG.convolve(interleaved, of: UInt8.self, depth: depth) {
                    (c: (UInt8, UInt8, UInt8, UInt8)) in .init(c.0, c.1, c.2, c.3)
                }
            case .rgba16(palette: _, fill: _):
                return PNG.convolve(interleaved, of: UInt16.self, depth: depth) {
                    (c: (UInt8, UInt8, UInt8, UInt8)) in .init(c.0, c.1, c.2, c.3)
                }
        }
    }

    public static func pack(
        _ pixels: [Self], as format: PNG.Format,
        indexer: ([(r: UInt8, g: UInt8, b: UInt8, a: UInt8)]) -> (Aggregate) -> Int
    ) -> [UInt8] {
        let depth: Int = format.pixel.depth
        switch format
        {
            case .indexed1(let palette, fill: _),
                .indexed2(let palette, fill: _),
                .indexed4(let palette, fill: _),
                .indexed8(let palette, fill: _):
                return PNG.deconvolve(pixels, reference: indexer(palette)) {
                    (c) in (c.red, c.green, c.blue, c.alpha)
                }

            case .v1(fill: _, key: _),
                .v2(fill: _, key: _),
                .v4(fill: _, key: _),
                .v8(fill: _, key: _):
                return PNG.deconvolve(pixels, as: UInt8.self, depth: depth, kernel: \.red)
            case .v16(fill: _, key: _):
                return PNG.deconvolve(pixels, as: UInt16.self, depth: depth, kernel: \.red)

            case .va8(fill: _):
                return PNG.deconvolve(pixels, as: UInt8.self, depth: depth) {
                    (c) in (c.red, c.alpha)
                }
            case .va16(fill: _):
                return PNG.deconvolve(pixels, as: UInt16.self, depth: depth) {
                    (c) in (c.red, c.alpha)
                }

            case .bgr8(palette: _, fill: _, key: _):
                return PNG.deconvolve(pixels, as: UInt8.self, depth: depth) {
                    (c) in (c.blue, c.green, c.red)
                }

            case .rgb8(palette: _, fill: _, key: _):
                return PNG.deconvolve(pixels, as: UInt8.self, depth: depth) {
                    (c) in (c.red, c.green, c.blue)
                }
            case .rgb16(palette: _, fill: _, key: _):
                return PNG.deconvolve(pixels, as: UInt16.self, depth: depth) {
                    (c) in (c.red, c.green, c.blue)
                }

            case .bgra8(palette: _, fill: _):
                return PNG.deconvolve(pixels, as: UInt8.self, depth: depth) {
                    (c) in (c.blue, c.green, c.red, c.alpha)
                }

            case .rgba8(palette: _, fill: _):
                return PNG.deconvolve(pixels, as: UInt8.self, depth: depth) {
                    (c) in (c.red, c.green, c.blue, c.alpha)
                }
            case .rgba16(palette: _, fill: _):
                return PNG.deconvolve(pixels, as: UInt16.self, depth: depth) {
                    (c) in (c.red, c.green, c.blue, c.alpha)
                }
        }
    }
}
