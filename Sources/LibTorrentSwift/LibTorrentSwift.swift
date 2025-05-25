// The Swift Programming Language
// https://docs.swift.org/swift-book

/// LibTorrentSwift - A modern Swift wrapper for libtorrent
/// 
/// This package provides a Swift-friendly API for the libtorrent library,
/// featuring modern Swift concurrency with async/await and actors for
/// thread-safe torrent management.
///
/// ## Usage Example:
/// ```swift
/// let session = await TorrentSession()
/// let torrent = try await session.addTorrent(from: torrentFileURL, downloadPath: "/Downloads")
/// let status = await torrent.getStatus()
/// print("Progress: \(status.progress * 100)%")
/// ```

@_exported import LibTorrentCxx

// Re-export all public types
public typealias LibTorrentSession = TorrentSession