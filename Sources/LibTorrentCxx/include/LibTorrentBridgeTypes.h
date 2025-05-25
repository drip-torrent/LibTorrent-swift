#ifndef LIBTORRENT_BRIDGE_TYPES_H
#define LIBTORRENT_BRIDGE_TYPES_H

#include <stdint.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef void* LTSessionHandle;
typedef void* LTTorrentHandle;

typedef struct {
    const char* name;
    int64_t totalSize;
    int pieceLength;
    const char* infoHash;
    int numFiles;
} LTTorrentInfo;

typedef enum {
    LTStateCheckingFiles = 0,
    LTStateDownloadingMetadata = 1,
    LTStateDownloading = 2,
    LTStateFinished = 3,
    LTStateSeeding = 4,
    LTStateCheckingResumeData = 5
} LTTorrentState;

typedef struct {
    LTTorrentState state;
    float progress;
    int64_t downloadRate;
    int64_t uploadRate;
    int64_t totalDownload;
    int64_t totalUpload;
    int numPeers;
    int numSeeds;
    bool isPaused;
    bool isFinished;
} LTTorrentStatus;

typedef struct {
    int downloadRateLimit;
    int uploadRateLimit;
    int maxConnections;
    int maxUploads;
    const char* listenInterfaces;
    bool enableDht;
    bool enableLsd;
    bool enableUpnp;
    bool enableNatpmp;
} LTSessionSettings;

typedef void (*LTAlertCallback)(const char* message, void* context);

// Session functions
LTSessionHandle LTSessionCreate(void);
LTSessionHandle LTSessionCreateWithSettings(const LTSessionSettings* settings);
void LTSessionDestroy(LTSessionHandle session);
void LTSessionApplySettings(LTSessionHandle session, const LTSessionSettings* settings);
LTTorrentHandle LTSessionAddTorrent(LTSessionHandle session, const char* torrentPath, const char* savePath);
LTTorrentHandle LTSessionAddMagnetUri(LTSessionHandle session, const char* magnetUri, const char* savePath);
void LTSessionRemoveTorrent(LTSessionHandle session, LTTorrentHandle handle, bool deleteFiles);
void LTSessionPause(LTSessionHandle session);
void LTSessionResume(LTSessionHandle session);
bool LTSessionIsPaused(LTSessionHandle session);
void LTSessionSetAlertCallback(LTSessionHandle session, LTAlertCallback callback, void* context);
void LTSessionProcessAlerts(LTSessionHandle session);

// Torrent functions
void LTTorrentPause(LTTorrentHandle handle);
void LTTorrentResume(LTTorrentHandle handle);
void LTTorrentSetDownloadLimit(LTTorrentHandle handle, int limit);
void LTTorrentSetUploadLimit(LTTorrentHandle handle, int limit);
LTTorrentStatus LTTorrentGetStatus(LTTorrentHandle handle);
LTTorrentInfo LTTorrentGetInfo(LTTorrentHandle handle);
bool LTTorrentIsValid(LTTorrentHandle handle);

// Utility functions
char* LTCreateMagnetUri(const char* infoHash, const char* name);
bool LTIsValidInfoHash(const char* infoHash);
char* LTHumanReadableSize(int64_t bytes);
void LTFreeString(char* str);

#ifdef __cplusplus
}
#endif

#endif