import Foundation
import LibTorrentSwift

@main
struct TorrentExample {
    static func main() async throws {
        print("LibTorrentSwift Example")
        print("======================")
        
        // Initialize session with custom configuration
        let config = SessionConfiguration(
            downloadRateLimit: 0,    // Unlimited
            uploadRateLimit: 0,      // Unlimited
            maxConnections: 200,
            enableDHT: true,
            enableLSD: true,
            enableUPnP: true
        )
        
        let session = await TorrentSession(configuration: config)
        print("✓ Session initialized")
        
        // Monitor alerts in background
        Task {
            for await alert in session.alerts {
                print("📢 Alert: \(alert.message)")
            }
        }
        
        // Example 1: Add torrent from magnet link
        let magnetLink = "magnet:?xt=urn:btih:08ada5a7a6183aae1e09d831df6748d566095a10&dn=Sintel"
        
        do {
            print("\n📥 Adding torrent from magnet link...")
            let torrent = try await session.addTorrent(
                magnetLink: magnetLink,
                downloadPath: "/tmp/downloads"
            )
            
            print("✓ Torrent added successfully")
            
            // Monitor torrent progress
            await monitorTorrent(torrent, duration: 30)
            
            // Get final statistics
            let stats = await session.getStatistics()
            print("\n📊 Session Statistics:")
            print("   Total Download: \(stats.totalDownload.humanReadableSize)")
            print("   Total Upload: \(stats.totalUpload.humanReadableSize)")
            print("   Active Torrents: \(stats.activeTorrents)")
            print("   Total Peers: \(stats.totalPeers)")
            
        } catch {
            print("❌ Error: \(error)")
        }
        
        // Example 2: Add torrent from file
        let torrentFilePath = "/path/to/example.torrent"
        if FileManager.default.fileExists(atPath: torrentFilePath) {
            do {
                let torrentURL = URL(fileURLWithPath: torrentFilePath)
                let torrent = try await session.addTorrent(
                    from: torrentURL,
                    downloadPath: "/tmp/downloads"
                )
                
                print("\n✓ Torrent from file added successfully")
                await monitorTorrent(torrent, duration: 10)
                
            } catch {
                print("❌ Error adding torrent from file: \(error)")
            }
        }
        
        // Pause session
        try await session.pause()
        print("\n⏸ Session paused")
        
        // Resume after 5 seconds
        try await Task.sleep(nanoseconds: 5_000_000_000)
        try await session.resume()
        print("▶️ Session resumed")
        
        // Clean up
        let torrents = await session.getAllTorrents()
        for torrent in torrents {
            try await session.removeTorrent(torrent, deleteFiles: false)
        }
        
        print("\n✓ Example completed")
    }
    
    static func monitorTorrent(_ torrent: Torrent, duration: Int) async {
        print("\n📊 Monitoring torrent for \(duration) seconds...")
        
        let startTime = Date()
        var lastProgress: Float = 0
        
        while Date().timeIntervalSince(startTime) < Double(duration) {
            let status = await torrent.getStatus()
            let info = await torrent.getInfo()
            
            if status.progress != lastProgress {
                lastProgress = status.progress
                
                print("\r", terminator: "")
                print("[\(formatProgressBar(status.progress))] ", terminator: "")
                print("\(Int(status.progress * 100))% ", terminator: "")
                print("↓ \(status.downloadRate.formattedBytesPerSecond) ", terminator: "")
                print("↑ \(status.uploadRate.formattedBytesPerSecond) ", terminator: "")
                print("Peers: \(status.numPeers) ", terminator: "")
                
                if let info = info {
                    print("(\(info.name))", terminator: "")
                }
                
                fflush(stdout)
            }
            
            if status.isFinished {
                print("\n✅ Download completed!")
                break
            }
            
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        }
        
        print() // New line after progress
    }
    
    static func formatProgressBar(_ progress: Float, width: Int = 20) -> String {
        let filled = Int(Float(width) * progress)
        let empty = width - filled
        return String(repeating: "█", count: filled) + String(repeating: "░", count: empty)
    }
}