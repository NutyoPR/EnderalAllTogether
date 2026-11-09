Scriptname _00E_NQ16Note extends ObjectReference  


Event OnRead()
	; Skyrim Together / Skyrim Souls keep the game running in menus: wait until the book is closed,
	; as in vanilla, so nothing happens (or starts talking) while you are still reading.
	while UI.IsMenuOpen("Book Menu")
		Utility.WaitMenuMode(0.2)
	endwhile
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
