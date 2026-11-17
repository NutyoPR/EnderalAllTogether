#include "Party.h"

#include <algorithm>
#include <atomic>
#include <charconv>
#include <chrono>
#include <format>
#include <fstream>
#include <map>
#include <set>
#include <vector>

#include "GlobalSync.h"
#include "Net.h"

namespace EAT::Party
{
    namespace
    {
        constexpr const char* kScript = "EnderalAllTogether";
        constexpr const char* kIniPath = "Data/SKSE/Plugins/EnderalAllTogether.ini";

        std::uint32_t             g_unstuckKey = 207;  // End
        std::atomic<std::int64_t> g_quietUntil{ 0 };   // a release we ran ourselves is not shared back before this
        std::int64_t              g_surrenderUntil = 0;  // a second press can't pay before the first payment applied
        std::vector<std::int64_t> g_mountResets;         // main thread: when to reset the other players' animations

        // After a Myrad flight the leader lands well after the others arrive, so the reset is repeated a few times.
        constexpr std::int64_t kMountResetDelaysMs[] = { 500, 3000, 8000, 15000 };

        // A partner's Eye of the Storm slows this game until they say it ended, or this long after it should have. Per
        // player: with two casters, the first one ending must not speed this game up while the other's still runs.
        std::map<std::uint32_t, std::int64_t> g_slowTimeBy;  // main thread: player -> when their slowdown ends at the latest
        constexpr std::int64_t kSlowTimeGraceMs = 3000;
        constexpr std::int64_t kMaxSlowTimeMs = 60000;

        // A partner's travel brings this player along behind a fade (ArriveAt). Two at once (both players travelling, or a
        // retried message) would overlap the fades: one at a time.
        std::int64_t           g_arriveUntil = 0;  // main thread
        constexpr std::int64_t kArriveMs = 5000;

        std::int64_t NowMs()
        {
            using namespace std::chrono;
            return duration_cast<milliseconds>(steady_clock::now().time_since_epoch()).count();
        }

        // Calls a global function of EnderalAllTogether.psc.
        void CallScript(const char* a_function, RE::BSScript::IFunctionArguments* a_args)
        {
            const auto vm = RE::BSScript::Internal::VirtualMachine::GetSingleton();
            if (!vm) {
                delete a_args;
                return;
            }
            RE::BSTSmartPointer<RE::BSScript::IStackCallbackFunctor> callback;
            vm->DispatchStaticCall(kScript, a_function, a_args, callback);
        }

        // Releasing runs Enderal's own stop functions, which share a release again: keep quiet for a few seconds.
        void RunRelease(const char* a_function)
        {
            g_quietUntil = NowMs() + 5000;
            CallScript(a_function, RE::MakeFunctionArguments());
        }

        // Other players as this game shows them: Skyrim Together spawns them with a temporary reference and a temporary
        // base NPC built from their appearance (form IDs 0xFF......). NPCs from the game files never have both.
        bool IsOtherPlayer(RE::Actor* a_actor)
        {
            if (!a_actor || a_actor->IsPlayerRef() || (a_actor->GetFormID() >> 24) != 0xFF)
                return false;
            const auto base = a_actor->GetActorBase();
            return base && (base->GetFormID() >> 24) == 0xFF;
        }

        // Puts the other players' characters on this game back into their normal animation state. The leader's Myrad
        // flight plays a paired "mount the dragon" animation; the leader's own game ends it, but the others kept playing
        // it on their copy of the leader, who then slid off into the distance until he reconnected.
        void ResetOtherPlayers()
        {
            const auto lists = RE::ProcessLists::GetSingleton();
            if (!lists)
                return;
            int count = 0;
            lists->ForEachHighActor([&](RE::Actor* a_actor) {
                if (IsOtherPlayer(a_actor)) {
                    a_actor->NotifyAnimationGraph("IdleForceDefaultState");
                    ++count;
                }
                return RE::BSContainer::ForEachResult::kContinue;
            });
            if (count)
                SKSE::log::info("reset the animation of {} other player(s)", count);
        }

        void ScheduleMountResets()
        {
            const auto now = NowMs();
            g_mountResets.clear();
            for (const auto delay : kMountResetDelaysMs)
                g_mountResets.push_back(now + delay);
        }

        // ---- Papyrus (EnderalAllTogether.psc) ----
        bool InCoop(RE::StaticFunctionTag*)
        {
            return Net::IsConnected();
        }

        // The party leader's game (it runs the NPCs), or the only game when playing alone.
        bool IsDesignatedPlayer(RE::StaticFunctionTag*)
        {
            return Net::IsReference();
        }

        void ShareRelease(RE::StaticFunctionTag*)
        {
            const auto now = NowMs();
            if (now < g_quietUntil)
                return;
            g_quietUntil = now + 2000;  // one release per scene, even if several stop functions run
            Net::Queue("X|release");
        }

