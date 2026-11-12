Scriptname _00E_NQ_G_03_OnReadLetter extends ObjectReference  

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
		NQ_G_03.bLetterOpened = true
		 bDone = true
	Endif
	
endEvent

bool bDone

_00E_NQ_G_03_Functions Property NQ_G_03 Auto

Bool STR_ReadPending = False ; Enderal AllTogether
