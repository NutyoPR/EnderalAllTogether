Scriptname _00E_NQ_G_07_Brief_SetStageOnRead extends ObjectReference  

; This is a version of _00E_SetStageOnRead.psc that includes an ugly
; failsave that prevents the activation if the NQ_G questline has not
; started yet. This is supposed to fix
; http://forum.sureai.net/tracker.php?p=8&t=10954 .
; Actually, this shouldn't be an issue because this letter should be
; disabled before the player has started NQ_G_07; but apparently, it
; enables itself for no fucking reason. So here's an ugly stopgap.

Event OnInit()

	Self.BlockActivation(True)

EndEvent

Event OnCellAttach()

	Self.BlockActivation(True)

EndEvent

Event OnActivate(ObjectReference akActionRef)

    if NQ_G_07Dijaam.GetCurrentStageID() >= 130
        ; The letter should not be enabled at this point to begin
        ; with!
        BlockActivation(false)
        Activate(Game.GetPlayer(), true)
    endif

EndEvent

Event OnRead()
	; Skyrim Together / Skyrim Souls keep the game running in menus: wait until the book is closed,
	; as in vanilla, so nothing happens (or starts talking) while you are still reading.
	while UI.IsMenuOpen("Book Menu")
		Utility.WaitMenuMode(0.2)
	endwhile

If !bDone
	QuestToSet.SetCurrentStageID(__Config_iDesiredStage)
	bDone = True
EndIf
	
EndEvent

bool bDone

Quest Property QuestToSet Auto
Quest Property NQ_G_07Dijaam Auto
int Property __Config_iDesiredStage Auto
