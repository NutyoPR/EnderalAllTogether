Scriptname _00E_MQ02_YerosBookSCN extends ObjectReference  

Quest Property _00E_MQ02_TheVoid Auto

Event OnCellAttach()
	
	If Self.Is3DLoaded()
		Self.SetMotionType(4)
	EndIf
	
EndEvent

Event OnActivate(ObjectReference akActionRef)

if akActionRef == Game.GetPlayer()
	Self.SetMotionType(1)
EndIf

EndEvent

Event OnRead()
	; Skyrim Together / Skyrim Souls keep the game running in menus: wait until the book is closed,
	; as in vanilla, so nothing happens (or starts talking) while you are still reading.
	while UI.IsMenuOpen("Book Menu")
		Utility.WaitMenuMode(0.2)
	endwhile
		_00E_MQ02_TheVoid.SetCurrentStageID(120)
endEvent