#pragma once

#include <cstdint>
#include <functional>
#include <string>

// Talking to the other party members through Skyrim Together. Outgoing messages are queued and sent from the game
// thread, at most 10 per second (the API allows 20 across all plugins); urgent messages go before bulk state.
// Incoming messages arrive on Skyrim Together's thread.
namespace EAT::Net
{
    using MessageHandler = std::function<void(std::uint32_t a_sender, std::string a_message)>;
    using PeerHandler = std::function<void(std::uint32_t a_player, bool a_joined)>;

    // Finds the API and registers our channel. False when not running under Skyrim Together (API-Together).
    bool Connect(MessageHandler a_onMessage, PeerHandler a_onPeer);
    bool IsConnected();

    // Queue a message for the whole party (a_to = 0) or one player. Bulk messages (state snapshots) wait behind
    // everything else, so a scene release or a Myrad trip is never stuck behind a check-up.
    void Queue(std::string a_message, std::uint32_t a_to = 0, bool a_bulk = false);

    // Drops everything not yet sent (a save is loading: its messages belong to the old game).
    void ClearOutbox();

    // Sends the next queued message, if any. Game thread, ~10 times per second.
    void Pump();

    bool InParty();
    bool HasPeers();
    std::uint32_t LocalId();

    // The party member whose game is the reference for shared state and places NPCs in scenes: the Skyrim Together
    // party leader when the executable exports it (SkyrimTogetherGetPartyLeaderId), otherwise the lowest player ID.
    // True when playing alone.
    bool IsReference();

    // The leader's player ID, 0 when unknown (no party, or an executable without the export).
    std::uint32_t LeaderId();

    // Messages are split into chunks that fit the API's size limit.
    inline constexpr std::size_t kMaxMessage = 250;
}
