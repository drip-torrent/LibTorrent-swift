import Foundation
import LibTorrentCxx

// Session handle wrapper to make it Sendable by using Int
internal struct SessionHandleWrapper: @unchecked Sendable {
    let ptrValue: Int
    
    init(ptr: UnsafeMutableRawPointer) {
        self.ptrValue = Int(bitPattern: ptr)
    }
    
    var ptr: UnsafeMutableRawPointer {
        UnsafeMutableRawPointer(bitPattern: ptrValue)!
    }
}

public actor TorrentSession {
    private let sessionWrapper: SessionHandleWrapper
    private var torrents: [UUID: Torrent] = [:]
    private var alertContinuation: AsyncStream<TorrentAlert>.Continuation?
    private var alertProcessingTask: Task<Void, Never>?
    
    public var alerts: AsyncStream<TorrentAlert> {
        AsyncStream { continuation in
            self.alertContinuation = continuation
        }
    }
    
    public init() async {
        let handle = LTSessionCreate()!
        self.sessionWrapper = SessionHandleWrapper(ptr: handle)
        setupAlertProcessing()
    }
    
    public init(configuration: SessionConfiguration) async {
        var cSettings = configuration.toCSettings()
        let handle = LTSessionCreateWithSettings(&cSettings)!
        self.sessionWrapper = SessionHandleWrapper(ptr: handle)
        setupAlertProcessing()
    }
    
    deinit {
        alertProcessingTask?.cancel()
        alertContinuation?.finish()
        // Capture the pointer value to avoid accessing self in the Task
        let sessionPtrValue = sessionWrapper.ptrValue
        Task { @Sendable in
            if let ptr = UnsafeMutableRawPointer(bitPattern: sessionPtrValue) {
                LTSessionDestroy(ptr)
            }
        }
    }
    
    private func setupAlertProcessing() {
        // Create a bridge to handle C callbacks
        let bridge = AlertCallbackBridge { [weak self] message in
            Task { [weak self] in
                await self?.handleAlert(message)
            }
        }
        
        // Keep the bridge alive
        alertProcessingTask = Task {
            let bridgePtr = Unmanaged.passUnretained(bridge).toOpaque()
            LTSessionSetAlertCallback(sessionWrapper.ptr, { message, context in
                guard let message = message, let context = context else { return }
                let bridge = Unmanaged<AlertCallbackBridge>.fromOpaque(context).takeUnretainedValue()
                bridge.handleAlert(String(cString: message))
            }, bridgePtr)
            
            while !Task.isCancelled {
                LTSessionProcessAlerts(sessionWrapper.ptr)
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            }
        }
    }
    
    private func handleAlert(_ message: String) {
        let alert = TorrentAlert(message: message)
        alertContinuation?.yield(alert)
    }
    
    public func updateConfiguration(_ configuration: SessionConfiguration) async throws {
        var cSettings = configuration.toCSettings()
        LTSessionApplySettings(sessionWrapper.ptr, &cSettings)
    }
    
    public func addTorrent(from fileURL: URL, downloadPath: String) async throws -> Torrent {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            throw TorrentError.invalidTorrentFile
        }
        
        // Capture values to avoid data races
        let torrentPath = fileURL.path
        let sessionPtrValue = sessionWrapper.ptrValue
        
        let handlePtrValue: Int? = await Task.detached {
            guard let sessionPtr = UnsafeMutableRawPointer(bitPattern: sessionPtrValue) else { return nil }
            let result = torrentPath.withCString { torrentPathPtr in
                downloadPath.withCString { savePathPtr in
                    return LTSessionAddTorrent(sessionPtr, torrentPathPtr, savePathPtr)
                }
            }
            return result.map { Int(bitPattern: $0) }
        }.value
        
        guard let handlePtrValue = handlePtrValue,
              let handle = UnsafeMutableRawPointer(bitPattern: handlePtrValue) else {
            throw TorrentError.invalidTorrentFile
        }
        
        let torrent = Torrent(handle: handle, session: self)
        let torrentId = await torrent.identifier
        torrents[torrentId] = torrent
        return torrent
    }
    
    public func addTorrent(magnetLink: String, downloadPath: String) async throws -> Torrent {
        // Capture values to avoid data races
        let sessionPtrValue = sessionWrapper.ptrValue
        
        let handlePtrValue: Int? = await Task.detached {
            guard let sessionPtr = UnsafeMutableRawPointer(bitPattern: sessionPtrValue) else { return nil }
            let result = magnetLink.withCString { magnetPtr in
                downloadPath.withCString { savePathPtr in
                    return LTSessionAddMagnetUri(sessionPtr, magnetPtr, savePathPtr)
                }
            }
            return result.map { Int(bitPattern: $0) }
        }.value
        
        guard let handlePtrValue = handlePtrValue,
              let handle = UnsafeMutableRawPointer(bitPattern: handlePtrValue) else {
            throw TorrentError.invalidMagnetLink
        }
        
        let torrent = Torrent(handle: handle, session: self)
        let torrentId = await torrent.identifier
        torrents[torrentId] = torrent
        return torrent
    }
    
    public func removeTorrent(_ torrent: Torrent, deleteFiles: Bool = false) async throws {
        let torrentId = await torrent.identifier
        guard torrents[torrentId] != nil else {
            throw TorrentError.torrentNotFound
        }
        
        let handleWrapper = await torrent.getHandleWrapper()
        LTSessionRemoveTorrent(sessionWrapper.ptr, handleWrapper.ptr, deleteFiles)
        torrents.removeValue(forKey: torrentId)
    }
    
    public func getAllTorrents() async -> [Torrent] {
        Array(torrents.values)
    }
    
    public func getTorrent(by id: UUID) async -> Torrent? {
        torrents[id]
    }
    
    public func pause() async throws {
        LTSessionPause(sessionWrapper.ptr)
    }
    
    public func resume() async throws {
        LTSessionResume(sessionWrapper.ptr)
    }
    
    public func isPaused() async throws -> Bool {
        LTSessionIsPaused(sessionWrapper.ptr)
    }
}

// Alert callback bridge
private class AlertCallbackBridge {
    let callback: (String) -> Void
    
    init(callback: @escaping (String) -> Void) {
        self.callback = callback
    }
    
    func handleAlert(_ message: String) {
        callback(message)
    }
}

// MARK: - Statistics
extension TorrentSession {
    public struct SessionStatistics: Sendable {
        public let totalDownload: Int64
        public let totalUpload: Int64
        public let activeTorrents: Int
        public let pausedTorrents: Int
        public let totalPeers: Int
        public let totalSeeds: Int
    }
    
    public func getStatistics() async -> SessionStatistics {
        var totalDownload: Int64 = 0
        var totalUpload: Int64 = 0
        var activeTorrents = 0
        var pausedTorrents = 0
        var totalPeers = 0
        var totalSeeds = 0
        
        for torrent in torrents.values {
            let status = await torrent.getStatus()
            totalDownload += status.totalDownload
            totalUpload += status.totalUpload
            totalPeers += status.numPeers
            totalSeeds += status.numSeeds
            
            if status.isPaused {
                pausedTorrents += 1
            } else {
                activeTorrents += 1
            }
        }
        
        return SessionStatistics(
            totalDownload: totalDownload,
            totalUpload: totalUpload,
            activeTorrents: activeTorrents,
            pausedTorrents: pausedTorrents,
            totalPeers: totalPeers,
            totalSeeds: totalSeeds
        )
    }
}