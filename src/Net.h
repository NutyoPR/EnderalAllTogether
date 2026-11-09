#pragma once

#include <cstdint>
#include <functional>
#include <string>
#include <vector>

// Talking to the other party members through Skyrim Together. Outgoing messages are queued and sent at most
// 10 per second (the API allows 20 across all plugins); incoming messages arrive on Skyrim Together's thread.
namespace EAT::Net
{
    using MessageHandler = std::function<void(std::uint32_t a_sender, std::string a_message)>;
    using PeerHandler = std::function<void(std::uint32_t a_player, bool a_joined)>;

    // Finds the API and registers our channel. False when not running under Skyrim Together (API-Together).
    bool Connect(MessageHandler a_onMessage, PeerHandler a_onPeer);
    bool IsConnected();

    // Queue a message for the whole party (a_to = 0) or one player.
    void Queue(std::string a_message, std::uint32_t a_to = 0);

    // Sends the next queued message, if any. Called ~10 times per second by the worker.
    void Pump();

    // The party member with the lowest player ID sends the full-state check-ups. Any fixed rule works, it only
    // has to give the same answer on every machine.
    bool IsReference();
    bool HasPeers();

    // Messages are split into chunks that fit the API's size limit.
    inline constexpr std::size_t kMaxMessage = 250;
}
