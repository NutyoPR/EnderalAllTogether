Scriptname _00E_WeAreSorrySC extends ObjectReference

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

	If !bDone
		Steam.UnlockAchievement("END_ARROW_01")
		bDone = true
	EndIf
	
EndEvent

bool bDone = false

Bool STR_ReadPending = False ; Enderal AllTogether
