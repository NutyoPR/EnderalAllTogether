#include "SharedValues.h"

#include <algorithm>
#include <charconv>
#include <chrono>
#include <format>
#include <map>
#include <mutex>

#include "GlobalSync.h"
#include "Net.h"

namespace EAT::SharedValues
{
    namespace
    {
        constexpr std::uint32_t kSerializationId = 'EATG';
        constexpr std::uint32_t kRecordValues = 'KVAL';
        constexpr std::uint32_t kRecordVersion = 1;
        constexpr std::size_t   kMaxKeyLength = 100;    // keys fit in one message with room to spare
        constexpr std::uint32_t kMaxSavedValues = 4096;

        using clock = std::chrono::steady_clock;
        // A snapshot (KN) is queued as bulk, so single changes (K) overtake it: one that arrives this soon after a
        // change to the same key, made here or received, is older than that change and must not undo it.
        constexpr auto kKeepRecentChange = std::chrono::seconds(5);

        std::mutex                                g_lock;
        std::map<std::string, std::int32_t>      g_values;
        std::map<std::string, clock::time_point> g_changedAt;  // last change per key, not saved

        void Announce(const std::string& a_key, std::int32_t a_value)
        {
            SKSE::ModCallbackEvent event{ "EnderalAllTogether_Shared", a_key.c_str(), static_cast<float>(a_value), nullptr };
            if (const auto source = SKSE::GetModCallbackEventSource())
                source->SendEvent(&event);
            // Scripts that can't listen for mod events (quest scripts) get it here: EnderalAllTogether.OnShared.
            if (const auto vm = RE::BSScript::Internal::VirtualMachine::GetSingleton()) {
                RE::BSTSmartPointer<RE::BSScript::IStackCallbackFunctor> callback;
                vm->DispatchStaticCall("EnderalAllTogether", "OnShared",
                    RE::MakeFunctionArguments(RE::BSFixedString(a_key), static_cast<std::int32_t>(a_value)), callback);
            }
        }

        // ---- Papyrus (EnderalAllTogether.psc) ----
        bool IsLoaded(RE::StaticFunctionTag*)
        {
            return true;  // unbound (plugin missing) returns False, so scripts know to leave things alone
        }

        void ShareValue(RE::StaticFunctionTag*, RE::BSFixedString a_key, std::int32_t a_value)
        {
            const std::string key(a_key.c_str());
            if (key.empty() || key.size() > kMaxKeyLength || key.find_first_of("|=;") != std::string::npos)
                return;
            {
                std::scoped_lock l(g_lock);
                g_values[key] = a_value;
                g_changedAt[key] = clock::now();
            }
            Net::Queue(std::format("K|{}|{}", key, a_value));
        }

        std::int32_t GetSharedValue(RE::StaticFunctionTag*, RE::BSFixedString a_key, std::int32_t a_default)
        {
            std::scoped_lock l(g_lock);
            const auto it = g_values.find(a_key.c_str());
            return it == g_values.end() ? a_default : it->second;
        }

        // ---- save game ----
        void Save(SKSE::SerializationInterface* a_intfc)
        {
            std::scoped_lock l(g_lock);
            if (!a_intfc->OpenRecord(kRecordValues, kRecordVersion))
                return;
            const auto count = static_cast<std::uint32_t>(g_values.size());
            a_intfc->WriteRecordData(count);
            for (const auto& [key, value] : g_values) {
                const auto length = static_cast<std::uint32_t>(key.size());
                a_intfc->WriteRecordData(length);
                a_intfc->WriteRecordData(key.data(), length);
                a_intfc->WriteRecordData(value);
            }
        }

