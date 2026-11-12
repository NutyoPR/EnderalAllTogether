Scriptname defaultSetStageOnCloseBookNotAlias extends ObjectReference  
{SCRIPT NAME NO LONGER ACCURATE. This previously waited until the book was closed to set its stage, but was changed to match expected behavior of OnRead event.}

int Property preReqStage = -1 Auto
{OPTIONAL: If set, this stage must have been done to set the StageToSet}
int Property StageToSet Auto
{The stage to set the quest to when I've been read}
Quest property MyQuest Auto
{Quest to set the stage on.}

auto STATE ready
	Event OnActivate(ObjectReference akActionRef)
		stageHandling()
	EndEvent

	Event OnEquipped(Actor akActor)
		stageHandling()
	endEvent
	
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
		If GetState() == "Done" ; activated or equipped while you were reading: already handled
			Return
		EndIf
		stageHandling()
	EndEvent
endSTATE

STATE Done
endSTATE

;==============================================

FUNCTION stageHandling()
	If (MyQuest.GetCurrentStageID() == preReqStage || preReqStage == -1)
		; utility.wait(0.1)
		MyQuest.SetCurrentStageID(StageToSet)	
		gotoState("Done")
	Endif	
endFUNCTION

Bool STR_ReadPending = False ; Enderal AllTogether
