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
	; Skyrim Together / Skyrim Souls keep the game running in menus: wait until the book is closed,
	; as in vanilla, so nothing happens (or starts talking) while you are still reading.
	while UI.IsMenuOpen("Book Menu")
		Utility.WaitMenuMode(0.2)
	endwhile

    UpdateMQ11b()

EndEvent


Event OnContainerChanged(ObjectReference akNewContainer, ObjectReference akOldContainer)

    UpdateMQ11b()

EndEvent

Quest Property MQ11b Auto
Int Property Objective Auto 
Bool DoOnce = False