        void Load(SKSE::SerializationInterface* a_intfc)
        {
            std::scoped_lock l(g_lock);
            g_values.clear();
            std::uint32_t type, version, length;
            while (a_intfc->GetNextRecordInfo(type, version, length)) {
                if (type != kRecordValues || version != kRecordVersion)
                    continue;
                std::uint32_t count = 0;
                if (!a_intfc->ReadRecordData(&count, sizeof(count)) || count > kMaxSavedValues)
                    continue;
                for (std::uint32_t i = 0; i < count; ++i) {
                    std::uint32_t keyLength = 0;
                    if (!a_intfc->ReadRecordData(&keyLength, sizeof(keyLength)) || keyLength == 0 || keyLength > kMaxKeyLength)
                        break;  // damaged record: keep what was read so far
                    std::string key(keyLength, '\0');
                    std::int32_t value = 0;
                    if (a_intfc->ReadRecordData(key.data(), keyLength) != keyLength || !a_intfc->ReadRecordData(&value, sizeof(value)))
                        break;
                    g_values[key] = value;
                }
            }
        }

        // Called before a save loads and when returning to the main menu.
        void Revert(SKSE::SerializationInterface*)
        {
            {
                std::scoped_lock l(g_lock);
                g_values.clear();
                g_changedAt.clear();
            }
            GlobalSync::OnGameUnloaded();
        }

        // Scripts hear about a value only when it changes: snapshots repeat every value every 30 seconds, and replaying
        // them would rerun OnShared (bounty journals, pages, stones) for nothing.
        void Store(std::string_view a_key, std::string_view a_value, bool a_fromSnapshot)
        {
            std::int32_t value = 0;
            const auto [end, error] = std::from_chars(a_value.data(), a_value.data() + a_value.size(), value);
            if (error != std::errc{} || end != a_value.data() + a_value.size() || a_key.empty() || a_key.size() > kMaxKeyLength)
                return;
            const std::string key(a_key);
            {
                std::scoped_lock l(g_lock);
                const auto now = clock::now();
                if (a_fromSnapshot) {
                    if (const auto it = g_changedAt.find(key); it != g_changedAt.end() && now - it->second < kKeepRecentChange)
                        return;
                } else {
                    g_changedAt[key] = now;
                }
                const auto [it, added] = g_values.try_emplace(key, value);
                if (!added) {
                    if (it->second == value)
                        return;
                    it->second = value;
                }
            }
            Announce(key, value);
        }
    }

    bool RegisterPapyrus(RE::BSScript::IVirtualMachine* a_vm)
    {
        a_vm->RegisterFunction("IsLoaded", "EnderalAllTogether", IsLoaded);
        a_vm->RegisterFunction("ShareValue", "EnderalAllTogether", ShareValue);
        a_vm->RegisterFunction("GetSharedValue", "EnderalAllTogether", GetSharedValue);
        return true;
    }

    void RegisterSerialization()
    {
        const auto serialization = SKSE::GetSerializationInterface();
        serialization->SetUniqueID(kSerializationId);
        serialization->SetSaveCallback(Save);
        serialization->SetLoadCallback(Load);
        serialization->SetRevertCallback(Revert);
    }

    void Apply(const std::string& a_message)
    {
        // K|key|value  or  KN|key=value;key=value
        if (a_message.starts_with("K|")) {
            const std::string_view body = std::string_view(a_message).substr(2);
            const auto             bar = body.find('|');
            if (bar != std::string_view::npos)
                Store(body.substr(0, bar), body.substr(bar + 1), false);
        } else if (a_message.starts_with("KN|")) {
            const std::string_view body = std::string_view(a_message).substr(3);
            std::size_t            pos = 0;
            while (pos < body.size()) {
                const auto end = (std::min)(body.find(';', pos), body.size());
                const auto item = body.substr(pos, end - pos);
                pos = end + 1;
                if (const auto eq = item.find('='); eq != std::string_view::npos)
                    Store(item.substr(0, eq), item.substr(eq + 1), true);
            }
        }
    }

    void QueueSnapshot(std::uint32_t a_to)
    {
        std::scoped_lock l(g_lock);
        std::string chunk = "KN|";
        for (const auto& [key, value] : g_values) {
            auto item = std::format("{}={};", key, value);
            if (chunk.size() + item.size() > Net::kMaxMessage) {
                Net::Queue(std::move(chunk), a_to, true);
                chunk = "KN|";
            }
            chunk += item;
        }
        if (chunk.size() > 3)
            Net::Queue(std::move(chunk), a_to, true);
    }
}
