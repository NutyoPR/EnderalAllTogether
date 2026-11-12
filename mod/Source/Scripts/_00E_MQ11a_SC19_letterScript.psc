Scriptname _00E_MQ11a_SC19_letterScript extends ObjectReference  

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

	if !Done
		MQ11a.SetObjectiveCompleted(56)
		MQ11a.SetObjectiveDisplayed(55)
		Done = True
	EndIf

EndEvent

bool Done
Quest Property MQ11a Auto

Bool STR_ReadPending = False ; Enderal AllTogether
