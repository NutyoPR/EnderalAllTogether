Scriptname EnderalAllTogether Native Hidden
{Enderal AllTogether: shares small bits of world state with your Skyrim Together party (see EnderalAllTogether.dll).
Without the plugin the native functions are unbound: IsLoaded() then returns False and scripts leave things alone.}

; True when the Enderal AllTogether plugin is installed.
Bool Function IsLoaded() global native

; Stores a value under a key and shares it with the party. Keys must not contain | = ;
Function ShareValue(String asKey, Int aiValue) global native

; The value stored under a key (yours or a party member's), or aiDefault if there is none.
; When a value arrives from the party, the mod event "EnderalAllTogether_Shared" is sent (strArg = key, numArg = value).
Int Function GetSharedValue(String asKey, Int aiDefault) global native

; True when running under Skyrim Together (the plugin found its API), so other players may be around.
Bool Function InCoop() global native

; True on exactly one machine in the party: the Skyrim Together party leader's (on builds that report the leader,
; otherwise the lowest player ID), and always when playing alone or without the plugin installed. Scenes use it so only
; one game moves NPCs around.
Bool Function IsDesignatedPlayer() global native

; A scene let go of the player here (fade gone, controls back, vision over): the party's games do the same.
Function ShareRelease() global native

; The player travelled (Myrad): the party's games follow to the same destination.
Function ShareTravel(ObjectReference akDestination) global native

; A companion reacted to the player in dialogue: the party's games show the same "<name> approves/dislikes".
Function ShareSympathy(Actor akActor, Int aiChange) global native


; ---- run by the plugin ----

; Undoes what scenes do to the player: vision effects, a black-hold fade, disabled controls. Runs on the partner's game
; when a scene releases the player elsewhere, and on the unstuck key.
Function Release() global
	Actor kPlayer = Game.GetPlayer()
	_00E_VisionControl kVision = _00E_PlayerFunctions.GetVisionControl()
	If kVision
		If kPlayer.HasPerk(kVision._00E_VisionPerk)
			kVision.VisionEffectNoTimestopStop(None, None, True)
		EndIf
		If kPlayer.HasSpell(kVision._00E_Vision_TimeSpell)
			kVision.VisionEffectTimestopStop(True)
		EndIf
	EndIf
	_00E_FadeToBlackControl kFade = _00E_PlayerFunctions.GetFadeToBlackControl()
	If kFade
		kFade.FadeToBlackHoldImod.Remove()
	EndIf
	; Leftovers of a scene that broke half-way: the vision's slowdown, transparency and ghost mode.
	If kPlayer.GetActorValue("SpeedMult") < 50
		kPlayer.SetActorValue("SpeedMult", 100)
		If kVision
			kVision.UpdateSpeed(kPlayer) ; apply it now, not at the next sprint or weapon draw
		EndIf
	EndIf
	kPlayer.SetAlpha(1.0)
	kPlayer.SetGhost(False)
	Game.EnablePlayerControls()
	Game.SetPlayerAIDriven(False)
	Game.SetHUDCartMode(False)
	Game.ShowFirstPersonGeometry(True)
EndFunction

; A party member's conversation changed a companion's sympathy: show the message here too (the value is synced).
Function ShowSympathy(Actor akActor, Int aiChange) global
	_00E_SympathyControl kSympathy = _00E_PlayerFunctions.GetSympathyControl()
	If kSympathy && akActor
		kSympathy.ShowSympathyFeedback(akActor, aiChange)
	EndIf
EndFunction

; A shared value arrived from the party (also called for your own). Scripts that can't listen for mod events, such as
; quest scripts, get their updates here.
Function OnShared(String asKey, Int aiValue) global
	If StringUtil.Find(asKey, "bounty:") == 0
		ApplyBounty(Game.GetForm(StringUtil.Substring(asKey, 7) as Int) as Quest, aiValue)
	ElseIf StringUtil.Find(asKey, "mq04stone:") == 0 && aiValue == 1
		_00E_MQ04_Firescript kStone = Game.GetForm(StringUtil.Substring(asKey, 10) as Int) as _00E_MQ04_Firescript
		If kStone
			kStone.SavedByParty()
		EndIf
	EndIf
EndFunction

; A bounty board quest moved on in someone else's game: show the same objectives here (the stage itself is shared by
; Skyrim Together). 10 = accepted, 15 = target dead, 20 = paid, then +20 for each further bounty.
Function ApplyBounty(Quest akQuest, Int aiStage) global
	If !akQuest || aiStage <= 0
		Return
	EndIf
	_00E_NQ_Bounty01_Functions kBounty = akQuest as _00E_NQ_Bounty01_Functions
	Int iStep = aiStage % 20
	If iStep == 10
		If aiStage == 10
			akQuest.SetObjectiveCompleted(0)
		EndIf
		akQuest.SetObjectiveDisplayed(aiStage)
		If kBounty
			kBounty._00E_NQ_Bounty01_Status = 1
		EndIf
	ElseIf iStep == 15
		akQuest.SetObjectiveCompleted(aiStage - 5)
		akQuest.SetObjectiveDisplayed(aiStage)
		If kBounty
			kBounty._00E_NQ_Bounty01_Status = 2
		EndIf
	ElseIf iStep == 0
		akQuest.SetObjectiveDisplayed(aiStage - 10, False)
		akQuest.SetObjectiveCompleted(aiStage - 5)
		If kBounty && kBounty._00E_NQ_Bounty01_Status != 10
			kBounty._00E_NQ_Bounty01_Status = 0
		EndIf
	EndIf
EndFunction

; A party member's game showed, completed or failed a quest objective: do the same here (the plugin only sends changes
; that move an objective forward). States: 1 shown, 2/3 completed, 4/5 failed.
Function ApplyObjective(Quest akQuest, Int aiIndex, Int aiState) global
	If !akQuest
		Return
	EndIf
	If aiState == 1
		akQuest.SetObjectiveDisplayed(aiIndex, True)
	ElseIf aiState == 2 || aiState == 3
		akQuest.SetObjectiveCompleted(aiIndex, True)
	ElseIf aiState == 4 || aiState == 5
		akQuest.SetObjectiveFailed(aiIndex, True)
	EndIf
EndFunction

; The unstuck key also ends music that a broken sequence left running; the plugin calls this for each music type the
; game has queued, and the game then picks the right music for where you are again.
Function RemoveMusic(MusicType akMusic) global
	If akMusic
		akMusic.Remove()
	EndIf
EndFunction

; The unstuck key: the same release, with a notification.
Function Unstuck() global
	Release()
	Debug.Notification("Enderal AllTogether: unstuck")
EndFunction

; Brings the player to where a party member just travelled, behind a short fade.
Function ArriveAt(ObjectReference akDestination) global
	; Not while you're in a scene, meditating (menus off, movement on) or otherwise without control: being pulled out
	; would break it.
	If !akDestination || !Game.IsMovementControlsEnabled() || !Game.IsMenuControlsEnabled()
		Return
	EndIf
	_00E_FadeToBlackControl kFade = _00E_PlayerFunctions.GetFadeToBlackControl()
	If kFade
		kFade.FadeToBlack()
		Utility.Wait(1.0) ; let the screen go black before moving
	EndIf
	Game.GetPlayer().MoveTo(akDestination)
	Utility.Wait(0.5)
	If kFade
		kFade.FadeToBlackBack()
	EndIf
EndFunction
