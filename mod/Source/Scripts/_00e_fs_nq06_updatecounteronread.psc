Scriptname _00E_FS_NQ06_UpdateCounterOnRead extends ObjectReference  

Event OnRead()
	; Skyrim Together / Skyrim Souls keep the game running in menus: wait until the book is closed,
	; as in vanilla, so nothing happens (or starts talking) while you are still reading.
	while UI.IsMenuOpen("Book Menu")
		Utility.WaitMenuMode(0.2)
	endwhile

	if !bDone
		bDone = true
		FS_NQ06.UpdateClues()
	endif
	

EndEvent

bool bDone

_00E_FS_NQ06_Functions Property FS_NQ06 Auto