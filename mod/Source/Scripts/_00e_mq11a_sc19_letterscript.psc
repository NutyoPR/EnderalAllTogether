Scriptname _00E_MQ11a_SC19_letterScript extends ObjectReference  

Event OnRead()
	; Skyrim Together / Skyrim Souls keep the game running in menus: wait until the book is closed,
	; as in vanilla, so nothing happens (or starts talking) while you are still reading.
	while UI.IsMenuOpen("Book Menu")
		Utility.WaitMenuMode(0.2)
	endwhile

	if !Done
		MQ11a.SetObjectiveCompleted(56)
		MQ11a.SetObjectiveDisplayed(55)
		Done = True
	EndIf

EndEvent

bool Done
Quest Property MQ11a Auto