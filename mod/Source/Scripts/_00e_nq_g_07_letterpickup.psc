ScriptName _00E_NQ_G_07_LetterPickUp extends ObjectReference

Quest Property NQ_G_07Dijaam Auto
Bool bDone

Bool bReadingDone

Event OnContainerChanged(ObjectReference akNewContainer, ObjectReference akOldContainer)

	If !bDone && akNewContainer == Game.GetPlayer() && NQ_G_07Dijaam.GetCurrentStageID() == 60
		bDone = true
		(NQ_G_07Dijaam as _00E_NQ_G_07_Functions).CheckForBagLooted()
		NQ_G_07Dijaam.SetObjectiveDisplayed(64)
		(NQ_G_07Dijaam as _00E_NQ_G_07_Functions).CheckIfNoteIsRead() ; need to make a check again, because the objective might not have been displayed yet!
	EndIf

EndEvent

Event OnRead()
	; Skyrim Together / Skyrim Souls keep the game running in menus: wait until the book is closed,
	; as in vanilla, so nothing happens (or starts talking) while you are still reading.
	while UI.IsMenuOpen("Book Menu")
		Utility.WaitMenuMode(0.2)
	endwhile
	
	If bReadingDone == false
		bReadingDone = true
		NQ_G_07Dijaam.SetObjectiveCompleted(64)
		(NQ_G_07Dijaam as _00E_NQ_G_07_Functions).CheckForBagLooted()
	EndIf

EndEvent