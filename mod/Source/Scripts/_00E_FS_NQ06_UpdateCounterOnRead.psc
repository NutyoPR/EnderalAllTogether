Scriptname _00E_FS_NQ06_UpdateCounterOnRead extends ObjectReference  

Event OnRead()
	; Enderal AllTogether: Skyrim Souls / unpaused menus keep the game running while you read; wait until
	; the book is closed, as in vanilla. A second read during the wait is ignored, so nothing runs twice.
	If STR_ReadPending
		Return
	EndIf
	STR_ReadPending = True
	While UI.IsMenuOpen("Book Menu")
		Utility.WaitMenuMode(0.2)
	EndWhile
	STR_ReadPending = False

	if !bDone
		bDone = true
		FS_NQ06.UpdateClues()
	endif
	

EndEvent

bool bDone

_00E_FS_NQ06_Functions Property FS_NQ06 Auto

Bool STR_ReadPending = False ; Enderal AllTogether
