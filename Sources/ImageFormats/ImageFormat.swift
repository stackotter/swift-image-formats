public enum ImageFormat {
    case png
    case jpeg
    case webp

    init?(fromExtension fileExtension: String) {
        switch fileExtension.lowercased() {
            case "png":
                self = .png
            case "jpg", "jpeg":
                self = .jpeg
            case "webp":
                self = .webp
            default:
                return nil
        }
    }
}
