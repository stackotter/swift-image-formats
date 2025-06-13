public struct HSV: BytesConvertible, RGBAConvertible, Hashable, Sendable {
    public static let stride = 3 * MemoryLayout<Double>.stride

    public var hue: Double
    public var saturation: Double
    public var value: Double

    public var rgba: RGBA {
        let hue = hue.truncatingRemainder(dividingBy: 360)
        let sector = Int((hue / 60).rounded(.down))
        let sectorFraction = hue / 60 - Double(sector)
        let p = value * (1 - saturation)
        let q = value * (1 - saturation * sectorFraction)
        let t = value * (1 - saturation * (1 - sectorFraction))

        let rgb: (r: Double, g: Double, b: Double)
        switch sector {
            case 0:
                rgb = (value, t, p)
            case 1:
                rgb = (q, value, p)
            case 2:
                rgb = (p, value, t)
            case 3:
                rgb = (p, q, value)
            case 4:
                rgb = (t, p, value)
            case 5:
                rgb = (value, p, q)
            default:
                fatalError("unreachable?")
        }

        return RGBA(
            UInt8(clamping: Int(rgb.r * 255)),
            UInt8(clamping: Int(rgb.g * 255)),
            UInt8(clamping: Int(rgb.b * 255)),
            255
        )
    }

    public init(_ hue: Double, _ saturation: Double, _ value: Double) {
        self.hue = hue
        self.saturation = saturation
        self.value = value
    }

    public init(from rgba: RGBA) {
        let red = Double(rgba.red) / Double(UInt8.max)
        let green = Double(rgba.green) / Double(UInt8.max)
        let blue = Double(rgba.blue) / Double(UInt8.max)

        let minValue = min(red, min(green, blue))
        let maxValue = max(red, max(green, blue))
        let delta = maxValue - minValue
        value = maxValue

        guard maxValue != 0, minValue != 1, delta != 0 else {
            saturation = 0
            hue = 0
            return
        }

        saturation = delta / maxValue

        if red == maxValue {
            hue = (green - blue) / delta
        } else if green == maxValue {
            hue = 2 + (blue - red) / delta
        } else {
            hue = 4 + (red - green) / delta
        }

        hue *= 60
        if hue < 0 {
            hue += 360
        }
    }

    public func encode(to array: inout [UInt8], startingAt offset: Int) {
        withUnsafeBytes(of: self) { buffer in
            for i in 0..<Self.stride {
                array[offset + i] = buffer[i]
            }
        }
    }

    public static func decode(_ bytes: ArraySlice<UInt8>) -> HSV {
        return bytes.withUnsafeBytes { buffer in
            let doubleBuffer = buffer.assumingMemoryBound(to: Double.self)
            return HSV(
                doubleBuffer[0],
                doubleBuffer[1],
                doubleBuffer[2]
            )
        }
    }
}
