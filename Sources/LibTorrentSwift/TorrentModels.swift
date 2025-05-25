import Foundation
import LibTorrentCxx

public struct TorrentInfo: Sendable {
    public let name: String
    public let totalSize: Int64
    public let pieceLength: Int
    public let infoHash: String
    public let numFiles: Int
    
    init(from cInfo: LTTorrentInfo) {
        self.name = String(cString: cInfo.name!)
        self.totalSize = cInfo.totalSize
        self.pieceLength = Int(cInfo.pieceLength)
        self.infoHash = String(cString: cInfo.infoHash!)
        self.numFiles = Int(cInfo.numFiles)
    }
}

public enum TorrentState: Sendable {
    case checkingFiles
    case downloadingMetadata
    case downloading
    case finished
    case seeding
    case checkingResumeData
    
    init(from cState: LTTorrentState) {
        switch cState {
        case LTStateCheckingFiles:
            self = .checkingFiles
        case LTStateDownloadingMetadata:
            self = .downloadingMetadata
        case LTStateDownloading:
            self = .downloading
        case LTStateFinished:
            self = .finished
        case LTStateSeeding:
            self = .seeding
        case LTStateCheckingResumeData:
            self = .checkingResumeData
        default:
            self = .downloading
        }
    }
}

public struct TorrentStatus: Sendable {
    public let state: TorrentState
    public let progress: Float
    public let downloadRate: Int64
    public let uploadRate: Int64
    public let totalDownload: Int64
    public let totalUpload: Int64
    public let numPeers: Int
    public let numSeeds: Int
    public let isPaused: Bool
    public let isFinished: Bool
    
    init(from cStatus: LTTorrentStatus) {
        self.state = TorrentState(from: cStatus.state)
        self.progress = cStatus.progress
        self.downloadRate = cStatus.downloadRate
        self.uploadRate = cStatus.uploadRate
        self.totalDownload = cStatus.totalDownload
        self.totalUpload = cStatus.totalUpload
        self.numPeers = Int(cStatus.numPeers)
        self.numSeeds = Int(cStatus.numSeeds)
        self.isPaused = cStatus.isPaused
        self.isFinished = cStatus.isFinished
    }
}

public struct SessionConfiguration: Sendable {
    public var downloadRateLimit: Int
    public var uploadRateLimit: Int
    public var maxConnections: Int
    public var maxUploads: Int
    public var listenInterfaces: String
    public var enableDHT: Bool
    public var enableLSD: Bool
    public var enableUPnP: Bool
    public var enableNATPMP: Bool
    
    public init(
        downloadRateLimit: Int = 0,
        uploadRateLimit: Int = 0,
        maxConnections: Int = 200,
        maxUploads: Int = -1,
        listenInterfaces: String = "0.0.0.0:6881",
        enableDHT: Bool = true,
        enableLSD: Bool = true,
        enableUPnP: Bool = true,
        enableNATPMP: Bool = true
    ) {
        self.downloadRateLimit = downloadRateLimit
        self.uploadRateLimit = uploadRateLimit
        self.maxConnections = maxConnections
        self.maxUploads = maxUploads
        self.listenInterfaces = listenInterfaces
        self.enableDHT = enableDHT
        self.enableLSD = enableLSD
        self.enableUPnP = enableUPnP
        self.enableNATPMP = enableNATPMP
    }
    
    func toCSettings() -> LTSessionSettings {
        return listenInterfaces.withCString { interfaces in
            LTSessionSettings(
                downloadRateLimit: Int32(downloadRateLimit),
                uploadRateLimit: Int32(uploadRateLimit),
                maxConnections: Int32(maxConnections),
                maxUploads: Int32(maxUploads),
                listenInterfaces: interfaces,
                enableDht: enableDHT,
                enableLsd: enableLSD,
                enableUpnp: enableUPnP,
                enableNatpmp: enableNATPMP
            )
        }
    }
}

public struct TorrentAlert: Sendable {
    public let message: String
    public let timestamp: Date
    
    public init(message: String) {
        self.message = message
        self.timestamp = Date()
    }
}