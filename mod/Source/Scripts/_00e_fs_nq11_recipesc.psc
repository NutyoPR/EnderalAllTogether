Scriptname _00E_FS_NQ11_RecipeSC extends ObjectReference

Event OnContainerChanged(ObjectReference akNewContainer, ObjectReference akOldContainer)
	
	If !bDoneFirstObjective && akNewContainer == PlayerREF && akOldContainer ==	FS_Theriantrophist_AlchemistCorpse
		bDoneFirstObjective = true
		FS_NQ11.SetObjectiveCompleted(5)
		FS_NQ11.SetObjectiveDisplayed(7)
	EndIf
	
EndEvent


Event OnRead()
	; Skyrim Together / Skyrim Souls keep the game running in menus: wait until the book is closed,
	; as in vanilla, so nothing happens (or starts talking) while you are still reading.
	while UI.IsMenuOpen("Book Menu")
		Utility.WaitMenuMode(0.2)
	endwhile
	
	If !bDone && FS_NQ11.GetCurrentStageID() == 5
		bDone = true
		FS_NQ11.SetCurrentStageID(10)
		FS_NQ11.SetObjectiveCompleted(7)
		FS_NQ11.SetObjectiveDisplayed(10)
	EndIf

EndEvent

bool bDone = false
bool bDoneFirstObjective = false
Quest Property FS_NQ11 Auto

Actor Property PlayerREF Auto
Actor Property FS_Theriantrophist_AlchemistCorpse Auto