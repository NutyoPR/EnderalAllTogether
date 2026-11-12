Scriptname _00E_NQ09_OldNoteScript extends ObjectReference  

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
	if ( NQ09.GetCurrentStageID() < 30 ) 
		NQ09.SetCurrentStageID(28)	
	endif
EndEvent

Quest property NQ09 auto

Bool STR_ReadPending = False ; Enderal AllTogether
