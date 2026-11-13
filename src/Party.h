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

    // Main thread: "X|release", "T|<destination form ID>" or "Y|<actor form ID>|<change>" from another player.
    void Apply(const std::string& a_message);
}
