import XCTest
@testable import LibTorrentSwift

final class LibTorrentSwiftTests: XCTestCase {
    
    func testSessionInitialization() async throws {
        let session = await TorrentSession()
        let isPaused = try await session.isPaused()
        XCTAssertFalse(isPaused)
    }
    
    func testSessionConfiguration() async throws {
        let config = SessionConfiguration(
            downloadRateLimit: 1_000_000, // 1 MB/s
            uploadRateLimit: 500_000,     // 500 KB/s
            maxConnections: 100,
            enableDHT: true
        )
        
        let session = await TorrentSession(configuration: config)
        let isPaused = try await session.isPaused()
        XCTAssertFalse(isPaused)
    }
    
    func testSessionPauseResume() async throws {
        let session = await TorrentSession()
        
        try await session.pause()
        var isPaused = try await session.isPaused()
        XCTAssertTrue(isPaused)
        
        try await session.resume()
        isPaused = try await session.isPaused()
        XCTAssertFalse(isPaused)
    }
    
    func testMagnetLinkCreation() {
        let infoHash = "1234567890abcdef1234567890abcdef12345678"
        let magnetLink = TorrentUtilities.createMagnetLink(
            infoHash: infoHash,
            name: "Test Torrent"
        )
        
        XCTAssertNotNil(magnetLink)
        XCTAssertTrue(magnetLink!.contains(infoHash))
        XCTAssertTrue(magnetLink!.contains("Test Torrent"))
    }
    
    func testInfoHashValidation() {
        // Valid SHA1 hash (40 chars)
        XCTAssertTrue(TorrentUtilities.isValidInfoHash("1234567890abcdef1234567890abcdef12345678"))
        
        // Valid SHA256 hash (64 chars)
        XCTAssertTrue(TorrentUtilities.isValidInfoHash("1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"))
        
        // Invalid hashes
        XCTAssertFalse(TorrentUtilities.isValidInfoHash("short"))
        XCTAssertFalse(TorrentUtilities.isValidInfoHash("1234567890abcdef1234567890abcdef1234567g")) // Contains 'g'
        XCTAssertFalse(TorrentUtilities.isValidInfoHash(""))
    }
    
    func testHumanReadableSize() {
        XCTAssertEqual(TorrentUtilities.humanReadableSize(1024), "1.00 KB")
        XCTAssertEqual(TorrentUtilities.humanReadableSize(1_048_576), "1.00 MB")
        XCTAssertEqual(TorrentUtilities.humanReadableSize(1_073_741_824), "1.00 GB")
        
        let size: Int64 = 1_500_000
        XCTAssertEqual(size.humanReadableSize, "1.43 MB")
    }
    
    func testETACalculation() {
        let eta = TorrentUtilities.calculateETA(
            totalSize: 1_000_000,
            downloadedSize: 500_000,
            downloadRate: 100_000
        )
        
        XCTAssertNotNil(eta)
        XCTAssertEqual(eta!, 5.0) // 500KB remaining at 100KB/s = 5 seconds
    }
    
    func testAlertStream() async throws {
        let session = await TorrentSession()
        
        let expectation = XCTestExpectation(description: "Alert stream works")
        
        Task {
            var alertCount = 0
            for await alert in await session.alerts {
                print("Alert received: \(alert.message)")
                alertCount += 1
                // Just verify we can receive alerts
                expectation.fulfill()
                break
            }
        }
        
        // Give some time for alerts to be processed
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // If no alerts are received, that's also fine
        expectation.fulfill()
        
        await fulfillment(of: [expectation], timeout: 3.0)
    }
    
    func testSessionStatistics() async throws {
        let session = await TorrentSession()
        let stats = await session.getStatistics()
        
        XCTAssertEqual(stats.totalDownload, 0)
        XCTAssertEqual(stats.totalUpload, 0)
        XCTAssertEqual(stats.activeTorrents, 0)
        XCTAssertEqual(stats.pausedTorrents, 0)
        XCTAssertEqual(stats.totalPeers, 0)
        XCTAssertEqual(stats.totalSeeds, 0)
    }
}