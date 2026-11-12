// Enderal AllTogether: keeps Enderal's story state the same for everyone in a Skyrim Together party.
// Requires Skyrim Together built from absol89's API-Together fork, which provides the plugin API.
//
//   Net           messages to/from the party through Skyrim Together
//   SyncList      which global variables are shared, and how
//   GlobalSync    relationships, quest counters, story choices
//   SharedValues  small shared values for patched scripts (house furniture), kept in the save
//   Party         scenes and travel: one machine places NPCs, releases and Myrad trips are shared, unstuck key
#include <chrono>
#include <thread>

#include "GlobalSync.h"
#include "Net.h"
#include "Party.h"
#include "SharedValues.h"

namespace
{
    using namespace std::chrono;

    void AddTask(std::function<void()> a_task)
    {
        if (const auto tasks = SKSE::GetTaskInterface())
            tasks->AddTask(std::move(a_task));
    }

    // Main thread: a message from another player.
    void Dispatch(std::uint32_t a_sender, const std::string& a_message)
    {
        if (a_message == "R") {  // a member asks for the current state
            if (EAT::Net::IsReference() && EAT::GlobalSync::InGame()) {
                EAT::GlobalSync::QueueSnapshot(a_sender);
                EAT::SharedValues::QueueSnapshot(a_sender);
            }
        } else if (a_message.starts_with("X|") || a_message.starts_with("T|")) {
            if (EAT::GlobalSync::InGame())
                EAT::Party::Apply(a_message);
        } else if (a_message.starts_with("K")) {
            EAT::SharedValues::Apply(a_message);
        } else {
            EAT::GlobalSync::Apply(a_message);
        }
    }

    // Line up with the party: the reference sends its state, everyone else asks for it.
    void Align(std::uint32_t a_to)
    {
        if (!EAT::Net::IsConnected() || !EAT::GlobalSync::InGame() || !EAT::Net::HasPeers())
            return;
        if (EAT::Net::IsReference()) {
            EAT::GlobalSync::QueueSnapshot(a_to);
            EAT::SharedValues::QueueSnapshot(a_to);
        } else if (a_to == 0) {
            EAT::Net::Queue("R");
        }
    }

    // Checks for local changes 10 times per second, sends queued messages, and has the reference send a full
    // check-up every 30 s (messages can be lost; this corrects any difference).
    void Worker()
    {
        auto lastCheckup = steady_clock::now();
        for (;;) {
            std::this_thread::sleep_for(100ms);
            AddTask([] { EAT::GlobalSync::Poll(); });
            EAT::Net::Pump();
            if (steady_clock::now() - lastCheckup > 30s) {
                lastCheckup = steady_clock::now();
                AddTask([] {
                    if (EAT::Net::IsReference())
                        Align(0);
                });
            }
        }
    }
}

SKSEPluginLoad(const SKSE::LoadInterface* a_skse)
{
    SKSE::Init(a_skse);
    SKSE::GetPapyrusInterface()->Register(EAT::SharedValues::RegisterPapyrus);
    SKSE::GetPapyrusInterface()->Register(EAT::Party::RegisterPapyrus);
    EAT::SharedValues::RegisterSerialization();

    SKSE::GetMessagingInterface()->RegisterListener([](SKSE::MessagingInterface::Message* a_msg) {
        switch (a_msg->type) {
        case SKSE::MessagingInterface::kDataLoaded:
            EAT::GlobalSync::Init();
            EAT::Party::InstallInput();
            if (EAT::Net::Connect(
                    [](std::uint32_t a_sender, std::string a_message) { AddTask([a_sender, a_message] { Dispatch(a_sender, a_message); }); },
                    [](std::uint32_t a_player, bool a_joined) {
                        if (a_joined)
                            AddTask([a_player] { Align(a_player); });
                    }))
                std::thread(Worker).detach();
            break;
        case SKSE::MessagingInterface::kPostLoadGame:
        case SKSE::MessagingInterface::kNewGame:
            EAT::GlobalSync::OnGameLoaded();
            Align(0);
            break;
        default:
            break;
        }
    });
    return true;
}
