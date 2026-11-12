Scriptname _00E_FS_NQ11_RecipeChymikumSC extends ObjectReference

Event OnContainerChanged(ObjectReference akNewContainer, ObjectReference akOldContainer)
	
	If !bDoneFirstObjective && akNewContainer == PlayerREF && akOldContainer ==	FS_Theriantrophist_AlchemistCorpse
		bDoneFirstObjective = true
		FS_NQ11.SetObjectiveDisplayed(8)
	EndIf
	
EndEvent

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
		bDone = true
		FS_NQ11.SetObjectiveCompleted(8)
		FS_NQ11.SetObjectiveDisplayed(15)
	EndIf

EndEvent

bool bDone = false
bool bDoneFirstObjective = false
Quest Property FS_NQ11 Auto
Actor Property PlayerREF Auto
Actor Property FS_Theriantrophist_AlchemistCorpse Auto

Bool STR_ReadPending = False ; Enderal AllTogether
