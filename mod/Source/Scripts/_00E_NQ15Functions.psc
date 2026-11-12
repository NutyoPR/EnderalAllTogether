Scriptname _00E_NQ15Functions extends Quest  Conditional

Import Utility

;=====================================================================================
 ;           							FUNCTIONS                 					 
;=====================================================================================


Function SetTime()

	RegisterForSingleUpdateGameTime(0.1)
	GameHoursAfterQuest = GameHour.GetValue() as float
	
EndFunction

Event OnUpdateGameTime() ; because of how we registered, this event occurs every 30 minutes of game time

	if GameHour.GetValue() as float >= GameHoursAfterQuest + 1.0
		SetCurrentStageID(50)
		UnregisterForUpdateGameTime()
	endif
	
endEvent

Function InitMeldorScene()

	Game.SetHUDCartMode(true)
	FadeToBlackImod.Apply()
	Wait(1.5)
	FadeToBlackHoldImod.ApplyCrossFade()
	Wait(1.0)
	; Enderal AllTogether: in a party every game runs this; only one moves the NPCs and starts the scene, so Meldor
	; isn't placed twice and left frozen. Without the plugin IsLoaded() is False and this behaves as before.
	Bool bPlacesNPCs = !EnderalAllTogether.IsLoaded() || EnderalAllTogether.IsDesignatedPlayer()
	If bPlacesNPCs
		MeldorRef.Enable()
		Actor Meldor = MeldorRef as Actor
		Meldor.SetGhost(True)
	EndIf
	PlayerREF.MoveTo(NQ15_SC01_PlayerStartMarker)
	NQ15_SC01_BedroomDoorREF.SetOpen(True)
	If bPlacesNPCs
		MayorRef.MoveTo(NQ15MayorMarker)
		MeldorRef.MoveTo(NQ15MeldorMarker002)
	EndIf
	Wait(1.0)
	FadeToBlackBackImod.ApplyCrossFade()
	Wait(1.0)
	If bPlacesNPCs
		NQ15_SC1.ForceStart()
	EndIf
	Game.EnablePlayerControls()
	Game.SetHUDCartMode(false)
	
EndFunction

Function EnableDrownedWoman()

	Actor Meldor = MeldorRef as Actor
	Meldor.SetGhost(False)
	NQ15Woman.Enable()

EndFunction

Function StartVision()
	_00E_PlayerFunctions.GetVisionControl().VisionEffectNoTimestop(None, _00E_NQ15_ActorsVision)
EndFunction

Function EndVision()
	_00E_PlayerFunctions.GetVisionControl().VisionEffectNoTimestopStop(None, _00E_NQ15_ActorsVision, true)
EndFunction

Function StartVisionNoActors()
	_00E_PlayerFunctions.GetVisionControl().VisionEffectNoTimestop(None, None)
EndFunction

function EndVisionNoActors()
	_00E_PlayerFunctions.GetVisionControl().VisionEffectNoTimestopStop(None, None)
EndFunction

Function StartSC3()
	NQ15_SC3.ForceStart()
	Game.DisablePlayerControls()
EndFunction

Function EndSC3()

	Game.EnablePlayerControls()
	PentasKey.Enable()
	_00E_TeleportVanishShader.Play(NQ15Woman)
	Wait(3)
	NQ15Woman.Disable()
	
EndFunction

Function NQ15_SC4Start()

	NQ15Woman.Enable()
	NQ15_SC4.ForceStart()
	
EndFunction

Function DisableWOman()

	_00E_TeleportVanishShader.Play(NQ15Woman)
	Wait(3)
	NQ15Woman.Disable()
	NQ15Auftrag.Enable()
	
EndFunction

Function SetUpMeldorScene()

	NQ15Soeldner.EnableNoWait()
	MeldorRef.Enable()
	MeldorRef.MoveTo(NQ15MeldorMarker02)
	MeldorRef.MoveTo(NQ15_SC05_MeldorStartMarker)
	NQ15_SC5.ForceStart()
	
EndFunction

Function PortWoman()

	if Player == NONE
		Player.ForceRefTo(Game.GetForm(0x00000014) as Actor)
	EndIf

	NQ15Woman.Enable()
	NQ15Woman.SetAlpha(0.0)
	NQ15Woman.MoveTo(NQ15WomanMarker)

	; SE: Need to wait for 3D to load before playing the shader
	_00E_Func_WaitForRef.WaitForReferenceToLoad(NQ15Woman)
	_00E_TeleportReappearShader.Play(NQ15Woman)

	; SE: The shader is short, 2 seconds is too long
	Wait(1.0)
	NQ15Woman.SetAlpha(1)
	
EndFunction

