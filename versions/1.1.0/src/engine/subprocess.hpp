// subprocess.hpp - spawn a child process, stream stdout lines, capture stderr.
#pragma once
#include "util.hpp"
#include <functional>
#include <string>
#include <thread>
#include <vector>

namespace proc {

struct Options {
    std::wstring exe;
    std::vector<std::wstring> args;
    std::wstring workingDir;                              // optional
    std::function<void(const std::string&)> onStdoutLine; // optional, UTF-8 lines (no newline)
    std::string* captureStdout = nullptr;                 // optional full stdout capture
    std::string* captureStderr = nullptr;                 // optional full stderr capture
};

// Returns the child exit code, or -1 on spawn failure.
inline int run(const Options& opt) {
    SECURITY_ATTRIBUTES sa{};
    sa.nLength = sizeof(sa);
    sa.bInheritHandle = TRUE;

    HANDLE outR = nullptr, outW = nullptr, errR = nullptr, errW = nullptr;
    if (!CreatePipe(&outR, &outW, &sa, 0)) return -1;
    SetHandleInformation(outR, HANDLE_FLAG_INHERIT, 0);
    if (!CreatePipe(&errR, &errW, &sa, 0)) { CloseHandle(outR); CloseHandle(outW); return -1; }
    SetHandleInformation(errR, HANDLE_FLAG_INHERIT, 0);

    STARTUPINFOW si{};
    si.cb = sizeof(si);
    si.dwFlags = STARTF_USESTDHANDLES;
    si.hStdOutput = outW;
    si.hStdError = errW;
    si.hStdInput = GetStdHandle(STD_INPUT_HANDLE);

    std::wstring cmd = util::buildCommandLine(opt.exe, opt.args);
    std::vector<wchar_t> cmdBuf(cmd.begin(), cmd.end());
    cmdBuf.push_back(L'\0');

    PROCESS_INFORMATION pi{};
    BOOL ok = CreateProcessW(
        nullptr, cmdBuf.data(), nullptr, nullptr, TRUE,
        CREATE_NO_WINDOW, nullptr,
        opt.workingDir.empty() ? nullptr : opt.workingDir.c_str(),
        &si, &pi);

    // Parent must close its copies of the write ends so reads see EOF.
    CloseHandle(outW);
    CloseHandle(errW);

    if (!ok) { CloseHandle(outR); CloseHandle(errR); return -1; }

    // Drain stderr on a background thread to avoid pipe deadlock.
    std::thread errThread([&]() {
        char buf[4096];
        DWORD got = 0;
        for (;;) {
            if (!ReadFile(errR, buf, sizeof(buf), &got, nullptr) || got == 0) break;
            if (opt.captureStderr) opt.captureStderr->append(buf, got);
        }
    });

    // Read stdout on this thread, splitting into lines.
    {
        char buf[4096];
        DWORD got = 0;
        std::string line;
        for (;;) {
            if (!ReadFile(outR, buf, sizeof(buf), &got, nullptr) || got == 0) break;
            if (opt.captureStdout) opt.captureStdout->append(buf, got);
            if (opt.onStdoutLine) {
                for (DWORD i = 0; i < got; ++i) {
                    char c = buf[i];
                    if (c == '\n') {
                        if (!line.empty() && line.back() == '\r') line.pop_back();
                        opt.onStdoutLine(line);
                        line.clear();
                    } else {
                        line.push_back(c);
                    }
                }
            }
        }
        if (opt.onStdoutLine && !line.empty()) {
            if (line.back() == '\r') line.pop_back();
            opt.onStdoutLine(line);
        }
    }

    errThread.join();
    CloseHandle(outR);
    CloseHandle(errR);

    WaitForSingleObject(pi.hProcess, INFINITE);
    DWORD code = 0;
    GetExitCodeProcess(pi.hProcess, &code);
    CloseHandle(pi.hProcess);
    CloseHandle(pi.hThread);
    return (int)code;
}

} // namespace proc
