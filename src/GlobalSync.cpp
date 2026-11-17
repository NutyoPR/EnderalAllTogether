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
#include "ObjectiveSync.h"
#include "Party.h"
#include "SyncList.h"
#include "Voice.h"

// Message format (text, one change per message, snapshots chunked). stamp = when the value last changed (wall clock ms):
//   A|name|delta|stamp       add a difference          (relationships, counters)
//   S|name|value|stamp       set a value               (choices and flags)
//   M|name|value|stamp       keep the higher value     (counted on every machine)
//   N|name=value@stamp;...   check-up snapshot         (newest change wins for relationships/choices, max for counters)
namespace EAT::GlobalSync
{
    namespace
    {
        struct Tracked
        {
            const SyncEntry* entry;
            RE::TESGlobal*   global;
            float            last;  // the value we last saw or set; a difference means a change on this machine
            std::chrono::steady_clock::time_point changedAt{};  // last change, here or from a party message (protects it from check-ups)
            std::int64_t     stamp = 0;  // wall clock of the last change anywhere (saved); 0 = unknown (older save)
        };

        using clock = std::chrono::steady_clock;
        // Long enough for our message to reach the party. Check-ups are queued as bulk, so a single change (A/S/M) can
        // overtake one: a check-up arriving this soon after a change is older than it.
        // Check-ups and snapshots are queued as bulk and can take several seconds to drain (more when two are queued close
        // together or urgent traffic goes first), so this is generous while staying well under the 30 s check-up.
        constexpr auto kKeepRecentChange = std::chrono::seconds(15);

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

        bool ParseStamp(std::string_view a_s, std::int64_t& a_out)
        {
            const auto [end, error] = std::from_chars(a_s.data(), a_s.data() + a_s.size(), a_out);
            return error == std::errc{} && end == a_s.data() + a_s.size() && a_out >= 0;
        }

        // Splits "value@stamp" or "value|stamp" (stamp optional: 0 when missing).
        bool ParseValueAndStamp(std::string_view a_s, char a_separator, float& a_value, std::int64_t& a_stamp)
        {
            a_stamp = 0;
            if (const auto at = a_s.find(a_separator); at != std::string_view::npos) {
                if (!ParseStamp(a_s.substr(at + 1), a_stamp))
                    return false;
                a_s = a_s.substr(0, at);
            }
            return ParseFloat(a_s, a_value);
        }

        // Snapshot rule: counters never go down. Relationships and choices: the newest change wins, whoever sends it. A
        // snapshot from a game with an older value (a stale save, a player who just became leader) never undoes a newer
        // one, and the sender gets the newer value back. Without stamps on either side (saves from before stamps), the
        // old rule: the sender's value, unless it changed here moments ago.
        void ApplySnapshotValue(std::uint32_t a_sender, Tracked& a_t, float a_value, std::int64_t a_stamp)
        {
            const float old = a_t.global->value;
            switch (a_t.entry->mode) {
            case SyncMode::kRelationship:
            case SyncMode::kSet:
                if (a_stamp < a_t.stamp) {
                    if (old != a_value) {
                        SKSE::log::info("snapshot from {}: kept {} = {} (changed {} ms later than their {})", a_sender,
                            a_t.entry->name, old, a_t.stamp - a_stamp, a_value);
                        Net::Queue(std::format("S|{}|{}|{}", a_t.entry->name, old, a_t.stamp), a_sender);
                    }
                    return;
                }
                if (a_stamp == a_t.stamp && clock::now() - a_t.changedAt < kKeepRecentChange)
                    return;
                a_t.global->value = a_value;
                a_t.stamp = a_stamp;
                break;
            case SyncMode::kCounter:
            case SyncMode::kMax:
                a_t.global->value = (std::max)(old, a_value);
                a_t.stamp = (std::max)(a_t.stamp, a_stamp);
                break;
            }
            if (a_t.global->value != old)
                SKSE::log::info("snapshot from {}: {} {} -> {} (their change stamp {}, ours {})", a_sender, a_t.entry->name, old,
                    a_t.global->value, a_stamp, a_t.stamp);
        }
    }

