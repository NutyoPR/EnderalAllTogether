#include "ObjectiveSync.h"

#include <algorithm>
#include <array>
#include <cctype>
#include <charconv>
#include <chrono>
#include <format>
#include <string_view>
#include <unordered_map>
#include <unordered_set>
#include <vector>

#include "Net.h"

namespace EAT::ObjectiveSync
{
    namespace
    {
        // Per-character machinery, not story: never shared.
        // Matched case-insensitively against the quest's editor ID.
        constexpr std::array<std::string_view, 17> kPersonal{ "_00e_player", "_00e_level", "_00e_perk", "_00e_meditation",
            "_00e_skill", "_00e_stat", "_00e_sys", "_00e_fs_player", "_00e_weather", "_00e_gameplay", "_00e_intro",
            "arkanist", "arcanefever", "fieber", "tutorial", "phasmalist", "theriantrophist" };

        std::vector<RE::TESQuest*>                      g_quests;
        std::unordered_set<RE::FormID>                  g_watched;  // the same quests, for incoming messages
        std::unordered_map<std::uint64_t, std::uint8_t> g_known;    // last state seen here
        std::unordered_map<std::uint64_t, std::uint8_t> g_pending;  // from the party, for quests not running here yet
        // When a party state was handed to Papyrus: until it has applied, the old state here isn't a change to report.
        std::unordered_map<std::uint64_t, std::chrono::steady_clock::time_point> g_fromParty;
        constexpr auto kApplyGrace = std::chrono::seconds(3);

        std::uint64_t KeyOf(RE::FormID a_quest, std::uint16_t a_index)
        {
            return (static_cast<std::uint64_t>(a_quest) << 16) | a_index;
        }

        // dormant < shown < finished (completed or failed)
        int Rank(std::uint8_t a_state)
        {
            return a_state == 0 ? 0 : a_state == 1 ? 1 : 2;
        }

        bool IsPersonal(const RE::TESQuest* a_quest)
        {
            std::string id = a_quest->GetFormEditorID() ? a_quest->GetFormEditorID() : "";
            std::transform(id.begin(), id.end(), id.begin(), [](unsigned char c) { return static_cast<char>(std::tolower(c)); });
            for (const auto part : kPersonal)
                if (id.find(part) != std::string::npos)
                    return true;
            return false;
        }

        RE::BGSQuestObjective* Find(RE::TESQuest* a_quest, std::uint16_t a_index)
        {
            for (const auto objective : a_quest->objectives)
                if (objective && objective->index == a_index)
                    return objective;
            return nullptr;
        }

        // Through Papyrus (EnderalAllTogether.ApplyObjective), so the journal and its notifications update as usual.
        void ApplyNow(RE::TESQuest* a_quest, std::uint16_t a_index, std::uint8_t a_state)
        {
            const auto vm = RE::BSScript::Internal::VirtualMachine::GetSingleton();
            if (!vm)
                return;
            RE::BSTSmartPointer<RE::BSScript::IStackCallbackFunctor> callback;
            vm->DispatchStaticCall("EnderalAllTogether", "ApplyObjective",
                RE::MakeFunctionArguments(static_cast<RE::TESQuest*>(a_quest), static_cast<std::int32_t>(a_index),
                    static_cast<std::int32_t>(a_state)),
                callback);
            SKSE::log::info("objective from the party: {} ({:X}) #{} -> {}", a_quest->GetFormEditorID(), a_quest->GetFormID(),
                a_index, a_state);
        }

        void Receive(RE::FormID a_questId, std::uint16_t a_index, std::uint8_t a_state)
        {
            if (a_state > 5 || !g_watched.contains(a_questId))
                return;
            const auto quest = RE::TESForm::LookupByID<RE::TESQuest>(a_questId);
            const auto objective = quest ? Find(quest, a_index) : nullptr;
            if (!objective || Rank(a_state) <= Rank(objective->state.underlying()))
                return;
            const auto key = KeyOf(a_questId, a_index);
            if (!quest->IsRunning()) {
                auto& pending = g_pending[key];
                if (Rank(a_state) > Rank(pending))
                    pending = a_state;
                return;
            }
            g_known[key] = a_state;  // what the party sent is not a change made here: don't send it back
            g_fromParty[key] = std::chrono::steady_clock::now();
            ApplyNow(quest, a_index, a_state);
        }

        template <class T>
        bool Parse(std::string_view a_text, T& a_out, int a_base = 10)
        {
            const auto [end, error] = std::from_chars(a_text.data(), a_text.data() + a_text.size(), a_out, a_base);
            return error == std::errc{} && end == a_text.data() + a_text.size();
        }
    }

