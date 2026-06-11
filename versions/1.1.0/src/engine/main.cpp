// EasyDownload core engine (core.exe)
// A small C++ CLI that orchestrates yt-dlp + ffmpeg and streams progress to
// stdout as one JSON object per line. The C# host spawns this and relays the
// events to the WebView2 UI.
//
// Commands:
//   core.exe info --url URL --bin DIR [--flat 1]
//       -> prints yt-dlp's raw -J JSON to stdout (the host parses it).
//
//   core.exe run  --url URL --bin DIR --temp DIR --out DIR --name NAME
//                 --type video|audio --quality best|2160|1440|1080|720|480|360
//                 --video-format mp4|mkv --audio-format mp3|m4a|opus|flac
//                 --metadata 0|1 --thumbnail 0|1 --playlist 0|1
//                 [--ffmeta PATH] [--jobid ID]
//       -> downloads through the temp -> merge -> move pipeline, emitting:
//          {"event":"started"} {"event":"stage","stage":...}
//          {"event":"progress",...} {"event":"done","file":...}
//          {"event":"error","message":...}

#include "util.hpp"
#include "json.hpp"
#include "subprocess.hpp"

#include <shellapi.h>
#include <algorithm>
#include <cstdio>
#include <io.h>
#include <fcntl.h>
#include <map>
#include <optional>
#include <string>
#include <vector>

namespace fs = std::filesystem;

// --------------------------------------------------------------------------
// stdout protocol
// --------------------------------------------------------------------------
#include <mutex>

static std::mutex g_emitMutex;

static void emit(const std::string& jsonLine) {
    std::string out = jsonLine;
    out.push_back('\n');
    std::lock_guard<std::mutex> lock(g_emitMutex);
    (void)fwrite(out.data(), 1, out.size(), stdout);
    (void)fflush(stdout);
}

static void emitError(const std::string& message) {
    emit(json::Obj().str("event", "error").str("message", message).done());
}

static void emitStage(const char* stage) {
    emit(json::Obj().str("event", "stage").str("stage", stage).done());
}

// --------------------------------------------------------------------------
// arg parsing  (--key value  |  --flag)
// --------------------------------------------------------------------------
struct Args {
    std::wstring command;
    std::map<std::wstring, std::wstring> kv;

    std::wstring get(const wchar_t* k, const std::wstring& def = L"") const {
        auto it = kv.find(k);
        return it == kv.end() ? def : it->second;
    }
    bool has(const wchar_t* k) const { return kv.count(k) > 0; }
    bool flag(const wchar_t* k, bool def = false) const {
        auto it = kv.find(k);
        if (it == kv.end()) return def;
        return it->second == L"1" || util::iequals(it->second, L"true") || it->second.empty();
    }
};

static Args parseArgs(int argc, wchar_t** argv) {
    Args a;
    if (argc >= 2) a.command = argv[1];
    for (int i = 2; i < argc; ++i) {
        std::wstring tok = argv[i];
        if (tok.rfind(L"--", 0) == 0) {
            std::wstring key = tok.substr(2);
            if (i + 1 < argc) {
                std::wstring next = argv[i + 1];
                if (next.rfind(L"--", 0) != 0) { a.kv[key] = next; ++i; continue; }
            }
            a.kv[key] = L"1"; // bare flag
        }
    }
    return a;
}

// --------------------------------------------------------------------------
// number parsing for progress fields (yt-dlp prints "NA" when unknown)
// --------------------------------------------------------------------------
static std::optional<double> parseNum(const std::string& s) {
    std::string t = util::trim(s);
    if (t.empty() || t == "NA" || t == "None") return std::nullopt;
    try { return std::stod(t); } catch (...) { return std::nullopt; }
}

// --------------------------------------------------------------------------
// info command: forward yt-dlp -J output to stdout
// --------------------------------------------------------------------------
static int cmdInfo(const Args& a) {
    fs::path bin = a.get(L"bin");
    std::wstring url = a.get(L"url");
    if (url.empty()) { emitError("missing --url"); return 2; }

    fs::path ytdlp = bin / L"yt-dlp.exe";
    std::vector<std::wstring> args = {
        L"-J", L"--no-warnings", L"--no-colors",
        L"--ignore-config", L"--no-playlist-reverse"
    };
    if (a.flag(L"flat", true)) args.push_back(L"--flat-playlist");
    args.push_back(url);

    std::string out, err;
    proc::Options o;
    o.exe = ytdlp.wstring();
    o.args = args;
    o.captureStdout = &out;
    o.captureStderr = &err;
    int code = proc::run(o);

    if (code != 0 || out.empty()) {
        std::string msg = util::trim(err);
        if (msg.size() > 600) msg = util::truncateUtf8Tail(msg, 600);
        emitError(msg.empty() ? "yt-dlp failed" : msg);
        return code == 0 ? 1 : code;
    }
    (void)fwrite(out.data(), 1, out.size(), stdout); // raw JSON for the host
    (void)fflush(stdout);
    return 0;
}

