public protocol BytesConvertible {
    static var stride: Int { get }
    static func decode(_ bytes: ArraySlice<UInt8>) -> Self
    func encode(to slice: inout ArraySlice<UInt8>)
}