    std::int64_t NowStamp()
    {
        using namespace std::chrono;
        return duration_cast<milliseconds>(system_clock::now().time_since_epoch()).count();
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
            t.changedAt = {};
        }
        g_inGame = true;
        g_inGameSince = clock::now();
    }

    void OnGameUnloaded()
    {
        g_inGame = false;
        Net::ClearOutbox();
        ObjectiveSync::OnGameUnloaded();
        Party::OnGameUnloaded();
        Voice::OnGameUnloaded();
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
            t.changedAt = clock::now();
            // Past the last stamp in any case: a partner whose clock runs ahead must not keep this change "older".
            t.stamp = (std::max)(NowStamp(), t.stamp + 1);
            switch (t.entry->mode) {
            case SyncMode::kRelationship:
            case SyncMode::kCounter:
                Net::Queue(std::format("A|{}|{}|{}", t.entry->name, value - t.last, t.stamp));
                break;
            case SyncMode::kSet:
                Net::Queue(std::format("S|{}|{}|{}", t.entry->name, value, t.stamp));
                break;
            case SyncMode::kMax:
                Net::Queue(std::format("M|{}|{}|{}", t.entry->name, value, t.stamp));
                break;
            }
            t.last = value;
        }
    }

    void Apply(std::uint32_t a_sender, const std::string& a_message)
    {
        if (!g_inGame || a_message.size() < 2 || a_message[1] != '|')
            return;
        Poll();  // send our own pending changes first, so applying this one doesn't swallow them

        const char kind = a_message[0];
        const std::string_view body = std::string_view(a_message).substr(2);

        if (kind == 'N') {  // part of the party's state; "L|" after all of it aligns this game (main.cpp)
            std::size_t pos = 0;
            while (pos < body.size()) {
                const auto end = (std::min)(body.find(';', pos), body.size());
                const auto item = body.substr(pos, end - pos);
                pos = end + 1;
                const auto   eq = item.find('=');
                float        value;
                std::int64_t stamp;
                if (eq == std::string_view::npos || !ParseValueAndStamp(item.substr(eq + 1), '@', value, stamp))
                    continue;
                if (const auto t = Find(item.substr(0, eq))) {
                    ApplySnapshotValue(a_sender, *t, value, stamp);
                    t->last = t->global->value;
                }
            }
            return;
        }

        const auto   bar = body.find('|');
        float        value;
        std::int64_t stamp;
        if (bar == std::string_view::npos || !ParseValueAndStamp(body.substr(bar + 1), '|', value, stamp))
            return;
        const auto t = Find(body.substr(0, bar));
        if (!t)
            return;
        switch (kind) {
        case 'A':
            t->global->value += value;
            break;
        case 'S':
            // Two players set it at nearly the same time: the later one wins on both games.
            if (stamp && stamp < t->stamp)
                return;
            t->global->value = value;
            break;
        case 'M':
            t->global->value = (std::max)(t->global->value, value);
            break;
        default:
            return;
        }
        t->last = t->global->value;  // our own change detection must not send it back
        t->changedAt = clock::now();  // a check-up queued before this change may still be on its way
        t->stamp = (std::max)(t->stamp, stamp ? stamp : NowStamp());
    }

    void QueueSnapshot(std::uint32_t a_to)
    {
        if (!g_inGame)
            return;
        std::string chunk = "N|";
        for (const auto& t : g_tracked) {
            auto item = std::format("{}={}@{};", t.entry->name, t.global->value, t.stamp);
            if (chunk.size() + item.size() > Net::kMaxMessage) {
                Net::Queue(std::move(chunk), a_to, true);
                chunk = "N|";
            }
            chunk += item;
        }
        if (chunk.size() > 2)
            Net::Queue(std::move(chunk), a_to, true);
    }

    void SaveStamps(SKSE::SerializationInterface* a_intfc)
    {
        std::uint32_t count = 0;
        for (const auto& t : g_tracked)
            count += t.stamp != 0;
        if (!count || !a_intfc->OpenRecord(kRecordStamps, kRecordStampsVersion))
            return;
        a_intfc->WriteRecordData(count);
        for (const auto& t : g_tracked) {
            if (!t.stamp)
                continue;
            const std::string_view name = t.entry->name;
            const auto             length = static_cast<std::uint32_t>(name.size());
            a_intfc->WriteRecordData(length);
            a_intfc->WriteRecordData(name.data(), length);
            a_intfc->WriteRecordData(t.stamp);
        }
    }

    void LoadStamps(SKSE::SerializationInterface* a_intfc, std::uint32_t a_version)
    {
        if (a_version != kRecordStampsVersion)
            return;
        std::uint32_t count = 0;
        if (!a_intfc->ReadRecordData(&count, sizeof(count)))
            return;
        for (std::uint32_t i = 0; i < count; ++i) {
            std::uint32_t length = 0;
            if (!a_intfc->ReadRecordData(&length, sizeof(length)) || length == 0 || length > 256)
                return;  // damaged record: keep what was read so far
            std::string  name(length, '\0');
            std::int64_t stamp = 0;
            if (a_intfc->ReadRecordData(name.data(), length) != length || !a_intfc->ReadRecordData(&stamp, sizeof(stamp)))
                return;
            if (const auto t = Find(name))
                t->stamp = stamp;
        }
    }

    void ClearStamps()
    {
        for (auto& t : g_tracked)
            t.stamp = 0;
    }
}
