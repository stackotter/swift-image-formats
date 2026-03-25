import Foundation

extension Image where Pixel: InterpolatableConvertible {
    public func lanczosResample(
        toWidth targetWidth: Int,
        height targetHeight: Int,
        radius: Int = 3
    ) -> Self {
        var pixels: [Pixel] = []
        for y in 0..<targetHeight {
            for x in 0..<targetWidth {
                let pixel = lanczosInterpolate(
                    atX: Double(x) / Double(targetWidth - 1) * Double(width),
                    y: Double(y) / Double(targetHeight - 1) * Double(height),
                    radius: radius
                )
                pixels.append(pixel)
            }
        }
        return Self(width: targetWidth, height: targetHeight, pixels: pixels)
    }

    /// Linearly downscales the image using naive pixel averaging (no weighting).
    public func linearlyDownscale(
        toWidth targetWidth: Int,
        height targetHeight: Int
    ) -> Self {
        precondition(targetWidth <= width)
        precondition(targetHeight <= height)

        func computeSourcePosition(x: Int, y: Int) -> (Int, Int) {
            let sourceX = Double(x) * Double(width) / Double(targetWidth)
            let sourceY = Double(y) * Double(height) / Double(targetHeight)
            let originX = Int(sourceX.rounded(.towardZero))
            let originY = Int(sourceY.rounded(.towardZero))
            return (
                min(originX, width),
                min(originY, height)
            )
        }

        var pixels: [Pixel] = []
        for y in 0..<targetHeight {
            for x in 0..<targetWidth {
                let (sourceX, sourceY) = computeSourcePosition(x: x, y: y)
                let (endSourceX, endSourceY) = computeSourcePosition(x: x + 1, y: y + 1)
                let bucketWidth = endSourceX - sourceX
                let bucketHeight = endSourceY - sourceY
                var accumulated = Pixel.InterpolatableRepresentation.zero
                for innerY in sourceY..<endSourceY {
                    for innerX in sourceX..<endSourceX {
                        accumulated += self[row: innerY][column: innerX].interpolatable
                    }
                }
                accumulated = accumulated * (1 / Double(bucketWidth * bucketHeight))
                pixels.append(Pixel(from: accumulated))
            }
        }
        return Self(width: targetWidth, height: targetHeight, pixels: pixels)
    }

    func lanczosInterpolate(atX x: Double, y: Double, radius: Int) -> Pixel {
        let xRange = lanczosRange(around: x, radius: radius)
        let yRange = lanczosRange(around: y, radius: radius)

        var value = Pixel.InterpolatableRepresentation.zero
        for kernelY in yRange {
            for kernelX in xRange {
                let clampedX = clamp(kernelX, to: 0...(width - 1))
                let clampedY = clamp(kernelY, to: 0...(height - 1))
                let kernelValue = lanczosKernel(
                    atX: Double(kernelX) - x,
                    y: Double(kernelY) - y,
                    radius: radius
                )
                value += self[row: clampedY][column: clampedX].interpolatable * kernelValue
            }
        }
        return Pixel(from: value)
    }

    func lanczosKernel(atX x: Double, y: Double, radius: Int) -> Double {
        lanczosKernel(at: x, radius: radius) * lanczosKernel(at: y, radius: radius)
    }

    func lanczosKernel(at value: Double, radius: Int) -> Double {
        if value == 0 {
            return 1
        } else if Double(-radius) <= value && value < Double(radius) {
            let piValue = Double.pi * value
            let denominator = piValue * piValue
            return Double(radius) * sin(piValue) * sin(piValue / Double(radius)) / denominator
        } else {
            return 0
        }
    }

    func lanczosRange(around value: Double, radius: Int) -> ClosedRange<Int> {
        (Int(floor(value)) - radius + 1)...(Int(floor(value)) + radius)
    }
}
