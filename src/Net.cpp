#include "Net.h"

#include <deque>
#include <mutex>
#include <set>

#include "SkyrimTogether.h"

namespace EAT::Net
{
    namespace
    {
        constexpr const char* kChannel = "EnderalAllTogether.Sync";
        constexpr const char* kLeaderExport = "SkyrimTogetherGetPartyLeaderId";  // absol89 API-Together, optional
        constexpr std::size_t kMaxQueued = 512;                                  // drop the oldest beyond this

        using GetPartyLeaderId = std::uint32_t (*)();

        struct Outgoing
        {
            std::uint32_t to;
            std::string   bytes;
        };

        SkyrimTogether::IV1*          g_api = nullptr;
        SkyrimTogether::ChannelHandle g_channel = 0;
        GetPartyLeaderId              g_getLeader = nullptr;
        MessageHandler                g_onMessage;
        PeerHandler                   g_onPeer;
        std::mutex                    g_lock;
        std::set<std::uint32_t>       g_peers;
        std::deque<Outgoing>          g_urgent;
        std::deque<Outgoing>          g_bulk;

        void OnMessage(std::uint32_t a_sender, const char* a_bytes, std::size_t a_length)
        {
            if (g_onMessage && a_bytes && a_length)
                g_onMessage(a_sender, std::string(a_bytes, a_length));
        }

        void OnPartyChanged(std::uint32_t a_player, bool a_joined)
        {
            {
                std::scoped_lock l(g_lock);
                if (a_joined)
                    g_peers.insert(a_player);
                else
                    g_peers.erase(a_player);
            }
            if (g_onPeer)
                g_onPeer(a_player, a_joined);
        }
    }

    bool Connect(MessageHandler a_onMessage, PeerHandler a_onPeer)
    {
        const auto exe = REX::W32::GetModuleHandleW(nullptr);
        const auto request = reinterpret_cast<SkyrimTogether::RequestPluginAPI>(REX::W32::GetProcAddress(exe, SkyrimTogether::kRequestExport));
        if (!request) {
            SKSE::log::info("Skyrim Together plugin API not found (not running under API-Together): staying inactive");
            return false;
        }
        g_api = static_cast<SkyrimTogether::IV1*>(request(1));
        if (!g_api) {
            SKSE::log::warn("Skyrim Together refused plugin API version 1: staying inactive");
            return false;
        }
        g_getLeader = reinterpret_cast<GetPartyLeaderId>(REX::W32::GetProcAddress(exe, kLeaderExport));
        g_onMessage = std::move(a_onMessage);
        g_onPeer = std::move(a_onPeer);
        g_channel = g_api->RegisterChannel(kChannel, OnMessage, OnPartyChanged);
        if (!g_channel) {
            SKSE::log::warn("could not register channel {}: staying inactive", kChannel);
            g_api = nullptr;
            return false;
        }
        SKSE::log::info("connected to Skyrim Together, channel {}; party leader {}", kChannel,
            g_getLeader ? "reported by Skyrim Together" : "not exported by this build, using the lowest player ID");
        return true;
    }

    bool IsConnected()
    {
        return g_api && g_channel;
    }

    void Queue(std::string a_message, std::uint32_t a_to, bool a_bulk)
    {
        if (!IsConnected() || a_message.empty() || a_message.size() > SkyrimTogether::kMaxMessageSize)
            return;
        std::scoped_lock l(g_lock);
        auto& queue = a_bulk ? g_bulk : g_urgent;
        if (a_message == "R")  // one pending state request is enough
            for (const auto& queued : queue)
                if (queued.bytes == "R" && queued.to == a_to)
                    return;
        if (queue.size() >= kMaxQueued)
            queue.pop_front();
        queue.push_back({ a_to, std::move(a_message) });
    }

    void Pump()
    {
        if (!IsConnected())
            return;
        Outgoing next;
        {
            std::scoped_lock l(g_lock);
            auto& queue = !g_urgent.empty() ? g_urgent : g_bulk;
            if (queue.empty())
                return;
            next = std::move(queue.front());
            queue.pop_front();
        }
        const auto result = next.to ? g_api->SendTo(g_channel, next.to, next.bytes.data(), next.bytes.size()) :
                                      g_api->Send(g_channel, next.bytes.data(), next.bytes.size());
        if (result == SkyrimTogether::SendResult::kTooLarge || result == SkyrimTogether::SendResult::kBadChannel)
            SKSE::log::warn("message rejected ({}): {}", static_cast<int>(result), next.bytes.substr(0, 40));
    }

    bool InParty()
    {
        return IsConnected() && g_api->IsInParty();
    }

    bool HasPeers()
    {
        const bool inParty = InParty();
        std::scoped_lock l(g_lock);
        if (!inParty) {
            g_peers.clear();  // left the party: forget its members (rejoining reports them again)
            return false;
        }
        return !g_peers.empty();
    }

    std::uint32_t LocalId()
    {
        return IsConnected() ? g_api->GetLocalPlayerId() : 0;
    }

    std::uint32_t LeaderId()
    {
        return g_getLeader && InParty() ? g_getLeader() : 0;
    }

    bool IsReference()
    {
        if (!HasPeers())
            return true;  // alone (or not in co-op): this game is the reference
        const auto self = LocalId();
        if (!self)
            return true;
        if (const auto leader = LeaderId())
            return leader == self;
        std::scoped_lock l(g_lock);  // the peer list can change on Skyrim Together's thread: check it under the lock
        return g_peers.empty() || *g_peers.begin() > self;
    }
}