        void ShareTravel(RE::StaticFunctionTag*, RE::TESObjectREFR* a_destination)
        {
            if (a_destination)
                Net::Queue(std::format("T|{:X}", a_destination->GetFormID()));
        }

        // The Myrad flight ended on this (the leader's) game: the others reset their copy of this player.
        void ShareMountReset(RE::StaticFunctionTag*)
        {
            Net::Queue("W|mount");
        }

        // Eye of the Storm on this game: every other game slows down (or speeds up again) with it.
        void ShareSlowTime(RE::StaticFunctionTag*, bool a_start, float a_seconds)
        {
            if (a_start)
                Net::Queue(std::format("E|1|{}", static_cast<std::int64_t>((std::clamp)(a_seconds, 0.0f, 60.0f) * 1000.0f)));
            else
                Net::Queue("E|0");
        }

        // True while a partner's Eye of the Storm slows this game (the talent's own end mustn't speed it up then).
        bool IsSlowedByParty(RE::StaticFunctionTag*)
        {
            return !g_slowTimeBy.empty();
        }

        bool IsOtherPlayerNative(RE::StaticFunctionTag*, RE::Actor* a_actor)
        {
            return IsOtherPlayer(a_actor);
        }

        // Eldritch Blood on this game: the victim's AI may run on another player's game, which then turns it too. Only
        // actors from the game files: a spawned NPC's temporary form ID differs between games.
        void ShareFrenzy(RE::StaticFunctionTag*, RE::Actor* a_victim, RE::Actor* a_target, float a_damageMult, std::int32_t a_seconds)
        {
            if (!a_victim || (a_victim->GetFormID() >> 24) == 0xFF) {
                if (a_victim)
                    SKSE::log::info("Eldritch Blood on {:X}: spawned NPC, not shared", a_victim->GetFormID());
                return;
            }
            const RE::FormID target = a_target && (a_target->GetFormID() >> 24) != 0xFF ? a_target->GetFormID() : 0;
            Net::Queue(std::format("B|{:X}|{:X}|{}|{}", a_victim->GetFormID(), target, a_damageMult, a_seconds));
        }

        void SlowTimeHere(bool a_start)
        {
            CallScript("SlowTimeWithParty", RE::MakeFunctionArguments(static_cast<bool>(a_start)));
        }

        // A companion's reaction in this player's conversation: the others show the same message.
        void ShareSympathy(RE::StaticFunctionTag*, RE::Actor* a_actor, std::int32_t a_change)
        {
            if (a_actor && a_change != 0)
                Net::Queue(std::format("Y|{:X}|{}", a_actor->GetFormID(), a_change));
        }

        // Music a broken sequence left behind (scripts add music types and only their own ending removes them, and the
        // game keeps them in the save): remove everything queued; the game then picks the music for where you are.
        // The queue holds the engine's music interface: only entries the game's own type information confirms as music
        // type forms are used, and only their form IDs go to Papyrus (never a pointer from the queue).
        void ClearMusic()
        {
            const auto manager = RE::BSMusicManager::GetSingleton();
            if (!manager)
                return;
            std::vector<RE::FormID> queued;
            for (const auto type : manager->musicQueue) {
                const auto music = type ? skyrim_cast<RE::BGSMusicType*>(type) : nullptr;
                if (music && RE::TESForm::LookupByID<RE::BGSMusicType>(music->GetFormID()) == music)
                    queued.push_back(music->GetFormID());
            }
            for (const auto id : queued)
                CallScript("RemoveMusic", RE::MakeFunctionArguments(static_cast<std::int32_t>(id)));
            SKSE::log::info("unstuck: removed {} of {} queued music entries", queued.size(), manager->musicQueue.size());
        }

        // Guards that won't stop fighting over a bounty, and won't talk so it could be paid (in co-op the guard's AI may run
        // in another player's game, which never offers you the arrest dialogue): surrender to them. Only bounties with the
        // crime faction of someone actually fighting you here, so a bandit fight never touches an old bounty elsewhere;
        // Papyrus pays it (if you can) and only then calls the guards off.
        void Surrender()
        {
            const auto player = RE::PlayerCharacter::GetSingleton();
            const auto lists = RE::ProcessLists::GetSingleton();
            if (!player || !lists || !player->IsInCombat() || NowMs() < g_surrenderUntil)
                return;
            std::set<RE::FormID> owed;
            lists->ForEachHighActor([&](RE::Actor* a_actor) {
                if (a_actor && a_actor != player && !a_actor->IsDead() && a_actor->IsInCombat() && a_actor->IsHostileToActor(player)) {
                    const auto faction = a_actor->GetCrimeFaction();
                    if (faction && player->GetViolentCrimeGoldValue(faction) + player->GetNonViolentCrimeGoldValue(faction) > 0)
                        owed.insert(faction->GetFormID());
                }
                return RE::BSContainer::ForEachResult::kContinue;
            });
            if (owed.empty())
                return;
            g_surrenderUntil = NowMs() + 3000;
            for (const auto id : owed)
                CallScript("PayBounty", RE::MakeFunctionArguments(static_cast<std::int32_t>(id)));
            SKSE::log::info("unstuck: surrendering to {} guard faction(s)", owed.size());
        }