// --------------------------------------------------------------------------
// progress line parsing  (PG \t status \t down \t total \t est \t speed \t eta)
// --------------------------------------------------------------------------
static void handleYtdlpLine(const std::string& line) {
    if (line.rfind("PG\t", 0) == 0) {
        auto f = util::split(line, '\t');
        // f[0]=PG f[1]=status f[2]=down f[3]=total f[4]=est f[5]=speed f[6]=eta
        auto get = [&](size_t i) { return i < f.size() ? f[i] : std::string(); };
        auto down  = parseNum(get(2));
        auto total = parseNum(get(3));
        if (!total) total = parseNum(get(4)); // fall back to estimate
        auto speed = parseNum(get(5));
        auto eta   = parseNum(get(6));

        json::Obj o;
        o.str("event", "progress").str("stage", "download").str("status", get(1));
        if (down)  o.num("downloaded", (long long)*down); else o.null("downloaded");
        if (total) o.num("total", (long long)*total);     else o.null("total");
        if (down && total && *total > 0)
            o.real("percent", (*down / *total) * 100.0);
        else if (get(1) == "finished")
            o.real("percent", 100.0);
        else o.null("percent");
        if (speed) o.real("speed", *speed); else o.null("speed");
        if (eta)   o.num("eta", (long long)*eta); else o.null("eta");
        emit(o.done());
    } else if (line.find("ERROR") != std::string::npos) {
        emit(json::Obj().str("event", "log").str("line", line).done());
    }
}

