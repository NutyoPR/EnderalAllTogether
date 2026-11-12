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
		_00E_MQ02_TheVoid.SetCurrentStageID(120)
endEvent

Bool STR_ReadPending = False ; Enderal AllTogether
