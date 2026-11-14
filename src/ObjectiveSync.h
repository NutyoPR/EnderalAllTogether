#pragma once

#include <cstdint>
#include <string>

// Quest objectives for the whole party. Skyrim Together syncs quest stages, but many Enderal scripts show, complete or
// fail objectives outside stage fragments, so one player's journal ended up missing them. This watches every quest's
// objectives and shares their changes, whatever script made them. Objectives only move forward (shown, then completed
// or failed), and Enderal's personal system quests (arcane fever, levelling, perks...) are left alone.
namespace EAT::ObjectiveSync
{
    void Init();          // data loaded: find the quests to watch
    void OnGameLoaded();    // a save's objectives are the starting point, not changes
    void OnGameUnloaded();  // main menu or a save loading: forget the old game's objectives
    void Poll();          // game thread, about once a second: send what changed here, apply what waited
    void Apply(const std::string& a_message);  // main thread: "O|quest|objective|state" or packed "ON|quest:objective=state;..."
    void QueueSnapshot(std::uint32_t a_to);    // every shown/finished objective, for a player who joins or loads
}
