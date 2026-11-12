Scriptname _00_ComplexSetStageOnRead extends ObjectReference  

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
		
		If bSetStage
			__Config_QuestToSet.SetCurrentStageID(__Config_iStageToSet)
		EndIf
		
		If bDisplayObjective && !__Config_QuestToSet.IsObjectiveCompleted(__Config_iDisplayObjectiveIndex)
			__Config_QuestToSet.SetObjectiveDisplayed(__Config_iDisplayObjectiveIndex)
		EndIf
		
		If bCompleteObjective
			__Config_QuestToSet.SetObjectiveCompleted(__Config_iDisplayObjectiveIndex)
		EndIf
		
		bDone = True
	EndIf
		
EndEvent

bool bDone = False

bool Property bSetStage = True Auto
bool Property bDisplayObjective = True Auto
bool Property bCompleteObjective = False Auto

int Property __Config_iCompleteObjectiveIndex Auto
int Property __Config_iDisplayObjectiveIndex Auto
int Property __Config_iStageToSet Auto

Quest Property __Config_QuestToSet Auto

Bool STR_ReadPending = False ; Enderal AllTogether
