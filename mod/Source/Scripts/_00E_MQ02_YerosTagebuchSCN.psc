Scriptname _00E_MQ02_YerosTagebuchSCN extends ObjectReference  

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

Bool STR_ReadPending = False ; Enderal AllTogether
