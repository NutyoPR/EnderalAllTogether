Scriptname _00E_FS_NQR03_PageCounterSC extends ObjectReference  

;=====================================================================================
;              							EVENTS                    					 
;=====================================================================================

Event OnCellAttach()
	If Self.Is3DLoaded()
		Self.SetMotionType(4)
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

	if !Done && !(FS_NQR03.IsObjectiveCompleted(35))
		FS_NQR03_NessahPageCounter.SetValue(FS_NQR03_NessahPageCounter.GetValue() + 1)
		FS_NQR03.UpdateCurrentInstanceGlobal(FS_NQR03_NessahPageCounter)
		int CurrentCount = FS_NQR03_NessahPageCounter.GetValueInt()

		if CurrentCount >= 3
			FS_NQR03.SetObjectiveCompleted(35)
			_00E_EPHandler.GiveEP(FS_NQR03.iPagesRewardEXP)
		ElseIf CurrentCount < 3
			FS_NQR03.SetObjectiveCompleted(35,0)
			FS_NQR03.SetObjectiveDisplayed(35, True, True)
			Done = 1
		EndIf
		
	ElseIf Done
		Return
	EndIf

EndEvent

;=====================================================================================
;              							PROPERTIES                    					 
;=====================================================================================

bool Done

_00E_FS_NQR03_Functions Property FS_NQR03 Auto

GlobalVariable Property FS_NQR03_NessahPageCounter Auto

Bool STR_ReadPending = False ; Enderal AllTogether
