#pragma once

#include <cstddef>
#include <cstdint>

// Our own declaration of Skyrim Together's plugin API, as provided by absol89's API-Together builds:
// SkyrimTogether.exe exports "SkyrimTogetherRequestPluginAPI"; version 1 returns an interface with these virtual
// functions, in this order. Skyrim Together relays small messages on a named channel to the sender's party.
namespace SkyrimTogether
{
    inline constexpr std::size_t kMaxMessageSize = 256;
    inline constexpr const char* kRequestExport = "SkyrimTogetherRequestPluginAPI";

    enum class SendResult : std::uint8_t
    {
        kOk,
        kNotConnected,
        kNotInParty,
        kTooLarge,
        kBadChannel
    };

    using ChannelHandle = std::uint32_t;  // 0 is invalid
    // Callbacks run in Skyrim Together's update, not necessarily on the game's main thread.
    using MessageCallback = void (*)(std::uint32_t a_senderId, const char* a_bytes, std::size_t a_length);
    using PartyChangedCallback = void (*)(std::uint32_t a_playerId, bool a_joined);

    class IV1
    {
    public:
        virtual ~IV1() = default;
        virtual ChannelHandle RegisterChannel(const char* a_name, MessageCallback a_onMessage, PartyChangedCallback a_onPartyChanged) noexcept = 0;
        virtual SendResult    Send(ChannelHandle a_channel, const char* a_bytes, std::size_t a_length) noexcept = 0;
        virtual SendResult    SendTo(ChannelHandle a_channel, std::uint32_t a_playerId, const char* a_bytes, std::size_t a_length) noexcept = 0;
        virtual std::uint32_t GetLocalPlayerId() const noexcept = 0;
        virtual bool          IsInParty() const noexcept = 0;
    };

    using RequestPluginAPI = void* (*)(std::uint8_t a_version);
}