    void Init()
    {
        g_quests.clear();
        g_watched.clear();
        std::size_t personal = 0;
        if (const auto data = RE::TESDataHandler::GetSingleton()) {
            for (const auto quest : data->GetFormArray<RE::TESQuest>()) {
                if (!quest || quest->objectives.empty())
                    continue;
                if (IsPersonal(quest)) {
                    ++personal;
                    continue;
                }
                g_quests.push_back(quest);
                g_watched.insert(quest->GetFormID());
            }
        }
        SKSE::log::info("objectives: watching {} quests ({} personal system quests left alone)", g_quests.size(), personal);
    }

    void OnGameUnloaded()
    {
        g_known.clear();
        g_pending.clear();
        g_fromParty.clear();
    }

    void OnGameLoaded()
    {
        g_known.clear();
        g_pending.clear();
        g_fromParty.clear();
        for (const auto quest : g_quests)
            for (const auto objective : quest->objectives)
                if (objective)
                    g_known[KeyOf(quest->GetFormID(), objective->index)] = objective->state.underlying();
    }

    void Poll()
    {
        const bool share = Net::HasPeers();
        for (const auto quest : g_quests) {
            for (const auto objective : quest->objectives) {
                if (!objective)
                    continue;
                const auto key = KeyOf(quest->GetFormID(), objective->index);
                const std::uint8_t state = objective->state.underlying();
                auto& known = g_known[key];
                if (known == state)
                    continue;
                // A party update still on its way through Papyrus: don't take the old state for a change.
                if (const auto from = g_fromParty.find(key);
                    from != g_fromParty.end() && Rank(state) < Rank(known) && std::chrono::steady_clock::now() - from->second < kApplyGrace)
                    continue;
                const bool forward = Rank(state) > Rank(known);
                known = state;
                if (forward && share)
                    Net::Queue(std::format("O|{:X}|{}|{}", quest->GetFormID(), objective->index, state));
            }
        }
        // Party updates for quests that weren't running here yet (their start arrives through Skyrim Together).
        for (auto it = g_pending.begin(); it != g_pending.end();) {
            const auto quest = RE::TESForm::LookupByID<RE::TESQuest>(static_cast<RE::FormID>(it->first >> 16));
            const auto index = static_cast<std::uint16_t>(it->first & 0xFFFF);
            const auto objective = quest ? Find(quest, index) : nullptr;
            if (!objective || quest->IsCompleted()) {
                it = g_pending.erase(it);
            } else if (quest->IsRunning()) {
                if (Rank(it->second) > Rank(objective->state.underlying())) {
                    g_known[it->first] = it->second;
                    g_fromParty[it->first] = std::chrono::steady_clock::now();
                    ApplyNow(quest, index, it->second);
                }
                it = g_pending.erase(it);
            } else {
                ++it;
            }
        }
    }

    void Apply(const std::string& a_message)
    {
        const std::string_view text(a_message);
        // "ON|<quest>:<objective>=<state>;..." (catch-up, packed) or "O|<quest>|<objective>|<state>" (one change)
        if (text.starts_with("ON|")) {
            std::size_t pos = 3;
            while (pos < text.size()) {
                auto end = text.find(';', pos);
                if (end == std::string_view::npos)
                    end = text.size();
                const auto item = text.substr(pos, end - pos);
                pos = end + 1;
                const auto colon = item.find(':');
                const auto equals = item.find('=');
                RE::FormID    questId = 0;
                std::uint16_t index = 0;
                std::uint8_t  state = 0;
                if (colon == std::string_view::npos || equals == std::string_view::npos || equals < colon ||
                    !Parse(item.substr(0, colon), questId, 16) || !Parse(item.substr(colon + 1, equals - colon - 1), index) ||
                    !Parse(item.substr(equals + 1), state))
                    continue;
                Receive(questId, index, state);
            }
            return;
        }
        const auto first = text.find('|', 2);
        const auto second = first == std::string_view::npos ? first : text.find('|', first + 1);
        if (second == std::string_view::npos)
            return;
        RE::FormID    questId = 0;
        std::uint16_t index = 0;
        std::uint8_t  state = 0;
        if (!Parse(text.substr(2, first - 2), questId, 16) || !Parse(text.substr(first + 1, second - first - 1), index) ||
            !Parse(text.substr(second + 1), state))
            return;
        Receive(questId, index, state);
    }

    void QueueSnapshot(std::uint32_t a_to)
    {
        std::string chunk = "ON|";
        for (const auto quest : g_quests) {
            if (!quest->IsRunning())
                continue;
            for (const auto objective : quest->objectives) {
                if (!objective || objective->state.underlying() == 0)
                    continue;
                const auto item = std::format("{:X}:{}={};", quest->GetFormID(), objective->index, objective->state.underlying());
                if (chunk.size() + item.size() > Net::kMaxMessage) {
                    Net::Queue(std::move(chunk), a_to, true);
                    chunk = "ON|";
                }
                chunk += item;
            }
        }
        if (chunk.size() > 3)
            Net::Queue(std::move(chunk), a_to, true);
    }
}