Function MarkAsNotFair()
	NQ15IsNotFair = true
EndFunction

Function GiveAmulet()
	PlayerREF.AddItem(Amulet, 1)
EndFunction

function GiveGold()
	PlayerREF.AddItem(Gold001, Gold)
EndFunction

Function LevitateMeldor()

	Actor Meldor = MeldorRef as Actor
	Debug.SendAnimationEvent(Meldor, "IdleDA02BoethiahPostEnter")
	NQ15Woman.PlayIdle(IdleCO2Ceremony2Blessing)
	_00E_Horror_Ghosts_01M.Play(NQ15Woman)
	Meldor.SetHeadTracking(false)
	Meldor.SetGhost(true)
	Wait(1.5)
	MeldorREF.Say(NQ15_D5_Meldor_PainTopic)
	Wait(4)
	_00E_HighOnesDisintegrate.Play(MeldorRef)
	Wait(1.5)
	ObjectReference KillMarkerMeldor = MeldorREF.PlaceAtMe(XMarker)
	_00E_A2_PrimalForce_ScreamMarkerMale.Play(KillMarkerMeldor)
	NQ15_BloodParentREF.Enable()
	MeldorRef.PlaceAtMe(ExplosionIllusionDark01)
	MeldorRef.PlaceAtMe(_00E_FS_MAGGoreExplosion)
	Game.ShakeCamera(None,1,1)
	Game.TriggerScreenBlood(10)
	MeldorRef.KnockAreaEffect(1, 1024)
	Wait(0.2)
	Meldor.KillEssential(Meldor)
	MeldorRef.DisableNoWait()
	SetCurrentStageID(240)
	
	_00E_Func_AIWalk.PlayerAIWalkStop()
	
EndFunction

Function DespawnWoman()

	_00E_TeleportVanishShader.Play(NQ15Woman)
	Wait(3)
	NQ15Woman.Disable()
	Wait(5)
	_00E_PlayerFunctions.GetSoundControl().RemoveSilence()
	Wait(3)
	Weather.ReleaseOverride()

EndFunction

Function EnableContainerAndGiveKey()

	NQ15Container.Enable()
	PlayerREF.AddItem(_00E_NQ15ContainerKey, 1)
	_00E_PlayerFunctions.GetSoundControl().RemoveSilence()
	Weather.ReleaseOverride()
	
EndFunction

;=====================================================================================
 ;           							PROPERTIES                 					 
;=====================================================================================

EffectShader Property _00E_TeleportVanishShader Auto
EffectShader Property _00E_TeleportReappearShader Auto
EffectShader Property _00E_HighOnesDisintegrate Auto

ReferenceAlias Property Player Auto

ObjectReference Property MeldorRef Auto
ObjectReference Property NQ15MayorMarker Auto
ObjectReference Property NQ15MeldorMarker02 Auto
ObjectReference Property NQ15WomanMarker Auto
ObjectReference Property PentasKey Auto
ObjectReference Property NQ15Container Auto
ObjectReference Property NQ15_SC01_PlayerStartMarker Auto
ObjectReference Property NQ15MeldorMarker002 Auto
ObjectReference Property NQ15_SC05_MeldorStartMarker Auto
ObjectReference Property NQ15_SC01_BedroomDoorREF Auto
ObjectReference Property NQ15_BloodParentREF Auto

Actor Property PlayerREF Auto

Topic Property NQ15_D5_Meldor_PainTopic Auto

ObjectReference Property NQ15Soeldner Auto
GlobalVariable Property GameHour Auto

Float GameHoursAfterQuest 

Key Property _00E_NQ15ContainerKey Auto
Idle Property IdleCO2Ceremony2Blessing Auto
Explosion Property ExplosionIllusionDark01 Auto
Explosion Property _00E_FS_MAGGoreExplosion Auto
Scene Property NQ15_SC1 Auto
Scene Property NQ15_SC3 Auto
Scene Property NQ15_SC4 Auto
Sound Property _00E_A2_PrimalForce_ScreamMarkerMale Auto
Sound Property _00E_Horror_Ghosts_01M Auto
Scene Property NQ15_SC5 Auto
Armor Property Amulet Auto
ImageSpaceModifier Property FadeToBlackImod Auto
ImageSpaceModifier Property FadeToBlackBackImod Auto
ImageSpaceModifier Property FadeToBlackHoldImod Auto
ObjectReference Property NQ15Auftrag Auto
ObjectReference Property MayorRef Auto
Formlist Property _00E_NQ15_ActorsVision Auto
Int Property Gold Auto
MiscObject Property Gold001 Auto
Actor Property NQ15Woman Auto
Static Property XMarker Auto
Bool Property NQ15IsNotFair  Auto  Conditional