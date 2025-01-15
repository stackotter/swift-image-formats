import Foundation
import ImageFormats

@main
struct Benchmarks {
    static func main() {
        do {
            let data = try Data(
                contentsOf: URL(
                    fileURLWithPath:
                        "/Users/stackotter/Desktop/Projects/SwiftCrossUI/TestFiles/wide_screenshot.png"
                )
            )

            let start = ProcessInfo.processInfo.systemUptime
            _ = try Image<RGBA>.load(from: Array(data))
            print("elapsed:", ProcessInfo.processInfo.systemUptime - start)
        } catch {
            print("error:", error)
        }
    }
}
