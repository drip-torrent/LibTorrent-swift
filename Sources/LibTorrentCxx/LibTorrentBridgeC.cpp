#include "LibTorrentBridgeTypes.h"
#include <libtorrent/session.hpp>
#include <libtorrent/add_torrent_params.hpp>
#include <libtorrent/torrent_handle.hpp>
#include <libtorrent/torrent_info.hpp>
#include <libtorrent/torrent_status.hpp>
#include <libtorrent/alert_types.hpp>
#include <libtorrent/magnet_uri.hpp>
#include <libtorrent/settings_pack.hpp>
#include <libtorrent/hex.hpp>
#include <memory>
#include <vector>
#include <string>
#include <sstream>
#include <iomanip>
#include <cstring>

namespace lt = libtorrent;

struct LTSession {
    lt::session session;
    std::vector<std::unique_ptr<lt::torrent_handle>> handles;
    LTAlertCallback alertCallback = nullptr;
    void* alertContext = nullptr;
};

struct LTTorrent {
    lt::torrent_handle* handle;
    LTSession* session;
};

// Helper to copy strings
static char* copyString(const std::string& str) {
    char* result = new char[str.length() + 1];
    std::strcpy(result, str.c_str());
    return result;
}

// Session functions
LTSessionHandle LTSessionCreate(void) {
    auto session = new LTSession();
    
    lt::settings_pack settings;
    settings.set_int(lt::settings_pack::alert_mask, 
        lt::alert_category::error | 
        lt::alert_category::status | 
        lt::alert_category::storage);
    session->session.apply_settings(settings);
    
    return session;
}

LTSessionHandle LTSessionCreateWithSettings(const LTSessionSettings* settings) {
    auto session = new LTSession();
    LTSessionApplySettings(session, settings);
    return session;
}

void LTSessionDestroy(LTSessionHandle session) {
    delete static_cast<LTSession*>(session);
}

void LTSessionApplySettings(LTSessionHandle sessionHandle, const LTSessionSettings* settings) {
    auto session = static_cast<LTSession*>(sessionHandle);
    
    lt::settings_pack pack;
    pack.set_int(lt::settings_pack::download_rate_limit, settings->downloadRateLimit);
    pack.set_int(lt::settings_pack::upload_rate_limit, settings->uploadRateLimit);
    pack.set_int(lt::settings_pack::connections_limit, settings->maxConnections);
    pack.set_int(lt::settings_pack::unchoke_slots_limit, settings->maxUploads);
    pack.set_str(lt::settings_pack::listen_interfaces, settings->listenInterfaces);
    pack.set_bool(lt::settings_pack::enable_dht, settings->enableDht);
    pack.set_bool(lt::settings_pack::enable_lsd, settings->enableLsd);
    pack.set_bool(lt::settings_pack::enable_upnp, settings->enableUpnp);
    pack.set_bool(lt::settings_pack::enable_natpmp, settings->enableNatpmp);
    
    pack.set_int(lt::settings_pack::alert_mask, 
        lt::alert_category::error | 
        lt::alert_category::status | 
        lt::alert_category::storage);
    
    session->session.apply_settings(pack);
}

LTTorrentHandle LTSessionAddTorrent(LTSessionHandle sessionHandle, const char* torrentPath, const char* savePath) {
    auto session = static_cast<LTSession*>(sessionHandle);
    
    lt::add_torrent_params params;
    params.save_path = savePath;
    
    lt::error_code ec;
    params.ti = std::make_shared<lt::torrent_info>(torrentPath, ec);
    if (ec) {
        return nullptr;
    }
    
    auto handle = session->session.add_torrent(params, ec);
    if (ec) {
        return nullptr;
    }
    
    auto torrentHandle = std::make_unique<lt::torrent_handle>(handle);
    auto torrent = new LTTorrent{torrentHandle.get(), session};
    session->handles.push_back(std::move(torrentHandle));
    
    return torrent;
}

LTTorrentHandle LTSessionAddMagnetUri(LTSessionHandle sessionHandle, const char* magnetUri, const char* savePath) {
    auto session = static_cast<LTSession*>(sessionHandle);
    
    lt::error_code ec;
    auto params = lt::parse_magnet_uri(magnetUri, ec);
    if (ec) {
        return nullptr;
    }
    
    params.save_path = savePath;
    
    auto handle = session->session.add_torrent(params, ec);
    if (ec) {
        return nullptr;
    }
    
    auto torrentHandle = std::make_unique<lt::torrent_handle>(handle);
    auto torrent = new LTTorrent{torrentHandle.get(), session};
    session->handles.push_back(std::move(torrentHandle));
    
    return torrent;
}

void LTSessionRemoveTorrent(LTSessionHandle sessionHandle, LTTorrentHandle torrentHandle, bool deleteFiles) {
    auto session = static_cast<LTSession*>(sessionHandle);
    auto torrent = static_cast<LTTorrent*>(torrentHandle);
    
    if (!torrent || !torrent->handle) return;
    
    lt::remove_flags_t flags = {};
    if (deleteFiles) {
        flags = lt::session::delete_files;
    }
    
    session->session.remove_torrent(*torrent->handle, flags);
    
    // Find and remove from handles vector
    auto it = std::find_if(session->handles.begin(), session->handles.end(),
        [torrent](const std::unique_ptr<lt::torrent_handle>& h) {
            return h.get() == torrent->handle;
        });
    
    if (it != session->handles.end()) {
        session->handles.erase(it);
    }
    
    delete torrent;
}

void LTSessionPause(LTSessionHandle sessionHandle) {
    auto session = static_cast<LTSession*>(sessionHandle);
    session->session.pause();
}

void LTSessionResume(LTSessionHandle sessionHandle) {
    auto session = static_cast<LTSession*>(sessionHandle);
    session->session.resume();
}

