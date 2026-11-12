Scriptname _00E_MQ11_StartBlackStoneQuests extends ObjectReference  
{Starts all Black Stone quests on read.}

; This script is placed on book _00E_MQ11_LexDocuments. It is supposed
; to start MQ11a, MQ11b and MQ11c.

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

	If doOnce == 0
		doOnce = 1
		MQ11c_ASongInTheSilence.Start()
		MQ11b_AngelOfDeath.Start()
		MQ11a_TheAvatar.Start()
		Utility.Wait(3)
		MQ12a.SetObjectiveDisplayed(0)
		MQ12a.SetObjectiveCompleted(1)
		MQ12a.SetObjectiveDisplayed(10)
		MQ12a.SetObjectiveDisplayed(15)
		RegisterForSingleUpdate(7)
	EndIf

EndEvent

int doOnce

Quest Property MQ11c_ASongInTheSilence Auto ; MQ11c
Quest Property MQ11b_AngelOfDeath Auto ; MQ11b
Quest Property MQ11a_TheAvatar Auto ; MQ11a
Quest Property MQ12a Auto

Bool STR_ReadPending = False ; Enderal AllTogether
