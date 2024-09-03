## swift-image-formats

A cross-platform Swift library for working with various image file formats.

### Supported image formats

- `.png`: Using [tayloraswift/swift-png](https://github.com/tayloraswift/swift-png)
- `.jpeg`: Using [tayloraswift/jpeg](https://github.com/tayloraswift/jpeg)
- `.webp`: Using [webmproject/libwebp](https://github.com/webmproject/libwebp)

In future I'd like to add support for bitmaps, gifs, and heic files.

### Usage

#### Loading image files

There are many different ways to load images. Which one you use will depend on how much
you know about the image that you're loading. In this example we will let `Image` use the
file extension to detect the file format, but you can also just give it bytes and it
will detect the image format from the first few bytes of the file. If you know the
file format up-front, you can use `Image.load(from:as:)`.

```swift
import Foundation
import ImageFormats

let url = URL(fileURLWithPath: "image.png")
let bytes = [UInt8](try Data(contentsOf: url))
let image = Image<RGBA>.load(from: bytes, usingFileExtension: fileExtension)

print("width = \(image.width)")
print("height = \(image.height)")
print("pixel @ (0, 0) = \(image[row: 0][column: 0])")
```

#### Detect file format from magic bytes

```swift
let bytes: [UInt8] = [...]
let format = Image.detectFormat(of: bytes)
```

#### Converting pixel format

```swift
let rgbaImage: Image<RGBA> = ...
let rgbImage = rgbaImage.convert(to: RGB.self)
```

#### Creating a custom pixel format

```swift
struct Grayscale: BytesConvertible, RGBAConvertible {
    static let stride = 1

    var luminosity: UInt8

    var rgba: RGBA {
        RGBA(
            luminosity,
            luminosity,
            luminosity,
            255
        )
    }

    init(_ luminosity: UInt8) {
        self.luminosity = luminosity
    }

    init(from rgba: RGBA) {
        luminosity = (rgba.red * 299 + rgba.green * 587 + rgba.blue * 114) / 1000
    }

    func encode(to slice: inout ArraySlice<UInt8>) {
        slice[slice.startIndex] = luminosity
    }

    static func decode(_ bytes: ArraySlice<UInt8>) -> Self {
        return Self(bytes[bytes.startIndex])
    }
}
```

You can now convert images to grayscale from any format. All conversions
go via `RGBA`.

```swift
let image: Image<RGB> = ...
let grayscale = image.convert(to: Grayscale.self)
```

#### Saving image files

Not yet implemented.
