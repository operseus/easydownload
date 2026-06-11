// json.hpp - minimal JSON object writer for emitting progress lines (UTF-8).
#pragma once
#include <string>
#include <sstream>
#include <cstdio>
#include "util.hpp"

namespace json {

inline std::string escape(const std::string& s) {
    std::string o;
    o.reserve(s.size() + 8);
    for (unsigned char c : s) {
        switch (c) {
            case '"':  o += "\\\""; break;
            case '\\': o += "\\\\"; break;
            case '\b': o += "\\b";  break;
            case '\f': o += "\\f";  break;
            case '\n': o += "\\n";  break;
            case '\r': o += "\\r";  break;
            case '\t': o += "\\t";  break;
            default:
                if (c < 0x20) {
                    char buf[8];
                    snprintf(buf, sizeof(buf), "\\u%04x", c);
                    o += buf;
                } else {
                    o += (char)c; // already valid UTF-8 byte
                }
        }
    }
    return o;
}

// Builds a single flat JSON object: {"k":"v","n":123,...}
class Obj {
public:
    Obj& str(const char* k, const std::string& v) {
        sep(); os_ << '"' << k << "\":\"" << escape(v) << '"'; return *this;
    }
    Obj& str(const char* k, const std::wstring& v) { return str(k, util::narrow(v)); }
    Obj& num(const char* k, long long v) {
        sep(); os_ << '"' << k << "\":" << v; return *this;
    }
    Obj& real(const char* k, double v) {
        sep(); os_ << '"' << k << "\":" << v; return *this;
    }
    Obj& boolean(const char* k, bool v) {
        sep(); os_ << '"' << k << "\":" << (v ? "true" : "false"); return *this;
    }
    Obj& null(const char* k) { sep(); os_ << '"' << k << "\":null"; return *this; }

    std::string done() { return "{" + os_.str() + "}"; }
private:
    void sep() { if (first_) first_ = false; else os_ << ','; }
    std::ostringstream os_;
    bool first_ = true;
};

} // namespace json
