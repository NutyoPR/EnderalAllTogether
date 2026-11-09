Scriptname _00E_NQ07_NoteSC extends ObjectReference  

Event OnRead()
	; Skyrim Together / Skyrim Souls keep the game running in menus: wait until the book is closed,
	; as in vanilla, so nothing happens (or starts talking) while you are still reading.
	while UI.IsMenuOpen("Book Menu")
		Utility.WaitMenuMode(0.2)
	endwhile

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