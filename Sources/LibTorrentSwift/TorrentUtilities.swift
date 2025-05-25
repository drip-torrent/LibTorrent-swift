import Foundation
import LibTorrentCxx

public enum TorrentUtilities {
    
    public static func createMagnetLink(infoHash: String, name: String? = nil) -> String? {
        guard isValidInfoHash(infoHash) else { return nil }
        
        let magnetPtr = infoHash.withCString { hash in
            if let name = name {
                return name.withCString { nameStr in
                    LTCreateMagnetUri(hash, nameStr)
                }
            } else {
                return LTCreateMagnetUri(hash, nil)
            }
        }
        
        guard let magnetPtr = magnetPtr else { return nil }
        let result = String(cString: magnetPtr)
        LTFreeString(magnetPtr)
        return result
    }
    
    public static func isValidInfoHash(_ infoHash: String) -> Bool {
        return infoHash.withCString { hash in
            LTIsValidInfoHash(hash)
        }
    }
    
    public static func humanReadableSize(_ bytes: Int64) -> String {
        guard let sizePtr = LTHumanReadableSize(bytes) else {
            return "\(bytes) B"
        }
        let result = String(cString: sizePtr)
        LTFreeString(sizePtr)
        return result
    }
    
    public static func calculateETA(totalSize: Int64, downloadedSize: Int64, downloadRate: Int64) -> TimeInterval? {
        guard downloadRate > 0 else { return nil }
        
        let remainingBytes = totalSize - downloadedSize
        guard remainingBytes > 0 else { return 0 }
        
        return TimeInterval(remainingBytes) / TimeInterval(downloadRate)
    }
}

// MARK: - Formatting Extensions
public extension TimeInterval {
    var formattedDuration: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        formatter.maximumUnitCount = 2
        return formatter.string(from: self) ?? "0s"
    }
}

public extension Int64 {
    var humanReadableSize: String {
        TorrentUtilities.humanReadableSize(self)
    }
    
    var formattedBytesPerSecond: String {
        "\(self.humanReadableSize)/s"
    }
}