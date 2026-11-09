Scriptname DefaultOnReadSetQuestStage extends ReferenceAlias  

int Property myStage  Auto  

Quest Property myQuest  Auto  

; Fixed by the USKP adding the GetStageDone check to prevent repeated quests

event onRead()
	; Skyrim Together / Skyrim Souls keep the game running in menus: wait until the book is closed,
	; as in vanilla, so nothing happens (or starts talking) while you are still reading.
	while UI.IsMenuOpen("Book Menu")
		Utility.WaitMenuMode(0.2)
	endwhile
	if (myQuest.IsStageDone(myStage) == 0)
		myQuest.SetCurrentStageID(myStage)
	endif
endEvent

