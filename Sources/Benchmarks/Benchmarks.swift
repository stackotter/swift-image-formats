import Foundation
import ImageFormats

@main
struct Benchmarks {
    static func main() {
        do {
            let data = try Data(
                contentsOf: URL(fileURLWithPath: "/Users/stackotter/Desktop/wide_screenshot.png")
            )

            let start = CFAbsoluteTimeGetCurrent()
            _ = try Image<RGBA>.load(from: Array(data))
            print("elapsed:", CFAbsoluteTimeGetCurrent() - start)
        } catch {
            print("error:", error)
        }
    }
}
