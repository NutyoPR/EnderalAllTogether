Scriptname _00E_NQ07_NoteSC extends ObjectReference  

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

	if NQ07.GetCurrentStageID() >= 10 && !bDone
		bDone = True
		NQ07.SetObjectiveDisplayed(22)
		NQ07_SisterKorrieREF.Enable()
		NQ07_SisterDeynaREF.Enable()
	EndIf
		
EndEvent

bool bDone

Actor Property PlayerREF Auto

_00E_NQ07_Functions Property NQ07 Auto

Actor Property NQ07_SisterDeynaREF Auto
Actor Property NQ07_SisterKorrieREF Auto

Bool STR_ReadPending = False ; Enderal AllTogether
