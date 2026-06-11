// util.hpp - small string / path / encoding helpers (header-only, inline)
#pragma once

#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>

#include <string>
#include <vector>
#include <filesystem>

namespace util {

// --- encoding -------------------------------------------------------------

inline std::string narrow(const std::wstring& w) {
    if (w.empty()) return std::string();
    int n = WideCharToMultiByte(CP_UTF8, 0, w.data(), (int)w.size(), nullptr, 0, nullptr, nullptr);
    std::string s(n, '\0');
    WideCharToMultiByte(CP_UTF8, 0, w.data(), (int)w.size(), s.data(), n, nullptr, nullptr);
    return s;
}

inline std::wstring widen(const std::string& s) {
    if (s.empty()) return std::wstring();
    int n = MultiByteToWideChar(CP_UTF8, 0, s.data(), (int)s.size(), nullptr, 0);
    std::wstring w(n, L'\0');
    MultiByteToWideChar(CP_UTF8, 0, s.data(), (int)s.size(), w.data(), n);
    return w;
}

// --- string ---------------------------------------------------------------

inline std::string trim(const std::string& s) {
    size_t a = s.find_first_not_of(" \t\r\n");
    if (a == std::string::npos) return std::string();
    size_t b = s.find_last_not_of(" \t\r\n");
    return s.substr(a, b - a + 1);
}

// Keep at most the last maxBytes bytes of a UTF-8 string without splitting
// a multi-byte sequence (skips leftover continuation bytes 10xxxxxx).
inline std::string truncateUtf8Tail(const std::string& s, size_t maxBytes) {
    if (s.size() <= maxBytes) return s;
    size_t start = s.size() - maxBytes;
    while (start < s.size() && (static_cast<unsigned char>(s[start]) & 0xC0) == 0x80)
        ++start;
    return s.substr(start);
}

inline std::vector<std::string> split(const std::string& s, char sep) {
    std::vector<std::string> out;
    std::string cur;
    for (char c : s) {
        if (c == sep) { out.push_back(cur); cur.clear(); }
        else cur.push_back(c);
    }
    out.push_back(cur);
    return out;
}

inline bool iequals(const std::wstring& a, const std::wstring& b) {
    if (a.size() != b.size()) return false;
    for (size_t i = 0; i < a.size(); ++i)
        if (towlower(a[i]) != towlower(b[i])) return false;
    return true;
}

inline std::wstring lower(std::wstring s) {
    for (auto& c : s) c = (wchar_t)towlower(c);
    return s;
}

// --- command line quoting (Windows rules) ---------------------------------

inline std::wstring quoteArg(const std::wstring& arg) {
    if (!arg.empty() && arg.find_first_of(L" \t\"") == std::wstring::npos)
        return arg;
    std::wstring out = L"\"";
    for (size_t i = 0; ; ++i) {
        unsigned backslashes = 0;
        while (i < arg.size() && arg[i] == L'\\') { ++backslashes; ++i; }
        if (i == arg.size()) { out.append(backslashes * 2, L'\\'); break; }
        if (arg[i] == L'"') { out.append(backslashes * 2 + 1, L'\\'); out.push_back(L'"'); }
        else { out.append(backslashes, L'\\'); out.push_back(arg[i]); }
    }
    out.push_back(L'"');
    return out;
}

inline std::wstring buildCommandLine(const std::wstring& exe, const std::vector<std::wstring>& args) {
    std::wstring cl = quoteArg(exe);
    for (const auto& a : args) { cl.push_back(L' '); cl += quoteArg(a); }
    return cl;
}

// --- filesystem -----------------------------------------------------------

namespace fs = std::filesystem;

// Pick a media/thumbnail file matching base name (e.g. "media") with an
// allowed extension inside dir. Returns empty path if none.
inline fs::path findByExt(const fs::path& dir, const std::wstring& stem,
                          const std::vector<std::wstring>& exts) {
    std::error_code ec;
    if (!fs::exists(dir, ec)) return {};
    for (const auto& e : fs::directory_iterator(dir, ec)) {
        if (!e.is_regular_file()) continue;
        const auto& p = e.path();
        if (lower(p.stem().wstring()) != lower(stem)) continue;
        std::wstring ext = lower(p.extension().wstring());
        if (!ext.empty() && ext[0] == L'.') ext.erase(0, 1);
        for (const auto& want : exts)
            if (ext == lower(want)) return p;
    }
    return {};
}

// Move src to dst, falling back to copy+remove across volumes. Returns final path.
inline fs::path safeMove(const fs::path& src, fs::path dst) {
    std::error_code ec;
    fs::create_directories(dst.parent_path(), ec);
    // Avoid clobbering: append " (n)" before the extension if needed.
    if (fs::exists(dst, ec)) {
        fs::path stem = dst.stem();
        fs::path ext = dst.extension();
        fs::path dir = dst.parent_path();
        for (int i = 1; ; ++i) {
            fs::path cand = dir / (stem.wstring() + L" (" + std::to_wstring(i) + L")" + ext.wstring());
            if (!fs::exists(cand, ec)) { dst = cand; break; }
        }
    }
    fs::rename(src, dst, ec);
    if (ec) {
        ec.clear();
        fs::copy_file(src, dst, fs::copy_options::overwrite_existing, ec);
        if (!ec) fs::remove(src, ec);
    }
    return dst;
}

} // namespace util
