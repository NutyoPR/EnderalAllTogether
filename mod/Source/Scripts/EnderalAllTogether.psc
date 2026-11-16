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

; The Myrad flight ended on the leader's game: the others put their copy of the leader back into normal animation
; (it kept playing the flight and slid away).
Function ShareMountReset() global native

; Eye of the Storm started (abStart, for afSeconds) or ended on this player's game: it slows every game at once.
Function ShareSlowTime(Bool abStart, Float afSeconds) global native

; True for another player's character as this game shows it (talents never mark or target your partner).
Bool Function IsOtherPlayer(Actor akActor) global native

; Eldritch Blood turned akVictim against akTarget (None: against whoever it fights) on this game: the others do too.
Function ShareFrenzy(Actor akVictim, Actor akTarget, Float afDamageMult, Int aiSeconds) global native

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
		kFade.FadeToBlackIMOD.Remove() ; a fade caught halfway
	EndIf
	ImageSpaceModifier.RemoveCrossFade(0.0)
	; Leftovers of a scene that broke half-way: the vision's slowdown, transparency and ghost mode.
	If kPlayer.GetActorValue("SpeedMult") < 50
		kPlayer.SetActorValue("SpeedMult", 100)
		If kVision
			kVision.UpdateSpeed(kPlayer) ; apply it now, not at the next sprint or weapon draw
		EndIf
	EndIf
	SlowTimeWithParty(False) ; a partner's Eye of the Storm whose end never arrived
	kPlayer.SetAlpha(1.0)
	kPlayer.SetGhost(False)
	Game.EnablePlayerControls()
	Game.SetPlayerAIDriven(False)
	Game.SetHUDCartMode(False)
	Game.ShowFirstPersonGeometry(True)
EndFunction

; A party member's Eye of the Storm: time slows on this game too, for as long as it does on theirs (called by the plugin).
; Same ability as the talent's (slowdown, its screen effect, no kill moves), without the talent itself.
Function SlowTimeWithParty(Bool abStart) global
	Spell kAb = Game.GetFormFromFile(0x0003A477, "Skyrim.esm") as Spell ; _00E_A2_EyeOfTheStormAb
	MagicEffect kOwnCast = Game.GetFormFromFile(0x0003A46E, "Skyrim.esm") as MagicEffect ; _00E_A2_EyeOfTheStormME
	Actor kPlayer = Game.GetPlayer()
	If !kAb
		Return
	EndIf
	If abStart
		If !kPlayer.HasSpell(kAb)
			kPlayer.AddSpell(kAb, False)
		EndIf
	ElseIf kPlayer.HasSpell(kAb) && !(kOwnCast && kPlayer.HasMagicEffect(kOwnCast)) ; your own Eye of the Storm keeps going
		kPlayer.RemoveSpell(kAb)
	EndIf
EndFunction

; A party member's Eldritch Blood (called by the plugin): the same frenzy on the same enemy, so the game that controls
; its AI turns it. Its explosion stays on the caster's game (_00E_A2_EldritchBloodSC).
Function FrenzyFromPartner(Actor akVictim, Actor akTarget, Float afDamageMult, Int aiSeconds) global
	Spell kFrenzy = Game.GetFormFromFile(0x000EEF9D, "Skyrim.esm") as Spell ; _00E_A2_EldritchBloodVictimSP
	If !kFrenzy || !akVictim || akVictim.IsDead()
		Return
	EndIf
	kFrenzy.SetNthEffectMagnitude(0, afDamageMult)
	kFrenzy.SetNthEffectDuration(0, aiSeconds)
	kFrenzy.Cast(akVictim, akVictim)
	If akTarget && !akTarget.IsDead()
		Utility.Wait(0.2)
		akVictim.StartCombat(akTarget)
	EndIf
EndFunction

; A party member's conversation changed a companion's sympathy: show the message here too (the value is synced).
Function ShowSympathy(Actor akActor, Int aiChange) global
	_00E_SympathyControl kSympathy = _00E_PlayerFunctions.GetSympathyControl()
	If kSympathy && akActor
		kSympathy.ShowSympathyFeedback(akActor, aiChange)
	EndIf
EndFunction

; A shared value arrived from the party. Scripts that can't listen for mod events, such as
; quest scripts, get their updates here.
Function OnShared(String asKey, Int aiValue) global
	If StringUtil.Find(asKey, "bounty:") == 0
		ApplyBounty(Game.GetForm(StringUtil.Substring(asKey, 7) as Int) as Quest, aiValue)
	ElseIf StringUtil.Find(asKey, "nq22page:") == 0 && aiValue == 1
		_00E_NQ22_PageSC kPage = Game.GetForm(StringUtil.Substring(asKey, 9) as Int) as _00E_NQ22_PageSC
		If kPage
			kPage.TakenByParty()
		EndIf
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
			; the board's last bounty was paid: it's done for everyone, as on the payer's board
			If aiStage / 20 >= kBounty._00E_NQ_Bounty01_Quest01_mb_FormList.GetSize()
				kBounty._00E_NQ_Bounty01_Status = 10
				akQuest.Stop()
			Else
				kBounty._00E_NQ_Bounty01_Status = 0
			EndIf
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
	Else
		; 3 and 5 are finished AND shown: show it first, or completing a never-shown objective leaves it hidden
		If aiState == 3 || aiState == 5
			akQuest.SetObjectiveDisplayed(aiIndex, True)
		EndIf
		If aiState == 2 || aiState == 3
			akQuest.SetObjectiveCompleted(aiIndex, True)
		ElseIf aiState == 4 || aiState == 5
			akQuest.SetObjectiveFailed(aiIndex, True)
		EndIf
	EndIf
EndFunction

; The unstuck key, while guards fight you over a bounty they won't let you pay: pay it as surrendering would. Paid
; directly (gold removed, bounty cleared) rather than through PlayerPayCrimeGold, which can move you to the faction's
; jail; stolen items stay with you. Only if you can afford it, and only then do the guards stand down.
Function PayBounty(Int aiFactionID) global
	Faction kFaction = Game.GetForm(aiFactionID) as Faction
	Actor kPlayer = Game.GetPlayer()
	If !kFaction
		Return
	EndIf
	Int iBounty = kFaction.GetCrimeGold()
	If iBounty <= 0
		Return
	EndIf
	If kPlayer.GetGoldAmount() >= iBounty
		kPlayer.RemoveItem(Game.GetForm(0x0000000F), iBounty, True) ; silent: our own message says it
		kFaction.SetCrimeGold(0)
		kFaction.SetCrimeGoldViolent(0)
		kPlayer.StopCombatAlarm()
		Debug.Notification("Enderal AllTogether: bounty of " + iBounty + " paid")
	Else
		Debug.Notification("Enderal AllTogether: not enough gold for a bounty of " + iBounty)
	EndIf
EndFunction

; The unstuck key also ends music that a broken sequence left running; the plugin calls this for each music type the
; game has queued, and the game then picks the right music for where you are again.
Function RemoveMusic(Int aiFormID) global
	MusicType kMusic = Game.GetForm(aiFormID) as MusicType
	If kMusic
		kMusic.Remove()
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
		kFade.FadeToBlack() ; returns once the screen is black
	EndIf
	Game.GetPlayer().MoveTo(akDestination)
	Utility.Wait(0.5)
	If kFade
		kFade.FadeToBlackBack()
	EndIf
EndFunction
