Scriptname _00E_PrinceMithBookSC extends ObjectReference

Event OnRead()
	; Skyrim Together / Skyrim Souls keep the game running in menus: wait until the book is closed,
	; as in vanilla, so nothing happens (or starts talking) while you are still reading.
	while UI.IsMenuOpen("Book Menu")
		Utility.WaitMenuMode(0.2)
	endwhile

	If _00E_PrinzMithAchievement02Unlocked.GetValueInt() == 0
 		Steam.UnlockAchievement("END_PRINCE_MITH_02")
		_00E_PrinzMithAchievement02Unlocked.SetValueInt(1)
	EndIf
	
EndEvent

GlobalVariable Property _00E_PrinzMithAchievement02Unlocked Auto
