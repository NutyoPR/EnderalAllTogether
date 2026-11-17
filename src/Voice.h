#pragma once

#include <string>

// Lines spoken by talking activators (Rys' painting in A Touching Effigy, talking statues): Skyrim Together relays only
// lines spoken by actors, so the other players never heard or read them. This game's lines go to the party as
// "V|<speaker form ID>|<topic info form ID>", and theirs play here with voice and subtitle. Only the voice and the text:
// the line's scripts belong to the conversation on the speaker's game and never run here.
namespace EAT::Voice
{
    // Starts listening for lines spoken on this game (data loaded).
    void Install();

    // Main thread: a line another player's game spoke.
    void Apply(const std::string& a_message);

    // Main menu, or a save about to load: stops the line playing and forgets the queue.
    void OnGameUnloaded();

    // Main thread, ~10 times per second: plays queued lines one after another.
    void Tick();
}
