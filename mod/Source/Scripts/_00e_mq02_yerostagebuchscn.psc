Scriptname _00E_MQ02_YerosTagebuchSCN extends ObjectReference  

Event OnRead()
	; Skyrim Together / Skyrim Souls keep the game running in menus: wait until the book is closed,
	; as in vanilla, so nothing happens (or starts talking) while you are still reading.
	while UI.IsMenuOpen("Book Menu")
		Utility.WaitMenuMode(0.2)
	endwhile
	if MQ02Function.IsObjectiveDisplayed(20)
		MQ02Function.ReadBook()
	endif
endEvent

Event OnOpen(ObjectReference akActionRef)
	if MQ02Function.IsObjectiveDisplayed(20)
		MQ02Function.ReadBook()
	endif
EndEvent

Event OnContainerChanged(ObjectReference akNewContainer, ObjectReference akOldContainer)
	if akNewContainer == Game.GetPlayer() && MQ02Function.IsObjectiveDisplayed(20)
		MQ02Function.CountBook()
	EndIf
EndEvent

_00E_MQ02_Functions Property MQ02Function Auto ; needs to be MQ02Function, not MQ02 because of backwards compatibility