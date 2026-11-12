#pragma once

#include <cstdint>
#include <string>

// Keeps the listed global variables (SyncList.h) the same on every party member's game. All functions run on the
// game's main thread.
namespace EAT::GlobalSync
{
    // Finds the listed globals by editor ID (data loaded).
    void Init();

    // A save was loaded or a new game started: the values in it are the starting point, not changes.
    // Alone, that state is right; in a party the game first asks the others (see main.cpp).
    void OnGameLoaded();
    // Main menu, or a save about to load: nothing to sync until the next OnGameLoaded.
    void OnGameUnloaded();
    bool InGame();
    float SecondsInGame();

    // Aligned = this game's state matches the party (it received their state, or found nobody to ask). Only aligned
    // games answer state requests and send check-ups, so a reloaded older save never overwrites the party.
    bool IsAligned();
    void SetAligned(bool a_aligned);

    // Sends any value that changed on this machine since the last check.
    void Poll();

    // Applies a message from another player ("A", "S", "M" or "N").
    void Apply(const std::string& a_message);

    // Sends this game's full state (in chunks) to the party (a_to = 0) or one player.
    void QueueSnapshot(std::uint32_t a_to);
}
