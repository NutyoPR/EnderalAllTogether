Scriptname _00E_NQ_G_04_ReadContractEvent extends ObjectReference  

Event OnRead()
	; Skyrim Together / Skyrim Souls keep the game running in menus: wait until the book is closed,
	; as in vanilla, so nothing happens (or starts talking) while you are still reading.
	while UI.IsMenuOpen("Book Menu")
		Utility.WaitMenuMode(0.2)
	endwhile
	
	if !bDone
		NQ_G_04.bContractRead = true
		bDone = true
	Endif
	
endEvent

bool bDone

_00E_NQ_G_04_Functions Property NQ_G_04 Auto