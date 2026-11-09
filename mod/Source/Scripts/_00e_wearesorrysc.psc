Scriptname _00E_WeAreSorrySC extends ObjectReference

Event OnRead()
	; Skyrim Together / Skyrim Souls keep the game running in menus: wait until the book is closed,
	; as in vanilla, so nothing happens (or starts talking) while you are still reading.
	while UI.IsMenuOpen("Book Menu")
		Utility.WaitMenuMode(0.2)
	endwhile

	If !bDone
		Steam.UnlockAchievement("END_ARROW_01")
		bDone = true
	EndIf
	
EndEvent

bool bDone = false
