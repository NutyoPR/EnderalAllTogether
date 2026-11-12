Scriptname _00E_NQ16Note extends ObjectReference  


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
	if DoOnce == false
		NQ16.SetObjectiveCompleted(10)
		Bandit.EnableNoWait()
		Utility.Wait(2)
		_00E_HelpMessage.Show(_00E_NQ16Falle, 4)
		Utility.Wait(8)
		NQ16.SetCurrentStageID(10)
		DoOnce = true
	endif
EndEvent


ObjectReference Property Bandit Auto
Quest Property NQ16 Auto
Message Property _00E_NQ16Falle Auto
bool doonce = false

Bool STR_ReadPending = False ; Enderal AllTogether
