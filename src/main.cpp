// Enderal AllTogether: keeps Enderal's story state the same for everyone in a Skyrim Together party.
// Requires Skyrim Together built from absol89's API-Together fork, which provides the plugin API.
//
//   Net           messages to/from the party through Skyrim Together; who the reference (leader) is
//   SyncList      which global variables are shared, and how
//   GlobalSync    relationships, quest counters, story choices
//   SharedValues  small shared values for patched scripts (house furniture), kept in the save
//   ObjectiveSync quest objectives shown, completed or failed outside stage fragments
//   Party         scenes and travel: one machine places NPCs, releases and Myrad trips are shared, unstuck key
//   Voice         lines spoken by talking activators (a painting), which Skyrim Together doesn't relay
//
// Alignment: a game that loads a save, joins a party or becomes the party leader asks the others for their state ("R")
// instead of sending its own, and only games that have been in sync for a while answer or send check-ups. Every value
// also carries when it last changed (kept in the save), and a snapshot never undoes a newer change: newest change wins,
// not whoever leads. So an older save loaded by anyone, leader included, never overwrites the party.
#include <atomic>
#include <chrono>
#include <thread>

#include "GlobalSync.h"
#include "Net.h"
#include "ObjectiveSync.h"
#include "Party.h"
#include "SharedValues.h"
#include "Voice.h"

namespace
{
    using namespace std::chrono;

    constexpr float kSettledSeconds = 10.0f;  // in game this long: trusted to answer state requests
    constexpr float kAskTimeout = 10.0f;      // nobody answered: this save's state is the party's

    std::atomic<bool>          g_tickQueued{ false };
    std::atomic<bool>          g_checkupQueued{ false };
    std::atomic<std::uint32_t> g_loggedLeader{ 0 };
    steady_clock::time_point   g_askedAt{};  // main thread: when this game last asked the party for its state

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
        EAT::ObjectiveSync::QueueSnapshot(a_to);
    }

    // Main thread: a message from another player.
    void Dispatch(std::uint32_t a_sender, const std::string& a_message)
    {
        if (a_message == "R") {  // someone just loaded or joined and asks for the party's state
            if (Settled())
                SendState(a_sender);
        } else if (a_message.starts_with("X|") || a_message.starts_with("T|") || a_message.starts_with("Y|") || a_message.starts_with("W|") ||
                   a_message.starts_with("E|") || a_message.starts_with("B|")) {
            if (EAT::GlobalSync::InGame())
                EAT::Party::Apply(a_message);
        } else if (a_message.starts_with("V|")) {
            if (EAT::GlobalSync::InGame())
                EAT::Voice::Apply(a_message);
        } else if (a_message.starts_with("O|") || a_message.starts_with("ON|")) {
            if (EAT::GlobalSync::InGame())
                EAT::ObjectiveSync::Apply(a_message);
        } else if (a_message.starts_with("K")) {
            if (EAT::GlobalSync::InGame())
                EAT::SharedValues::Apply(a_sender, a_message);
        } else {
            EAT::GlobalSync::Apply(a_sender, a_message);
        }
    }

    // Until the party answers (or nobody does within kAskTimeout), this game sends no check-ups and answers no requests.
    void AskForState(const char* a_why)
    {
        SKSE::log::info("{}: asking the others for their state", a_why);
        EAT::GlobalSync::SetAligned(false);
        g_askedAt = steady_clock::now();
        EAT::Net::Queue("R");
    }

    // A save was loaded or a game started: alone, its state is right; in a party, ask first.
    void OnGameLoaded()
    {
        EAT::GlobalSync::OnGameLoaded();
        EAT::ObjectiveSync::OnGameLoaded();
        if (EAT::Net::IsConnected() && EAT::Net::HasPeers())
            AskForState("loaded in a party");
        else
            EAT::GlobalSync::SetAligned(true);
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
        static int s_ticks = 0;
        EAT::GlobalSync::Poll();
        if (++s_ticks % 10 == 0 && EAT::GlobalSync::InGame())  // objectives change rarely: once a second is plenty
            EAT::ObjectiveSync::Poll();
        EAT::Party::Tick();
        EAT::Voice::Tick();
        EAT::Net::Pump();
        if (EAT::GlobalSync::InGame() && !EAT::GlobalSync::IsAligned() &&
            duration<float>(steady_clock::now() - g_askedAt).count() >= kAskTimeout) {
            SKSE::log::info("no answer from the party: keeping this game's state");
            EAT::GlobalSync::SetAligned(true);
        }
        const auto leader = EAT::Net::LeaderId();
        if (g_loggedLeader.exchange(leader) != leader && leader) {
            const bool leading = leader == EAT::Net::LocalId();
            SKSE::log::info("party leader: {} (this client: {}{})", leader, EAT::Net::LocalId(), leading ? ", leading" : "");
            // Leadership moved here (a reconnect can do that): catch up with the party before sending check-ups as the
            // reference. Stamps already keep stale values from winning; this keeps the first check-ups from being stale.
            if (leading && EAT::GlobalSync::InGame() && EAT::Net::HasPeers())
                AskForState("became the party leader");
        }
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
            EAT::ObjectiveSync::Init();
            EAT::Party::InstallInput();
            EAT::Voice::Install();
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
