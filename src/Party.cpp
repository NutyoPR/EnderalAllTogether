#include "Party.h"

#include <atomic>
#include <charconv>
#include <chrono>
#include <format>
#include <fstream>
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
        return true;
    }

    void InstallInput()
    {
        LoadKey();
        if (const auto input = RE::BSInputDeviceManager::GetSingleton())
            input->AddEventSink(InputSink::Get());
    }

    void Apply(const std::string& a_message)
    {
        if (a_message == "X|release") {
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
            RE::FormID id = 0;
            try {
                id = static_cast<RE::FormID>(std::stoul(a_message.substr(2), nullptr, 16));
            } catch (...) {
                return;
            }
            if (const auto destination = RE::TESForm::LookupByID<RE::TESObjectREFR>(id)) {
                SKSE::log::info("partner travelled: following to {:X}", id);
                CallScript("ArriveAt", RE::MakeFunctionArguments(static_cast<RE::TESObjectREFR*>(destination)));
            }
        }
    }
}
