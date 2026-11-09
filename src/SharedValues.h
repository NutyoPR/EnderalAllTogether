#pragma once

#include <cstdint>
#include <string>

// Small named values that patched Enderal scripts share with the party, for world state Skyrim Together doesn't
// sync (e.g. which furniture a house has). Scripts call the Papyrus functions in EnderalAllTogether.psc; values
// arriving from the party are stored, kept in the save, and announced with the mod event
// "EnderalAllTogether_Shared" (strArg = key, numArg = value).
namespace EAT::SharedValues
{
    bool RegisterPapyrus(RE::BSScript::IVirtualMachine* a_vm);
    void RegisterSerialization();

    // Main thread: applies "K|key|value" or "KN|key=value;..." from another player.
    void Apply(const std::string& a_message);

    // Sends all stored values (chunked) to the party (a_to = 0) or one player.
    void QueueSnapshot(std::uint32_t a_to);
}
