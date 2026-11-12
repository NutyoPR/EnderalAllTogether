#include "Party.h"

#include <atomic>
#include <chrono>
#include <format>
#include <fstream>

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
        bool IsDesignatedPlayer(RE::StaticFunctionTag*)
        {
            return !Net::IsConnected() || !Net::HasPeers() || Net::IsReference();
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
            std::ifstream ini(kIniPath);
            std::string   line;
            while (std::getline(ini, line)) {
                if (!line.starts_with("iUnstuckKey"))
                    continue;
                const auto eq = line.find('=');
                try {
                    if (eq != std::string::npos)
                        g_unstuckKey = static_cast<std::uint32_t>(std::stoul(line.substr(eq + 1)));
                } catch (...) {
                }
            }
            SKSE::log::info("unstuck key: {}", g_unstuckKey);
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
                    const auto ui = RE::UI::GetSingleton();
                    if (ui && ui->IsMenuOpen(RE::Console::MENU_NAME))  // typing in the console
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
