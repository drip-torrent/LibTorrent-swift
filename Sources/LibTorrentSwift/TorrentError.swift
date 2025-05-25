import Foundation

public enum TorrentError: LocalizedError {
    case invalidTorrentFile
    case invalidMagnetLink
    case invalidInfoHash
    case torrentNotFound
    case sessionNotInitialized
    case fileSystemError(String)
    case networkError(String)
    case invalidConfiguration
    case torrentAlreadyExists
    
    public var errorDescription: String? {
        switch self {
        case .invalidTorrentFile:
            return "Invalid torrent file"
        case .invalidMagnetLink:
            return "Invalid magnet link"
        case .invalidInfoHash:
            return "Invalid info hash"
        case .torrentNotFound:
            return "Torrent not found"
        case .sessionNotInitialized:
            return "Session not initialized"
        case .fileSystemError(let message):
            return "File system error: \(message)"
        case .networkError(let message):
            return "Network error: \(message)"
        case .invalidConfiguration:
            return "Invalid configuration"
        case .torrentAlreadyExists:
            return "Torrent already exists in session"
        }
    }
}