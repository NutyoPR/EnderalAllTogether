#include "ObjectiveSync.h"

#include <array>
#include <charconv>
#include <format>
#include <string_view>
#include <unordered_map>
#include <vector>

#include "Net.h"

namespace EAT::ObjectiveSync
{
    namespace
    {
        // Per-character machinery, not story: never shared.
        constexpr std::array<std::string_view, 16> kPersonal{ "_00E_Player", "_00E_Level", "_00E_Perk", "_00E_Meditation",
            "_00E_Skill", "_00E_Stat", "_00E_Sys", "_00E_FS_Player", "_00E_Weather", "_00E_GamePlay", "_00E_Intro",
            "Arkanist", "ArcaneFever", "Fieber", "Tutorial", "_FS_Phasmalist" };

        std::vector<RE::TESQuest*>                      g_quests;
        std::unordered_map<std::uint64_t, std::uint8_t> g_known;    // last state seen here
        std::unordered_map<std::uint64_t, std::uint8_t> g_pending;  // from the party, for quests not running here yet

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
            const std::string_view id = a_quest->GetFormEditorID() ? a_quest->GetFormEditorID() : "";
            for (const auto part : kPersonal)
                if (id.find(part) != std::string_view::npos)
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
            }
        }
        SKSE::log::info("objectives: watching {} quests ({} personal system quests left alone)", g_quests.size(), personal);
    }

    void OnGameLoaded()
    {
        g_known.clear();
        g_pending.clear();
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
            if (!objective) {
                it = g_pending.erase(it);
            } else if (quest->IsRunning()) {
                if (Rank(it->second) > Rank(objective->state.underlying()))
                    ApplyNow(quest, index, it->second);
                it = g_pending.erase(it);
            } else {
                ++it;
            }
        }
    }

    void Apply(const std::string& a_message)
    {
        const std::string_view text(a_message);
        const auto first = text.find('|', 2);
        const auto second = first == std::string_view::npos ? first : text.find('|', first + 1);
        if (second == std::string_view::npos)
            return;
        RE::FormID    questId = 0;
        std::uint16_t index = 0;
        std::uint8_t  state = 0;
        if (!Parse(text.substr(2, first - 2), questId, 16) || !Parse(text.substr(first + 1, second - first - 1), index) ||
            !Parse(text.substr(second + 1), state) || state > 5)
            return;
        const auto quest = RE::TESForm::LookupByID<RE::TESQuest>(questId);
        if (!quest || IsPersonal(quest))
            return;
        const auto objective = Find(quest, index);
        if (!objective || Rank(state) <= Rank(objective->state.underlying()))
            return;
        if (!quest->IsRunning()) {
            auto& pending = g_pending[KeyOf(questId, index)];
            if (Rank(state) > Rank(pending))
                pending = state;
            return;
        }
        ApplyNow(quest, index, state);
    }

    void QueueSnapshot(std::uint32_t a_to)
    {
        for (const auto quest : g_quests) {
            if (!quest->IsRunning())
                continue;
            for (const auto objective : quest->objectives)
                if (objective && objective->state.underlying() != 0)
                    Net::Queue(std::format("O|{:X}|{}|{}", quest->GetFormID(), objective->index, objective->state.underlying()),
                        a_to, true);
        }
    }
}