// --------------------------------------------------------------------------
// run command: the download pipeline
// --------------------------------------------------------------------------
static int cmdRun(const Args& a) {
    fs::path bin   = a.get(L"bin");
    std::wstring url = a.get(L"url");
    if (url.empty()) { emitError("missing --url"); return 2; }

    std::wstring type        = a.get(L"type", L"video");
    std::wstring quality     = a.get(L"quality", L"best");
    std::wstring videoFormat = a.get(L"video-format", L"mp4");
    std::wstring audioFormat = a.get(L"audio-format", L"mp3");
    bool metadata  = a.flag(L"metadata", true);
    bool thumbnail = a.flag(L"thumbnail", true);
    bool playlist  = a.flag(L"playlist", false);

    fs::path outDir = a.get(L"out");
    if (outDir.empty()) { emitError("missing --out"); return 2; }

    std::wstring name = a.get(L"name", L"download");
    // strip anything filesystem-hostile that slipped through
    for (wchar_t bad : std::wstring(L"\\/:*?\"<>|"))
        std::replace(name.begin(), name.end(), bad, L'_');
    if (name.empty()) name = L"download";

    fs::path tempBase = a.get(L"temp");
    if (tempBase.empty()) tempBase = fs::temp_directory_path() / L"EasyDownload";
    std::wstring jobid = a.get(L"jobid");
    if (jobid.empty()) jobid = std::to_wstring(GetTickCount64());
    fs::path workdir = tempBase / jobid;

    fs::path ytdlp  = bin / L"yt-dlp.exe";
    fs::path ffmpeg = bin / L"ffmpeg.exe";

    std::error_code ec;
    fs::create_directories(workdir, ec);
    if (ec) { emitError("cannot create temp folder: " + ec.message()); return 1; }

    emit(json::Obj().str("event", "started").str("jobId", jobid).done());

    // ---- 1. download into temp -------------------------------------------
    emitStage("download");
    std::vector<std::wstring> yargs = {
        L"--no-warnings", L"--no-colors", L"--newline", L"--ignore-config",
        L"--ffmpeg-location", bin.wstring(),
        L"--progress-template",
        L"PG\t%(progress.status)s\t%(progress.downloaded_bytes)s\t%(progress.total_bytes)s\t%(progress.total_bytes_estimate)s\t%(progress.speed)s\t%(progress.eta)s",
        L"-o", (workdir / L"media.%(ext)s").wstring(),
    };
    if (!playlist) yargs.push_back(L"--no-playlist");

    if (type == L"audio") {
        yargs.insert(yargs.end(), {
            L"-x", L"--audio-format", audioFormat, L"--audio-quality", L"0"
        });
    } else {
        std::wstring sel;
        if (quality == L"best" || quality.empty()) {
            sel = L"bv*+ba/b";
        } else {
            sel = L"bv*[height<=" + quality + L"]+ba/b[height<=" + quality + L"]/b";
        }
        yargs.insert(yargs.end(), {
            L"-f", sel, L"--merge-output-format", videoFormat
        });
    }
    if (thumbnail) {
        yargs.insert(yargs.end(), { L"--write-thumbnail", L"--convert-thumbnails", L"jpg" });
    }
    yargs.push_back(url);

    std::string dlErr;
    proc::Options dl;
    dl.exe = ytdlp.wstring();
    dl.args = yargs;
    dl.onStdoutLine = handleYtdlpLine;
    dl.captureStderr = &dlErr;
    int dlCode = proc::run(dl);
    if (dlCode != 0) {
        std::string msg = util::trim(dlErr);
        if (msg.size() > 600) msg = util::truncateUtf8Tail(msg, 600);
        emitError(msg.empty() ? "download failed" : msg);
        fs::remove_all(workdir, ec);
        return 1;
    }

    // ---- 2. locate downloaded media + thumbnail --------------------------
    fs::path media = util::findByExt(workdir, L"media",
        { L"mp4", L"mkv", L"webm", L"mov", L"m4v",
          L"m4a", L"mp3", L"opus", L"aac", L"flac", L"wav", L"ogg" });
    if (media.empty()) {
        emitError("downloaded file not found in temp folder");
        fs::remove_all(workdir, ec);
        return 1;
    }
    fs::path cover = util::findByExt(workdir, L"media", { L"jpg", L"jpeg", L"png", L"webp" });

    std::wstring ext = util::lower(media.extension().wstring());
    if (!ext.empty() && ext[0] == L'.') ext.erase(0, 1);

    // ---- 3. merge (only when there is metadata/cover to embed) -----------
    fs::path ffmeta = a.get(L"ffmeta");
    bool haveFfmeta = !ffmeta.empty() && fs::exists(ffmeta, ec);
    bool coverCapable = thumbnail && !cover.empty() && type == L"audio" &&
                        (ext == L"mp3" || ext == L"m4a" || ext == L"mp4" || ext == L"aac");
    bool doMerge = metadata && (haveFfmeta || coverCapable);

    fs::path finalSrc = media;
    if (doMerge) {
        fs::path mergeDir = workdir / L"merge";
        fs::create_directories(mergeDir, ec);
        fs::path merged = mergeDir / (L"media." + ext);
        emitStage("merge");
        emit(json::Obj().str("event", "progress").str("stage", "merge").null("percent").done());

        std::vector<std::wstring> fargs = { L"-y", L"-hide_banner", L"-loglevel", L"error" };
        // inputs: 0=media, then optionally cover, then optionally ffmeta
        fargs.insert(fargs.end(), { L"-i", media.wstring() });
        int coverIdx = -1, metaIdx = -1, nextIdx = 1;
        if (coverCapable) { fargs.insert(fargs.end(), { L"-i", cover.wstring() }); coverIdx = nextIdx++; }
        if (haveFfmeta)   { fargs.insert(fargs.end(), { L"-i", ffmeta.wstring() }); metaIdx = nextIdx++; }

        if (coverCapable) {
            // map audio from media + cover image as attached picture
            fargs.insert(fargs.end(), { L"-map", L"0:a", L"-map", std::to_wstring(coverIdx) + L":v" });
            if (metaIdx >= 0)
                fargs.insert(fargs.end(), { L"-map_metadata", std::to_wstring(metaIdx) });
            fargs.insert(fargs.end(), { L"-c:a", L"copy" });
            // Always re-encode cover as MJPEG with 1:1 square crop (removes padding/letterbox)
            fargs.insert(fargs.end(), {
                L"-c:v", L"mjpeg",
                L"-vf", L"crop=min(iw\\,ih):min(iw\\,ih),setsar=1"
            });
            if (ext == L"mp3") {
                fargs.insert(fargs.end(), {
                    L"-id3v2_version", L"3",
                    L"-metadata:s:v", L"title=Album cover",
                    L"-metadata:s:v", L"comment=Cover (front)"
                });
            }
            fargs.insert(fargs.end(), { L"-disposition:v", L"attached_pic" });
        } else {
            // metadata only
            fargs.insert(fargs.end(), { L"-map", L"0", L"-map_metadata", std::to_wstring(metaIdx), L"-c", L"copy" });
            if (ext == L"mp4" || ext == L"m4a" || ext == L"mov")
                fargs.insert(fargs.end(), { L"-movflags", L"+faststart" });
        }
        fargs.push_back(merged.wstring());

        std::string fErr;
        proc::Options f;
        f.exe = ffmpeg.wstring();
        f.args = fargs;
        f.captureStderr = &fErr;
        int fc = proc::run(f);
        if (fc != 0 || !fs::exists(merged, ec)) {
            std::string msg = util::trim(fErr);
            if (msg.size() > 600) msg = util::truncateUtf8Tail(msg, 600);
            emitError("merge failed: " + (msg.empty() ? "ffmpeg error" : msg));
            fs::remove_all(workdir, ec);
            return 1;
        }
        finalSrc = merged;
    }

    // ---- 4. move final file to destination -------------------------------
    emitStage("move");
    fs::path dst = util::safeMove(finalSrc, outDir / (name + L"." + ext));

    // ---- 5. clean up temp ------------------------------------------------
    fs::remove_all(workdir, ec);

    emit(json::Obj().str("event", "done").str("file", dst.wstring()).done());
    return 0;
}

// --------------------------------------------------------------------------
int main() {
    _setmode(_fileno(stdout), _O_BINARY); // emit UTF-8 bytes verbatim

    int argc = 0;
    LPWSTR* argv = CommandLineToArgvW(GetCommandLineW(), &argc);
    if (!argv) { emitError("cannot read command line"); return 2; }
    Args a = parseArgs(argc, argv);

    int rc;
    if (a.command == L"info")      rc = cmdInfo(a);
    else if (a.command == L"run")  rc = cmdRun(a);
    else { emitError("unknown command (use 'info' or 'run')"); rc = 2; }

    LocalFree(argv);
    return rc;
}
