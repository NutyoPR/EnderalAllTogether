#include "Party.h"

#include <atomic>
#include <charconv>
#include <chrono>
#include <format>
#include <fstream>

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
                }
                return RE::BSEventNotifyControl::kContinue;
            }
        };
    }

    bool RegisterPapyrus(RE::BSScript::IVirtualMachine* a_vm)
    {
        a_vm->RegisterFunction("IsDesignatedPlayer", kScript, IsDesignatedPlayer);
        a_vm->RegisterFunction("ShareRelease", kScript, ShareRelease);
        a_vm->RegisterFunction("ShareTravel", kScript, ShareTravel);
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
