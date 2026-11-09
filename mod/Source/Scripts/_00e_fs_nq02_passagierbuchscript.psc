Scriptname _00E_FS_NQ02_PassagierbuchScript extends ObjectReference  

Event OnRead()
	; Skyrim Together / Skyrim Souls keep the game running in menus: wait until the book is closed,
	; as in vanilla, so nothing happens (or starts talking) while you are still reading.
	while UI.IsMenuOpen("Book Menu")
		Utility.WaitMenuMode(0.2)
	endwhile

	If FS_NQ02.GetCurrentStageID() == 90
		FS_NQ02.SetCurrentStageID(100)
	ElseIf FS_NQ02.GetCurrentStageID() == 110
		FS_NQ02.SetCurrentStageID(120)
	EndIf

EndEvent

Quest Property FS_NQ02 Auto