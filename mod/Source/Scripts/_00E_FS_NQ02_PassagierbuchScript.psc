Scriptname _00E_FS_NQ02_PassagierbuchScript extends ObjectReference  

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

	If FS_NQ02.GetCurrentStageID() == 90
		FS_NQ02.SetCurrentStageID(100)
	ElseIf FS_NQ02.GetCurrentStageID() == 110
		FS_NQ02.SetCurrentStageID(120)
	EndIf

EndEvent

Quest Property FS_NQ02 Auto

Bool STR_ReadPending = False ; Enderal AllTogether
