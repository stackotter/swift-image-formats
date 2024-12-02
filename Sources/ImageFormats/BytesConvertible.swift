public protocol BytesConvertible {
    static var stride: Int { get }

    static func decode(_ bytes: ArraySlice<UInt8>) -> Self

    /// This used to take an `inout ArraySlice<UInt8>`, but unfortunately
    /// that led to serious performance issues. See
    /// [this great Swift Forums thread](https://forums.swift.org/t/solving-the-mutating-slice-cow-problem/35297)
    /// for more information.
    func encode(to array: inout [UInt8], startingAt offset: Int)
}
