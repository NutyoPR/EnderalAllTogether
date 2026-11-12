Scriptname _00E_MQ11bBookSCN extends ObjectReference  

; This is a script placed on the three "testimonies" of the victims
; in MQ11b.

Function UpdateMQ11b()

	If MQ11b.GetCurrentStageID() >= 10 && DoOnce == false

		MQ11b.SetObjectiveCompleted(Objective)

		If MQ11b.IsObjectiveCompleted(20) == 1 && MQ11b.IsObjectiveCompleted(30) == 1 && MQ11b.IsObjectiveCompleted(40) == 1
			MQ11b.SetCurrentStageID(20)
			MQ11b.SetCurrentStageID(30)
			MQ11b.SetObjectiveDisplayed(60)
		EndIf
		DoOnce = true
	EndIf

EndFunction

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

    UpdateMQ11b()

EndEvent


Event OnContainerChanged(ObjectReference akNewContainer, ObjectReference akOldContainer)

    UpdateMQ11b()

EndEvent

Quest Property MQ11b Auto
Int Property Objective Auto 
Bool DoOnce = False

Bool STR_ReadPending = False ; Enderal AllTogether
