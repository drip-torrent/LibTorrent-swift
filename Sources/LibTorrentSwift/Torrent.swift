import Foundation
import LibTorrentCxx

// Make handle sendable
internal struct TorrentHandleWrapper: @unchecked Sendable {
    let ptr: UnsafeMutableRawPointer
}

public actor Torrent {
    private let handle: UnsafeMutableRawPointer
    private let id: UUID = UUID()
    private weak var session: TorrentSession?
    
    public var identifier: UUID { id }
    
    init(handle: UnsafeMutableRawPointer, session: TorrentSession) {
        self.handle = handle
        self.session = session
    }
    
    deinit {
        // Handle cleanup is managed by the session
    }
    
    public func pause() async {
        LTTorrentPause(handle)
    }
    
    public func resume() async {
        LTTorrentResume(handle)
    }
    
    public func setDownloadLimit(_ bytesPerSecond: Int) async {
        LTTorrentSetDownloadLimit(handle, Int32(bytesPerSecond))
    }
    
    public func setUploadLimit(_ bytesPerSecond: Int) async {
        LTTorrentSetUploadLimit(handle, Int32(bytesPerSecond))
    }
    
    public func getStatus() async -> TorrentStatus {
        let cStatus = LTTorrentGetStatus(handle)
        return TorrentStatus(from: cStatus)
    }
    
    public func getInfo() async -> TorrentInfo? {
        let cInfo = LTTorrentGetInfo(handle)
        guard let name = cInfo.name else { return nil }
        guard !String(cString: name).isEmpty else { return nil }
        return TorrentInfo(from: cInfo)
    }
    
    public func isValid() -> Bool {
        LTTorrentIsValid(handle)
    }
    
    internal func getHandleWrapper() -> TorrentHandleWrapper {
        TorrentHandleWrapper(ptr: handle)
    }
}