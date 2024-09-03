import Foundation
import XCTest

@testable import ImageFormats

final class ImageFormatsTests: XCTestCase {
    func loadBytes(path: String) throws -> [UInt8] {
        let file = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent(path)
        let data = try Data(contentsOf: file)
        return Array(data)
    }

    func testPNGLoading() throws {
        let bytes = try loadBytes(path: "test.png")
        let image = try Image.loadPNG(from: bytes)
        XCTAssertEqual(image[row: 0][column: 0], RGBA(2, 1, 0, 255))
        XCTAssertEqual(image[row: 9][column: 9], RGBA(223, 223, 12, 255))
    }

    func testWebPLoading() throws {
        let bytes = try loadBytes(path: "test.webp")
        let image = try Image.loadWebP(from: bytes)
        XCTAssertEqual(image[row: 0][column: 0], RGBA(2, 1, 0, 255))
        XCTAssertEqual(image[row: 9][column: 9], RGBA(223, 223, 12, 255))
    }

    func testJPEGLoading() throws {
        let bytes = try loadBytes(path: "test.jpg")
        let image = try Image.loadJPEG(from: bytes)
        XCTAssertEqual(image[row: 0][column: 0], RGB(5, 1, 0))
        XCTAssertEqual(image[row: 9][column: 9], RGB(225, 221, 21))
    }

    func testDetectedPNGLoading() throws {
        let bytes = try loadBytes(path: "test.png")
        let image = try Image<RGBA>.load(from: bytes)
        XCTAssertEqual(image[row: 0][column: 0], RGBA(2, 1, 0, 255))
        XCTAssertEqual(image[row: 9][column: 9], RGBA(223, 223, 12, 255))
    }

    func testDetectedWebPLoading() throws {
        let bytes = try loadBytes(path: "test.webp")
        let image = try Image<RGBA>.load(from: bytes)
        XCTAssertEqual(image[row: 0][column: 0], RGBA(2, 1, 0, 255))
        XCTAssertEqual(image[row: 9][column: 9], RGBA(223, 223, 12, 255))
    }

    func testDetectedJPEGLoading() throws {
        let bytes = try loadBytes(path: "test.jpg")
        let image = try Image<RGB>.load(from: bytes)
        XCTAssertEqual(image[row: 0][column: 0], RGB(5, 1, 0))
        XCTAssertEqual(image[row: 9][column: 9], RGB(225, 221, 21))
    }

    func testRGBAToRGB() {
        let rgba = Image<RGBA>(
            width: 2,
            height: 2,
            data: [
                1, 2, 3, 4,
                5, 6, 7, 8,
                9, 10, 11, 12,
                13, 14, 15, 16,
            ]
        )
        let rgb = rgba.convert(to: RGB.self)
        for (rgbaPixel, rgbPixel) in zip(rgba.pixels, rgb.pixels) {
            XCTAssertEqual(rgbaPixel.rgb, rgbPixel)
        }
    }

    func testRGBToRGBA() {
        let rgb = Image<RGB>(
            width: 2,
            height: 2,
            data: [
                1, 2, 3,
                4, 5, 6,
                7, 8, 9,
                10, 11, 12,
            ]
        )
        let rgba = rgb.convert(to: RGBA.self)
        for (rgbPixel, rgbaPixel) in zip(rgb.pixels, rgba.pixels) {
            XCTAssertEqual(rgbPixel.rgba, rgbaPixel)
        }
    }
}