        // ---- unstuck key ----
        void LoadKey()
        {
            const auto trim = [](std::string_view a_s) {
                const auto b = a_s.find_first_not_of(" \t\r");
                const auto e = a_s.find_last_not_of(" \t\r");
                return b == std::string_view::npos ? std::string_view{} : a_s.substr(b, e - b + 1);
            };
            std::ifstream ini(kIniPath);
            std::string   line;
            while (std::getline(ini, line)) {
                const auto eq = line.find('=');
                if (eq == std::string::npos || trim(std::string_view(line).substr(0, eq)) != "iUnstuckKey")
                    continue;
                const auto    value = trim(std::string_view(line).substr(eq + 1));
                std::uint32_t key = 0;
                const auto [end, error] = std::from_chars(value.data(), value.data() + value.size(), key);
                if (error == std::errc{} && key > 0 && key < 256)
                    g_unstuckKey = key;
            }
            SKSE::log::info("unstuck key: {}", g_unstuckKey);
        }

        // Only while the game itself has your input: any menu, text field or chat window takes it.
        bool InGameplay()
        {
            const auto controls = RE::ControlMap::GetSingleton();
            if (!controls)
                return false;
            const auto& data = controls->GetRuntimeData();
            return data.textEntryCount == 0 && !data.contextPriorityStack.empty() &&
                   data.contextPriorityStack.back() == RE::UserEvents::INPUT_CONTEXT_ID::kGameplay;
        }

        class InputSink : public RE::BSTEventSink<RE::InputEvent*>
        {
        public:
            static InputSink* Get()
            {
                static InputSink sink;
                return &sink;
            }

            RE::BSEventNotifyControl ProcessEvent(RE::InputEvent* const* a_event, RE::BSTEventSource<RE::InputEvent*>*) override
            {
                for (auto event = a_event ? *a_event : nullptr; event; event = event->next) {
                    const auto button = event->AsButtonEvent();
                    if (!button || !button->IsDown() || button->GetDevice() != RE::INPUT_DEVICE::kKeyboard ||
                        button->GetIDCode() != g_unstuckKey)
                        continue;
                    if (!GlobalSync::InGame() || !InGameplay())  // menus, chat, console, main menu, loading
                        continue;
                    SKSE::log::info("unstuck key pressed");
                    RunRelease("Unstuck");
                    ClearMusic();
                    Surrender();
                    ResetOtherPlayers();  // a partner stuck in an animation on this game (Myrad flight)
                }
                return RE::BSEventNotifyControl::kContinue;
            }
        };
    }

    bool RegisterPapyrus(RE::BSScript::IVirtualMachine* a_vm)
    {
        a_vm->RegisterFunction("IsDesignatedPlayer", kScript, IsDesignatedPlayer);
        a_vm->RegisterFunction("InCoop", kScript, InCoop);
        a_vm->RegisterFunction("ShareRelease", kScript, ShareRelease);
        a_vm->RegisterFunction("ShareTravel", kScript, ShareTravel);
        a_vm->RegisterFunction("ShareSympathy", kScript, ShareSympathy);
        a_vm->RegisterFunction("ShareMountReset", kScript, ShareMountReset);
        a_vm->RegisterFunction("ShareSlowTime", kScript, ShareSlowTime);
        a_vm->RegisterFunction("IsOtherPlayer", kScript, IsOtherPlayerNative);
        a_vm->RegisterFunction("ShareFrenzy", kScript, ShareFrenzy);
        a_vm->RegisterFunction("IsSlowedByParty", kScript, IsSlowedByParty);
        return true;
    }

    void InstallInput()
    {
        LoadKey();
        if (const auto input = RE::BSInputDeviceManager::GetSingleton())
            input->AddEventSink(InputSink::Get());
    }

    void OnGameUnloaded()
    {
        g_slowTimeBy.clear();
        g_mountResets.clear();
        g_arriveUntil = 0;
    }

