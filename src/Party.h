#pragma once

#include <string>

// Keeping the party together in Enderal's single-player scenes: one machine places NPCs (IsDesignatedPlayer), a scene
// letting go of the player on one game releases the partner too (ShareRelease), Myrad travel brings the party along
// (ShareTravel), and an unstuck key undoes whatever a scene left behind. Scripts use these through EnderalAllTogether.psc.
namespace EAT::Party
{
    bool RegisterPapyrus(RE::BSScript::IVirtualMachine* a_vm);

    // Reads the unstuck key from EnderalAllTogether.ini and starts listening for it (data loaded).
    void InstallInput();

    // Main thread: "X|release", "T|<destination form ID>", "Y|<actor form ID>|<change>", "W|mount" or
    // "E|1|<ms>" / "E|0" (Eye of the Storm started / ended) or "B|<victim>|<target>|<damage mult>|<seconds>" (Eldritch
    // Blood) from another player.
    void Apply(std::uint32_t a_sender, const std::string& a_message);

    // Main menu, or a save about to load: forget partners' slowdowns, pending resets and travel.
    void OnGameUnloaded();

    // Main thread, ~10 times per second: pending animation resets of other players, slowdowns whose end never came.
    void Tick();
}
