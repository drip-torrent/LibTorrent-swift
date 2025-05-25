# LibTorrent-Swift

A modern Swift wrapper for libtorrent featuring async/await, actors, and full Swift concurrency support.

## Features

- ✅ Modern Swift API with async/await
- ✅ Actor-based thread-safe design
- ✅ Full Swift concurrency support
- ✅ Type-safe error handling
- ✅ Real-time progress monitoring
- ✅ Support for both torrent files and magnet links
- ✅ Session configuration and management
- ✅ Comprehensive statistics

## Requirements

- Swift 6.0+
- macOS 14.0+ / iOS 17.0+
- libtorrent-rasterbar
- Boost libraries

## Installation

### 1. Install Dependencies

```bash
./Scripts/install-dependencies.sh
```

Or manually:

**macOS (Homebrew):**
```bash
brew install libtorrent-rasterbar boost openssl
```

**Linux (apt):**
```bash
sudo apt-get install libtorrent-rasterbar-dev libboost-all-dev libssl-dev
```

### 2. Swift Package Manager

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/LibTorrent-swift.git", from: "1.0.0")
]
```

## Usage

### Basic Example

```swift
import LibTorrentSwift

// Create a session
let session = await TorrentSession()

// Add a torrent from a magnet link
let torrent = try await session.addTorrent(
    magnetLink: "magnet:?xt=urn:btih:...",
    downloadPath: "/path/to/downloads"
)

// Monitor progress
let status = await torrent.getStatus()
print("Progress: \(status.progress * 100)%")
print("Download rate: \(status.downloadRate.formattedBytesPerSecond)")

// Pause/Resume
await torrent.pause()
await torrent.resume()
```

### Advanced Configuration

```swift
let config = SessionConfiguration(
    downloadRateLimit: 1_000_000,  // 1 MB/s
    uploadRateLimit: 500_000,      // 500 KB/s
    maxConnections: 200,
    enableDHT: true,
    enableLSD: true,
    enableUPnP: true
)

let session = await TorrentSession(configuration: config)
```

### Real-time Alerts

```swift
Task {
    for await alert in session.alerts {
        print("Alert: \(alert.message) at \(alert.timestamp)")
    }
}
```

### Session Statistics

```swift
let stats = await session.getStatistics()
print("Total downloaded: \(stats.totalDownload.humanReadableSize)")
print("Active torrents: \(stats.activeTorrents)")
print("Total peers: \(stats.totalPeers)")
```

## API Reference

### TorrentSession

- `init()` - Create a new session with default settings
- `init(configuration:)` - Create a session with custom configuration
- `addTorrent(from:downloadPath:)` - Add torrent from file
- `addTorrent(magnetLink:downloadPath:)` - Add torrent from magnet link
- `removeTorrent(_:deleteFiles:)` - Remove a torrent
- `getAllTorrents()` - Get all torrents
- `pause()` / `resume()` - Pause/resume session
- `getStatistics()` - Get session statistics

### Torrent

- `pause()` / `resume()` - Pause/resume torrent
- `setDownloadLimit(_:)` - Set download speed limit
- `setUploadLimit(_:)` - Set upload speed limit
- `getStatus()` - Get current status
- `getInfo()` - Get torrent information

### Utilities

- `TorrentUtilities.createMagnetLink(infoHash:name:)` - Create magnet link
- `TorrentUtilities.isValidInfoHash(_:)` - Validate info hash
- `TorrentUtilities.humanReadableSize(_:)` - Format bytes
- `TorrentUtilities.calculateETA(totalSize:downloadedSize:downloadRate:)` - Calculate ETA

## Architecture

The package uses a C bridge layer to interface with libtorrent while providing a pure Swift API:

- **C Bridge**: Handles C++ interop with libtorrent
- **Swift Actors**: Ensure thread safety and prevent data races
- **Async/Await**: Modern concurrency for all operations
- **Type Safety**: Strong typing with comprehensive error handling

## Building

```bash
swift build
```

## Testing

```bash
swift test
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

### Dependencies

- libtorrent-rasterbar is licensed under BSD-3-Clause
- Boost libraries are licensed under the Boost Software License

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.