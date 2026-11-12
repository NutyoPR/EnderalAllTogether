Scriptname _00E_PrinceMithBookSC extends ObjectReference

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

	If _00E_PrinzMithAchievement02Unlocked.GetValueInt() == 0
 		Steam.UnlockAchievement("END_PRINCE_MITH_02")
		_00E_PrinzMithAchievement02Unlocked.SetValueInt(1)
	EndIf
	
EndEvent

GlobalVariable Property _00E_PrinzMithAchievement02Unlocked Auto

Bool STR_ReadPending = False ; Enderal AllTogether