    void Apply(std::uint32_t a_sender, const std::string& a_message)
    {
        if (a_message.starts_with("B|")) {
            // B|victim|target|mult|seconds
            std::vector<std::string_view> parts;
            for (std::string_view rest = std::string_view(a_message).substr(2);;) {
                const auto bar = rest.find('|');
                parts.push_back(rest.substr(0, bar));
                if (bar == std::string_view::npos)
                    break;
                rest = rest.substr(bar + 1);
            }
            RE::FormID   victimId = 0, targetId = 0;
            float        mult = 0.0f;
            std::int32_t seconds = 0;
            const auto   parse = [](std::string_view a_s, auto& a_out, auto... a_base) {
                return std::from_chars(a_s.data(), a_s.data() + a_s.size(), a_out, a_base...).ec == std::errc{};
            };
            if (parts.size() != 4 || !parse(parts[0], victimId, 16) || !parse(parts[1], targetId, 16) || !parse(parts[2], mult) ||
                !parse(parts[3], seconds))
                return;
            const auto victim = RE::TESForm::LookupByID<RE::Actor>(victimId);
            const auto target = targetId ? RE::TESForm::LookupByID<RE::Actor>(targetId) : nullptr;
            if (!victim)
                return;
            SKSE::log::info("partner's Eldritch Blood: {:X} turns on {:X} for {} s", victimId, targetId, seconds);
            CallScript("FrenzyFromPartner", RE::MakeFunctionArguments(static_cast<RE::Actor*>(victim), static_cast<RE::Actor*>(target),
                                                static_cast<float>(mult), static_cast<std::int32_t>(seconds)));
        } else if (a_message.starts_with("E|1|")) {
            std::int64_t ms = 0;
            const auto   text = std::string_view(a_message).substr(4);
            if (std::from_chars(text.data(), text.data() + text.size(), ms).ec != std::errc{})
                return;
            g_slowTimeBy[a_sender] = NowMs() + (std::clamp)(ms, std::int64_t{ 0 }, kMaxSlowTimeMs) + kSlowTimeGraceMs;
            SKSE::log::info("{}'s Eye of the Storm: slowing time here for {} ms", a_sender, ms);
            SlowTimeHere(true);
        } else if (a_message == "E|0") {
            if (g_slowTimeBy.erase(a_sender)) {
                SKSE::log::info("{}'s Eye of the Storm ended{}", a_sender, g_slowTimeBy.empty() ? "" : " (another one still runs)");
                if (g_slowTimeBy.empty())
                    SlowTimeHere(false);
            }
        } else if (a_message == "W|mount") {
            SKSE::log::info("partner's Myrad flight ended: resetting their animation here");
            ScheduleMountResets();
        } else if (a_message == "X|release") {
            SKSE::log::info("partner released from a scene: releasing here too");
            RunRelease("Release");
        } else if (a_message.starts_with("Y|")) {
            const auto bar = a_message.find('|', 2);
            if (bar == std::string::npos)
                return;
            RE::FormID   id = 0;
            std::int32_t change = 0;
            const auto   idText = std::string_view(a_message).substr(2, bar - 2);
            const auto   changeText = std::string_view(a_message).substr(bar + 1);
            if (std::from_chars(idText.data(), idText.data() + idText.size(), id, 16).ec != std::errc{} ||
                std::from_chars(changeText.data(), changeText.data() + changeText.size(), change).ec != std::errc{} || change == 0)
                return;
            if (const auto actor = RE::TESForm::LookupByID<RE::Actor>(id))
                CallScript("ShowSympathy", RE::MakeFunctionArguments(static_cast<RE::Actor*>(actor), static_cast<std::int32_t>(change)));
        } else if (a_message.starts_with("T|")) {
            RE::FormID     id = 0;
            const auto     text = std::string_view(a_message).substr(2);
            const auto [end, error] = std::from_chars(text.data(), text.data() + text.size(), id, 16);
            if (error != std::errc{} || end != text.data() + text.size())
                return;
            if (const auto now = NowMs(); now < g_arriveUntil) {
                SKSE::log::info("partner travelled to {:X} while this game is still arriving elsewhere: staying", id);
                return;
            }
            if (const auto destination = RE::TESForm::LookupByID<RE::TESObjectREFR>(id)) {
                g_arriveUntil = NowMs() + kArriveMs;
                SKSE::log::info("partner travelled: following to {:X}", id);
                CallScript("ArriveAt", RE::MakeFunctionArguments(static_cast<RE::TESObjectREFR*>(destination)));
            }
        }
    }

    void Tick()
    {
        const auto now = NowMs();
        if (!g_slowTimeBy.empty() && std::erase_if(g_slowTimeBy, [now](const auto& a_entry) { return now > a_entry.second; }) &&
            g_slowTimeBy.empty()) {
            SKSE::log::info("partner's Eye of the Storm: no end received, ending it here");
            SlowTimeHere(false);
        }
        if (g_mountResets.empty())
            return;
        if (std::erase_if(g_mountResets, [now](std::int64_t a_at) { return a_at <= now; }))
            ResetOtherPlayers();
    }
}
