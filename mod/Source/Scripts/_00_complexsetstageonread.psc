Scriptname _00_ComplexSetStageOnRead extends ObjectReference  

Event OnRead()
	; Skyrim Together / Skyrim Souls keep the game running in menus: wait until the book is closed,
	; as in vanilla, so nothing happens (or starts talking) while you are still reading.
	while UI.IsMenuOpen("Book Menu")
		Utility.WaitMenuMode(0.2)
	endwhile

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