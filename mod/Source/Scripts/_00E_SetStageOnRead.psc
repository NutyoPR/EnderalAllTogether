Scriptname _00E_SetStageOnRead extends ObjectReference  


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
	QuestToSet.SetCurrentStageID(__Config_iDesiredStage)
	bDone = True
EndIf
	
EndEvent

bool bDone

Quest Property QuestToSet Auto
int Property __Config_iDesiredStage Auto

Bool STR_ReadPending = False ; Enderal AllTogether
