func clamp<T: Comparable>(_ value: T, to range: ClosedRange<T>) -> T {
    if value <= range.lowerBound {
        range.lowerBound
    } else if value >= range.upperBound {
        range.upperBound
    } else {
        value
    }
}
