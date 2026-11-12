#include "GlobalSync.h"

#include <algorithm>
#include <cctype>
#include <charconv>
#include <chrono>
#include <cmath>
#include <format>
#include <unordered_map>
#include <vector>

#include "Net.h"
#include "SyncList.h"

// Message format (text, one change per message, snapshots chunked):
//   A|name|delta      add a difference          (relationships, counters)
//   S|name|value      set a value               (choices and flags)
//   M|name|value      keep the higher value     (counted on every machine)
//   N|name=value;...  check-up snapshot         (set for relationships/choices, max for counters)
namespace EAT::GlobalSync
{
    namespace
    {
        struct Tracked
        {
            const SyncEntry* entry;
            RE::TESGlobal*   global;
            float            last;  // the value we last saw or set; a difference means a change on this machine
            std::chrono::steady_clock::time_point changedHere{};  // last local change (protects it from check-ups)
        };

        using clock = std::chrono::steady_clock;
        constexpr auto kKeepLocalChange = std::chrono::seconds(5);  // long enough for our message to reach the party

        std::vector<Tracked>                    g_tracked;
        std::unordered_map<std::string, std::size_t> g_byName;  // lower-case name -> index
        bool                                    g_inGame = false;
        bool                                    g_aligned = true;
        clock::time_point                       g_inGameSince{};

        std::string Lower(std::string_view a_s)
        {
            std::string s(a_s);
            std::ranges::transform(s, s.begin(), [](unsigned char c) { return static_cast<char>(std::tolower(c)); });
            return s;
        }

        Tracked* Find(std::string_view a_name)
        {
            const auto it = g_byName.find(Lower(a_name));
            return it == g_byName.end() ? nullptr : &g_tracked[it->second];
        }

        bool ParseFloat(std::string_view a_s, float& a_out)
        {
            const auto [end, error] = std::from_chars(a_s.data(), a_s.data() + a_s.size(), a_out);
            return error == std::errc{} && end == a_s.data() + a_s.size() && std::isfinite(a_out);
        }

        // Snapshot rule: relationships and choices take the reference's value, counters never go down.
        void ApplySnapshotValue(Tracked& a_t, float a_value)
        {
            switch (a_t.entry->mode) {
            case SyncMode::kRelationship:
            case SyncMode::kSet:
                // A change made here moments ago may still be on its way to the sender: don't undo it.
                if (clock::now() - a_t.changedHere < kKeepLocalChange)
                    break;
                a_t.global->value = a_value;
                break;
            case SyncMode::kCounter:
            case SyncMode::kMax:
                a_t.global->value = (std::max)(a_t.global->value, a_value);
                break;
            }
        }
    }

    void Init()
    {
        std::unordered_map<std::string, RE::TESGlobal*> byEditorId;
        if (const auto data = RE::TESDataHandler::GetSingleton()) {
            for (const auto global : data->GetFormArray<RE::TESGlobal>()) {
                if (const auto id = global ? global->GetFormEditorID() : nullptr; id && *id)
                    byEditorId.emplace(Lower(id), global);
            }
        }
        for (const auto& entry : kSyncList) {
            const auto it = byEditorId.find(Lower(entry.name));
            if (it == byEditorId.end()) {
                SKSE::log::warn("global {} not found, not synced", entry.name);
                continue;
            }
            g_byName.emplace(Lower(entry.name), g_tracked.size());
            g_tracked.push_back({ &entry, it->second, it->second->value });
        }
        SKSE::log::info("{} of {} listed globals found", g_tracked.size(), kSyncList.size());
    }

    void OnGameLoaded()
    {
        for (auto& t : g_tracked) {
            t.last = t.global->value;
            t.changedHere = {};
        }
        g_inGame = true;
        g_inGameSince = clock::now();
    }

    void OnGameUnloaded()
    {
        g_inGame = false;
    }

    bool InGame()
    {
        return g_inGame;
    }

    float SecondsInGame()
    {
        return g_inGame ? std::chrono::duration<float>(clock::now() - g_inGameSince).count() : 0.0f;
    }

    bool IsAligned()
    {
        return g_aligned;
    }

    void SetAligned(bool a_aligned)
    {
        g_aligned = a_aligned;
    }

    void Poll()
    {
        if (!g_inGame)
            return;
        for (auto& t : g_tracked) {
            const float value = t.global->value;
            if (value == t.last || !std::isfinite(value))
                continue;
            t.changedHere = clock::now();
            switch (t.entry->mode) {
            case SyncMode::kRelationship:
            case SyncMode::kCounter:
                Net::Queue(std::format("A|{}|{}", t.entry->name, value - t.last));
                break;
            case SyncMode::kSet:
                Net::Queue(std::format("S|{}|{}", t.entry->name, value));
                break;
            case SyncMode::kMax:
                Net::Queue(std::format("M|{}|{}", t.entry->name, value));
                break;
            }
            t.last = value;
        }
    }

    void Apply(const std::string& a_message)
    {
        if (!g_inGame || a_message.size() < 2 || a_message[1] != '|')
            return;
        Poll();  // send our own pending changes first, so applying this one doesn't swallow them

        const char kind = a_message[0];
        const std::string_view body = std::string_view(a_message).substr(2);

        if (kind == 'N') {
            g_aligned = true;  // the party's state arrived
            std::size_t pos = 0;
            while (pos < body.size()) {
                const auto end = (std::min)(body.find(';', pos), body.size());
                const auto item = body.substr(pos, end - pos);
                pos = end + 1;
                const auto eq = item.find('=');
                float      value;
                if (eq == std::string_view::npos || !ParseFloat(item.substr(eq + 1), value))
                    continue;
                if (const auto t = Find(item.substr(0, eq))) {
                    ApplySnapshotValue(*t, value);
                    t->last = t->global->value;
                }
            }
            return;
        }

        const auto bar = body.find('|');
        float      value;
        if (bar == std::string_view::npos || !ParseFloat(body.substr(bar + 1), value))
            return;
        const auto t = Find(body.substr(0, bar));
        if (!t)
            return;
        switch (kind) {
        case 'A':
            t->global->value += value;
            break;
        case 'S':
            t->global->value = value;
            break;
        case 'M':
            t->global->value = (std::max)(t->global->value, value);
            break;
        default:
            return;
        }
        t->last = t->global->value;  // our own change detection must not send it back
    }

    void QueueSnapshot(std::uint32_t a_to)
    {
        if (!g_inGame)
            return;
        std::string chunk = "N|";
        for (const auto& t : g_tracked) {
            auto item = std::format("{}={};", t.entry->name, t.global->value);
            if (chunk.size() + item.size() > Net::kMaxMessage) {
                Net::Queue(std::move(chunk), a_to, true);
                chunk = "N|";
            }
            chunk += item;
        }
        if (chunk.size() > 2)
            Net::Queue(std::move(chunk), a_to, true);
    }
}
