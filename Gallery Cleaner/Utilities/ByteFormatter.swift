import Foundation

struct ByteFormatter {
    private static let formatter: ByteCountFormatter = {
        let bcf = ByteCountFormatter()
        bcf.allowedUnits = [.useBytes, .useKB, .useMB, .useGB]
        bcf.countStyle = .file
        bcf.includesUnit = true
        return bcf
    }()
    
    static func format(_ bytes: Int64) -> String {
        return formatter.string(fromByteCount: bytes)
    }
}