bool LTSessionIsPaused(LTSessionHandle sessionHandle) {
    auto session = static_cast<LTSession*>(sessionHandle);
    return session->session.is_paused();
}

void LTSessionSetAlertCallback(LTSessionHandle sessionHandle, LTAlertCallback callback, void* context) {
    auto session = static_cast<LTSession*>(sessionHandle);
    session->alertCallback = callback;
    session->alertContext = context;
}

void LTSessionProcessAlerts(LTSessionHandle sessionHandle) {
    auto session = static_cast<LTSession*>(sessionHandle);
    
    std::vector<lt::alert*> alerts;
    session->session.pop_alerts(&alerts);
    
    for (auto* alert : alerts) {
        if (session->alertCallback) {
            session->alertCallback(alert->message().c_str(), session->alertContext);
        }
    }
}

// Torrent functions
void LTTorrentPause(LTTorrentHandle torrentHandle) {
    auto torrent = static_cast<LTTorrent*>(torrentHandle);
    if (torrent && torrent->handle && torrent->handle->is_valid()) {
        torrent->handle->pause();
    }
}

void LTTorrentResume(LTTorrentHandle torrentHandle) {
    auto torrent = static_cast<LTTorrent*>(torrentHandle);
    if (torrent && torrent->handle && torrent->handle->is_valid()) {
        torrent->handle->resume();
    }
}

void LTTorrentSetDownloadLimit(LTTorrentHandle torrentHandle, int limit) {
    auto torrent = static_cast<LTTorrent*>(torrentHandle);
    if (torrent && torrent->handle && torrent->handle->is_valid()) {
        torrent->handle->set_download_limit(limit);
    }
}

void LTTorrentSetUploadLimit(LTTorrentHandle torrentHandle, int limit) {
    auto torrent = static_cast<LTTorrent*>(torrentHandle);
    if (torrent && torrent->handle && torrent->handle->is_valid()) {
        torrent->handle->set_upload_limit(limit);
    }
}

LTTorrentStatus LTTorrentGetStatus(LTTorrentHandle torrentHandle) {
    LTTorrentStatus status = {};
    auto torrent = static_cast<LTTorrent*>(torrentHandle);
    
    if (!torrent || !torrent->handle || !torrent->handle->is_valid()) {
        return status;
    }
    
    auto s = torrent->handle->status();
    
    switch (s.state) {
        case lt::torrent_status::checking_files:
            status.state = LTStateCheckingFiles;
            break;
        case lt::torrent_status::downloading_metadata:
            status.state = LTStateDownloadingMetadata;
            break;
        case lt::torrent_status::downloading:
            status.state = LTStateDownloading;
            break;
        case lt::torrent_status::finished:
            status.state = LTStateFinished;
            break;
        case lt::torrent_status::seeding:
            status.state = LTStateSeeding;
            break;
        case lt::torrent_status::checking_resume_data:
            status.state = LTStateCheckingResumeData;
            break;
        default:
            status.state = LTStateDownloading;
    }
    
    status.progress = s.progress;
    status.downloadRate = s.download_rate;
    status.uploadRate = s.upload_rate;
    status.totalDownload = s.total_download;
    status.totalUpload = s.total_upload;
    status.numPeers = s.num_peers;
    status.numSeeds = s.num_seeds;
    status.isPaused = s.flags & lt::torrent_flags::paused;
    status.isFinished = s.is_finished;
    
    return status;
}

LTTorrentInfo LTTorrentGetInfo(LTTorrentHandle torrentHandle) {
    LTTorrentInfo info = {};
    auto torrent = static_cast<LTTorrent*>(torrentHandle);
    
    if (!torrent || !torrent->handle || !torrent->handle->is_valid()) {
        return info;
    }
    
    auto ti = torrent->handle->torrent_file();
    if (!ti) {
        return info;
    }
    
    static std::string nameBuffer;
    static std::string hashBuffer;
    
    nameBuffer = ti->name();
    hashBuffer = lt::aux::to_hex(ti->info_hash());
    
    info.name = nameBuffer.c_str();
    info.totalSize = ti->total_size();
    info.pieceLength = ti->piece_length();
    info.infoHash = hashBuffer.c_str();
    info.numFiles = ti->num_files();
    
    return info;
}

bool LTTorrentIsValid(LTTorrentHandle torrentHandle) {
    auto torrent = static_cast<LTTorrent*>(torrentHandle);
    return torrent && torrent->handle && torrent->handle->is_valid();
}

// Utility functions
char* LTCreateMagnetUri(const char* infoHash, const char* name) {
    std::ostringstream oss;
    oss << "magnet:?xt=urn:btih:" << infoHash;
    if (name && strlen(name) > 0) {
        oss << "&dn=" << name;
    }
    return copyString(oss.str());
}

bool LTIsValidInfoHash(const char* infoHash) {
    if (!infoHash) return false;
    
    size_t len = strlen(infoHash);
    if (len != 40 && len != 64) {
        return false;
    }
    
    for (size_t i = 0; i < len; i++) {
        if (!std::isxdigit(infoHash[i])) {
            return false;
        }
    }
    
    return true;
}

char* LTHumanReadableSize(int64_t bytes) {
    const char* suffixes[] = {"B", "KB", "MB", "GB", "TB", "PB"};
    int suffixIndex = 0;
    double size = static_cast<double>(bytes);
    
    while (size >= 1024 && suffixIndex < 5) {
        size /= 1024;
        suffixIndex++;
    }
    
    std::ostringstream oss;
    oss << std::fixed << std::setprecision(2) << size << " " << suffixes[suffixIndex];
    return copyString(oss.str());
}

void LTFreeString(char* str) {
    delete[] str;
}