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
	; Skyrim Together / Skyrim Souls keep the game running in menus: wait until the book is closed,
	; as in vanilla, so nothing happens (or starts talking) while you are still reading.
	while UI.IsMenuOpen("Book Menu")
		Utility.WaitMenuMode(0.2)
	endwhile

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