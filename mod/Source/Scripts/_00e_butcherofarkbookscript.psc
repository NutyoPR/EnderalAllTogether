Scriptname _00E_ButcherOfArkBookScript extends ObjectReference  

Event OnRead()
	; Skyrim Together / Skyrim Souls keep the game running in menus: wait until the book is closed,
	; as in vanilla, so nothing happens (or starts talking) while you are still reading.
	while UI.IsMenuOpen("Book Menu")
		Utility.WaitMenuMode(0.2)
	endwhile

	if NQ25.GetCurrentStageID() < 5
		NQ25.SetCurrentStageID(5)
	endif
	
	if ThisPart.GetValueInt() == 0
		_00E_NQ25_BooksRead.SetValue(_00E_NQ25_BooksRead.GetValue() + 1)
		NQ25.UpdateCurrentInstanceGlobal(_00E_NQ25_BooksRead)
		if ((NumberOfThePart == 10) || (_00E_ButcherOfArk10Read.GetValue() == 1)) || (_00E_NQ25_TalkedToMarius.GetValueInt() == 1)
			if _00E_NQ25_BooksRead.GetValueInt() < 10
				NQ25.SetObjectiveDisplayed(10, 0, 0)
				NQ25.SetObjectiveDisplayed(20, 1, 1)
			else
				NQ25.SetObjectiveDisplayed(10, 0, 0)
				NQ25.SetObjectiveDisplayed(20, 1, 1)
				NQ25.SetObjectiveCompleted(20)
				NQ25.SetCurrentStageID(10)
			endif
		else
			if _00E_NQ25_BooksRead.GetValueInt() < 10
				NQ25.SetObjectiveCompleted(10,0)
				NQ25.SetObjectiveDisplayed(10, 1, 1)
			endif
		endif
		ThisPart.SetValueInt(1)
	endif
EndEvent


GlobalVariable Property ThisPart Auto
GlobalVariable Property _00E_ButcherOfArk10Read Auto
GlobalVariable Property _00E_NQ25_TalkedToMarius Auto
int Property NumberOfThePart Auto

Quest Property NQ25 Auto
GlobalVariable Property _00E_NQ25_BooksRead Auto