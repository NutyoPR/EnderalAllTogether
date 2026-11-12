// Enderal AllTogether: keeps Enderal's story state the same for everyone in a Skyrim Together party.
// Requires Skyrim Together built from absol89's API-Together fork, which provides the plugin API.
//
//   Net           messages to/from the party through Skyrim Together; who the reference (leader) is
//   SyncList      which global variables are shared, and how
//   GlobalSync    relationships, quest counters, story choices
//   SharedValues  small shared values for patched scripts (house furniture), kept in the save
//   Party         scenes and travel: one machine places NPCs, releases and Myrad trips are shared, unstuck key
//
// Alignment: a game that loads a save or joins a party asks the others for their state ("R") instead of sending
// its own, and only games that have been in sync for a while answer or send check-ups. So an older save loaded by
// anyone, leader included, never overwrites the party.
#include <atomic>
#include <chrono>
#include <thread>

#include "GlobalSync.h"
#include "Net.h"
#include "Party.h"
#include "SharedValues.h"

namespace
{
    using namespace std::chrono;

    constexpr float kSettledSeconds = 10.0f;  // in game this long: trusted to answer state requests
    constexpr float kAskTimeout = 10.0f;      // nobody answered: this save's state is the party's

    std::atomic<bool>          g_tickQueued{ false };
    std::atomic<bool>          g_checkupQueued{ false };
    std::atomic<std::uint32_t> g_loggedLeader{ 0 };

    void AddTask(std::function<void()> a_task)
    {
        if (const auto tasks = SKSE::GetTaskInterface())
            tasks->AddTask(std::move(a_task));
    }

    bool Settled()
    {
        return EAT::GlobalSync::InGame() && EAT::GlobalSync::IsAligned() && EAT::GlobalSync::SecondsInGame() >= kSettledSeconds;
    }

    void SendState(std::uint32_t a_to)
    {
        EAT::GlobalSync::QueueSnapshot(a_to);
        EAT::SharedValues::QueueSnapshot(a_to);
    }

    // Main thread: a message from another player.
    void Dispatch(std::uint32_t a_sender, const std::string& a_message)
    {
        if (a_message == "R") {  // someone just loaded or joined and asks for the party's state
            if (Settled())
                SendState(a_sender);
        } else if (a_message.starts_with("X|") || a_message.starts_with("T|")) {
            if (EAT::GlobalSync::InGame())
                EAT::Party::Apply(a_message);
        } else if (a_message.starts_with("K")) {
            EAT::SharedValues::Apply(a_message);
        } else {
            EAT::GlobalSync::Apply(a_message);
        }
    }

    // A save was loaded or a game started: alone, its state is right; in a party, ask first.
    void OnGameLoaded()
    {
        EAT::GlobalSync::OnGameLoaded();
        const bool ask = EAT::Net::IsConnected() && EAT::Net::HasPeers();
        EAT::GlobalSync::SetAligned(!ask);
        if (ask) {
            SKSE::log::info("loaded in a party: asking the others for their state");
            EAT::Net::Queue("R");
        }
    }

    // A player joined our party: the reference (the leader) brings them up to date.
    void OnPeerJoined(std::uint32_t a_player)
    {
        if (EAT::Net::IsReference() && Settled())
            SendState(a_player);
    }

    // Game thread, ~10 times per second.
    void Tick()
    {
        EAT::GlobalSync::Poll();
        EAT::Net::Pump();
        if (EAT::GlobalSync::InGame() && !EAT::GlobalSync::IsAligned() && EAT::GlobalSync::SecondsInGame() >= kAskTimeout) {
            SKSE::log::info("no answer from the party: keeping this save's state");
            EAT::GlobalSync::SetAligned(true);
        }
        const auto leader = EAT::Net::LeaderId();
        if (g_loggedLeader.exchange(leader) != leader && leader)
            SKSE::log::info("party leader: {} (this client: {}{})", leader, EAT::Net::LocalId(),
                leader == EAT::Net::LocalId() ? ", leading" : "");
    }

    // Queues the game-thread work, at most one of each pending, so nothing piles up during a loading screen.
    // A full check-up every 30 s from the reference corrects lost messages.
    void Worker()
    {
        auto lastCheckup = steady_clock::now();
        for (;;) {
            std::this_thread::sleep_for(100ms);
            if (!g_tickQueued.exchange(true))
                AddTask([] {
                    Tick();
                    g_tickQueued = false;
                });
            if (steady_clock::now() - lastCheckup > 30s && !g_checkupQueued.exchange(true)) {
                lastCheckup = steady_clock::now();
                AddTask([] {
                    if (EAT::Net::HasPeers() && EAT::Net::IsReference() && Settled())
                        SendState(0);
                    g_checkupQueued = false;
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
                            AddTask([a_player] { OnPeerJoined(a_player); });
                    }))
                std::thread(Worker).detach();
            break;
        case SKSE::MessagingInterface::kPreLoadGame:
            EAT::GlobalSync::OnGameUnloaded();
            break;
        case SKSE::MessagingInterface::kPostLoadGame:
        case SKSE::MessagingInterface::kNewGame:
            OnGameLoaded();
            break;
        default:
            break;
        }
    });
    return true;
}
