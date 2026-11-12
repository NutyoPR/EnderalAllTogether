Scriptname DefaultOnReadSetQuestStage extends ReferenceAlias  

int Property myStage  Auto  

Quest Property myQuest  Auto  

; Fixed by the USKP adding the GetStageDone check to prevent repeated quests

event onRead()
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
	if (myQuest.IsStageDone(myStage) == 0)
		myQuest.SetCurrentStageID(myStage)
	endif
endEvent

Bool STR_ReadPending = False ; Enderal AllTogether
