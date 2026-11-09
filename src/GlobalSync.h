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
    void OnGameLoaded();
    bool InGame();

    // Sends any value that changed on this machine since the last check.
    void Poll();

    // Applies a message from another player ("A", "S", "M" or "N").
    void Apply(const std::string& a_message);

    // Sends this game's full state (in chunks) to the party (a_to = 0) or one player.
    void QueueSnapshot(std::uint32_t a_to);
}
