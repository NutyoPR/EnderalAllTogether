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

; True on exactly one machine in the party (the lowest player ID), and always when playing alone or without the plugin
; installed. Scenes use it so only one game moves NPCs around.
Bool Function IsDesignatedPlayer() global native

; A scene let go of the player here (fade gone, controls back, vision over): the party's games do the same.
Function ShareRelease() global native

; The player travelled (Myrad): the party's games follow to the same destination.
Function ShareTravel(ObjectReference akDestination) global native


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
	EndIf
	kPlayer.SetAlpha(1.0)
	kPlayer.SetGhost(False)
	Game.EnablePlayerControls()
	Game.SetPlayerAIDriven(False)
	Game.SetHUDCartMode(False)
	Game.ShowFirstPersonGeometry(True)
EndFunction

; The unstuck key: the same release, with a notification.
Function Unstuck() global
	Release()
	Debug.Notification("Enderal AllTogether: unstuck")
EndFunction

; Brings the player to where a party member just travelled, behind a short fade.
Function ArriveAt(ObjectReference akDestination) global
	; Not while you're in a scene, meditating or otherwise without control: being pulled out would break it.
	If !akDestination || !Game.IsMovementControlsEnabled()
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
