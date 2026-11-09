Scriptname defaultSetStageOnCloseBook extends ReferenceAlias  
{SCRIPT NAME NO LONGER ACCURATE. This previously waited until the book was closed to set its stage, but was changed to match expected behavior of OnRead event.}
;==============================================
int Property preReqStage = -1 Auto
{OPTIONAL: If set, this stage must have been done to set the StageToSet}
int Property StageToSet Auto
{The stage to set the quest to when I've been read}
;==============================================
auto STATE ready
	Event OnActivate(ObjectReference akActionRef)
		stageHandling()
	EndEvent

	Event OnEquipped(Actor akActor)
		stageHandling()
	endEvent
	
	Event OnRead()
		; Skyrim Together / Skyrim Souls keep the game running in menus: wait until the book is closed,
		; as in vanilla, so nothing happens (or starts talking) while you are still reading.
		while UI.IsMenuOpen("Book Menu")
			Utility.WaitMenuMode(0.2)
		endwhile
		stageHandling()
	EndEvent
endSTATE

STATE Done
endSTATE

;==============================================

FUNCTION stageHandling()
	If GetOwningQuest().GetCurrentStageID() == preReqStage || preReqStage == -1
		; utility.wait(0.1)
		GetOwningQuest().SetCurrentStageID(StageToSet)	
		gotoState("Done")
	Endif	
endFUNCTION
