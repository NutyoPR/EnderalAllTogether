Scriptname _00E_NQ09_OldNoteScript extends ObjectReference  

Event OnRead()
	; Skyrim Together / Skyrim Souls keep the game running in menus: wait until the book is closed,
	; as in vanilla, so nothing happens (or starts talking) while you are still reading.
	while UI.IsMenuOpen("Book Menu")
		Utility.WaitMenuMode(0.2)
	endwhile
	if ( NQ09.GetCurrentStageID() < 30 ) 
		NQ09.SetCurrentStageID(28)	
	endif
EndEvent

Quest property NQ09 auto

