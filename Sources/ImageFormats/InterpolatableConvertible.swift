/// A value that can be converted to and from an interpolatable representation,
/// often in a lossy manner.
public protocol InterpolatableConvertible {
    associatedtype InterpolatableRepresentation: Interpolatable

    init(from interpolatable: InterpolatableRepresentation)

    var interpolatable: InterpolatableRepresentation { get }
}
