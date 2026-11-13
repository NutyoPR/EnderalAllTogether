Scriptname MQ03_Functions extends Quest  

; This is the script on quest MQ04 (Wave Taming).

Import Utility
Import Math

int function _GetScriptVersion() Global
    return 1
endFunction

;=====================================================================================
;              							FUNCTIONS                  					 
;=====================================================================================

Function DisableBarrier()

	MQ04Barriere.Disable()
	MQ04_Rock02.Disable()

EndFunction

Function EnableLishari()

	if !(Self.IsObjectiveCompleted(20))
		Self.SetObjectiveDisplayed(20, False)
	EndIf

	_00E_MQ04_CrystalTouch.Play(MQ04_SC1_CrystalTrap)
	Game.DisablePlayerControls(true, true, true, false, true, true, true, true)
	Wait(0.4)
	_00E_MC_LishariREF.Enable()
	_00E_MC_LishariREF.MoveTo(MQ04_SC1_LishariAppearMarker)
	MQ04_SC1_LishariAppears.ForceStart()

EndFunction

Function DetonateMines()

	MQ04_SC1_CrystalTrap.PlaceAtMe(FXdustDropMedExplosion, 1)
	MQ04_CrystalTrap02.PlaceAtMe(_00E_MQ04_CrystalExplosion, 1)
	MQ04_CrystalTrap03.PlaceAtMe(_00E_MQ04_CrystalExplosion, 1)
	MQ04_SC1_CrystalTrap.PlaceAtMe(_00E_MQ04_CrystalExplosion, 1)
	MQ04_SC1_CrystalTrap.PlayImpactEffect(FXDragonLandingImpactSet, "crystaleffect01", 0, 0, -1, 90)
	MQ04_CrystalTrap02.PlayImpactEffect(FXDragonLandingImpactSet, "crystaleffect01", 0, 0, -1, 90)
	MAGShockExpImod.Apply()
	ObjectReference KnockBackMarker = PlayerREF.PlaceAtMe(XMarkerHeading)
	KnockBackMarker.MoveTo(PlayerRef, -(90.0 * Math.Sin(PlayerRef.GetAngleZ())), -(90.0 * Math.Cos(PlayerRef.GetAngleZ())), 0.0)
	KnockBackMarker.KnockAreaEffect(1, 1024)
	Game.ShakeCamera(afStrength = 2)
	PlayerREF.PlayIdle(PlayerStagger)
	MQ04_SC1_CrystalTrap.Disable()
	KnockBackMarker.Delete()
	Wait(3)
	FadeToBlackBackImod.ApplyCrossFade()
	Self.SetCurrentStageID(25)

EndFunction

Function UglyLishariFailsave()

	If GetCurrentStageID() < 38
		bDeadBodyFailsaveUsed = True
		MQ04_SC3_DeadBodyComment.ForceStart()
	Else
		SetCurrentStageID(40)
	EndIf

EndFunction

Function SetStageIfFailsaveUsed()

	If bDeadBodyFailsaveUsed
		SetCurrentStageID(40)
	Else
		Return
	EndIf
	
EndFunction

Function StartFollowing()
	_00E_MC_LishariREF.EvaluatePackage()
	_00E_Func_SetNPCAsCompanion.SetNPCAsCompanion(_00E_MC_LishariREF, true, 200, 100, 200)
EndFunction

Function GivePlayerSpell()
    PlayerREF.AddSpell(_00E_MQ04_FeuerloescherSpell)
EndFunction

Function StartSevfScene()
	Sevf.GetActorReference().PlayIdle(IdleCowerEnter)
	MQ04_SC4_SevfScreamsForHelp.ForceStart()
EndFunction

Function StartSC03()

	_00E_Func_SetNPCAsCompanion.SetNPCAsCompanion(_00E_MC_LishariREF, false)
	MQ04_SC3_DeadBodyComment.ForceStart()

EndFunction

Function KillSevf()
	_00E_MAGBottleBreak.Play(MQ04_SC4_SevfKillBurner)
	_00E_MAGFireballExplosionM.Play(MQ04_SC4_SevfKillBurner)
	MQ04_SC4_SevfKillBurner.PlaceAtMe(FireBallExp01, 1)
	MQ04_Sc4_SevfKillBurner.DisableNoWait()
	MQ04_Sc4_SevfKillBurner.PushActorAway(Sevf.GetActorReference(), 18.0)
	Sevf.GetActorReference().KillEssential(PlayerREF)
	Game.ShakeCamera(afStrength = 0.3)
	Utility.Wait(0.7)
	_00E_MAGFXFireOilIgniteLow.Play(MQ04_SC4_SevfKillFire)
	MQ04_SC4_SevfKillFire.Enable(True)
	Self.SetObjectiveCompleted(65)
	Self.SetObjectiveFailed(60)

EndFunction

Function SevfUseFlashpowder()

	Sevf.GetReference().PlaceAtMe(_00E_MQ04_FlashpowderExplosion)
	_00E_MQ04_FlashpowderFlash.Apply()
	Utility.Wait(0.7)
	Sevf.GetReference().Disable()
	Self.SetObjectiveCompleted(60)
	Self.SetObjectiveFailed(65)
	_00E_MQ04_SavedSevf.SetValueInt(1)

EndFunction

Function ActivateLift()
	
	If _00E_MC_LishariREF.IsDisabled()
		_00E_MC_LishariREF.Enable()
	EndIf
	
    MQ04_SC3_DeadBodyComment.Stop()
    _00E_MC_LishariREF.MoveTo(MQ04_SC6_LishariStandMarker)
	_00E_MC_LishariREF.EvaluatePackage()
	Wait(1)
	
	;Failsafe in case that the property is NONE like in report ERB-694. However, this was most likely caused by one of the installed mods of the player
	If MQ04_SC6_LishariLiftPlatform == None
		MQ04_SC6_LishariLiftPlatform = Game.GetFormFromFile(0x000329E8, "Skyrim.esm") as ObjectReference
	EndIf
	
	MQ04_SC6_LishariLiftPlatform.Activate(MQ04_SC6_LishariLiftPlatform)

EndFunction

Function FadeToBlackAndBack()

	Game.DisablePlayerControls()
	FadeToBlackImod.Apply()
	Wait(2.5)
	FadeToBlackImod.PopTo(FadeToBlackHoldImod)
	_00E_MC_LishariREF.MoveTo(MQ04_D4_LishariLeanMarker)
	_00E_MC_LishariREF.EvaluatePackage()
	PlayerREF.MoveTo(MQ04_D4_PlayerStandMarker)
	Wait(4)
	FadeToBlackHoldImod.PopTo(FadeToBlackBackImod)
	Self.SetCurrentStageID(80)
	_00E_MC_LishariREF.EvaluatePackage()

EndFunction

Function LishariStartRitualScene()

	Game.DisablePlayerControls()

	If _00E_MC_LishariREF.IsDisabled()
		_00E_MC_LishariREF.Enable()
		_00E_MC_LishariREF.MoveTo(MQ04_D4_LishariLeanMarker)
	EndIf
	
	MQ04_SC6_LishariPerformsRitual.ForceStart()

EndFunction

Function LevitatePlayer()

	Debug.SetGodMode(True)
	Game.DisablePlayerControls(True, True, True, False, True, True, True, True)
	Game.ForceFirstPerson()
	PlayerOrigin = PlayerREF.PlaceAtMe(XMarkerHeading, 1)
	float TranslateZ = PlayerRef.GetHeight() + 85.0
	TranslateMarker = PlayerREF.PlaceAtMe(XMarkerHeading, 1)
	TranslateMarker.MoveTo(PlayerRef, -(120.0 * Math.Sin(PlayerRef.GetAngleZ())), -(120.0 * Math.Cos(PlayerRef.GetAngleZ())), TranslateZ)
	PlayerREF.SplineTranslateToRef(TranslateMarker, 1.0, 30.0)
	_00E_MQ04_RitualAttachClouds.Play(PlayerREF)
	_00E_MagConjureReanimate.Play(PlayerREF)
	_00E_MQ04RitualImod.Apply()
	
EndFunction

Function RitualFailsave()

	Wait(2)
	PlayerREF.RemoveSpell(_00E_MQP03_MagicFeverSpell)
	ImageSpaceModifier.RemoveCrossFade(afFadeDuration = 3.0)
	PlayerREF.PlayIdle(TG05_GetUp)
	Wait(2)
	Game.EnablePlayerControls()
	Self.SetCurrentStageID(90)

EndFunction

ObjectReference Function GetTranslateMarker()
	Return PlayerOrigin
EndFunction

Function FinishUp()

	PlayerREF.UnequipSpell(_00E_MQ04_FeuerloescherSpell, 1)
	PlayerREF.UnequipSpell(_00E_MQ04_FeuerloescherSpell, 0)
	PlayerREF.RemoveSpell(_00E_MQ04_FeuerloescherSpell)
	PlayerREF.RemoveSpell(_00E_MQP03_MagicFeverSpell)
    _00E_MQ04_RitualAttachClouds.Stop(PlayerREF)
	EnvironmentScene02_StartBox.Enable()
	_00E_PlayerFunctions.GetSoundControl().RemoveSilence()
	_00E_EPHandler.GiveEP(__Config_RewardEXP)
	Self.SetObjectiveCompleted(70)
	NQ41.SetCurrentStageID(10)
	MQ05Prologue.Start()
	If MQ04_SC6_LishariLiftPlatform == None
		MQ04_SC6_LishariLiftPlatform = Game.GetFormFromFile(0x000329E8, "Skyrim.esm") as ObjectReference
	EndIf
	MQ04_SC6_LishariLiftPlatform.lock(0)
	PlayerOrigin.Delete()
	TranslateMarker.Delete()
	; calling the following line again, it seems to persist on the player for some reason
	_00E_MQ04_RitualAttachClouds.Stop(PlayerREF)
	
	; failsafe for issue 1536, fills empty aliases
	If MQ05PrologueFunctions == None
		MQ05PrologueFunctions = Game.GetFormFromFile(0x00033A5B, "Skyrim.esm") as _00E_MQ05Prologue_Functions
	EndIf
	MQ05PrologueFunctions.FillEmptyAliasesFailsafe()
	
EndFunction

Function GiveEPForStones()

	int TotalReward = (_00E_MQ04_StonesSaved.GetValueInt()*__Config_RewardEXP_PerStone)
	_00E_EPHandler.GiveEP(TotalReward)
	
EndFunction

;=====================================================================================
;              							STONE MINIGAME                 					 
;=====================================================================================

Function StartStoneMinigame()

	_00E_Music_CombatRegular.Add()
	PlayerREF.AddSpell(_00E_MQ04_FeuerloescherSpell)
	PlayerREF.EquipSpell(_00E_MQ04_FeuerloescherSpell, 0)
	_00E_MQ04_StonesLeft.SetValueInt(_00E_MQ04_MagicStones.GetSize())
	Self.UpdateCurrentInstanceGlobal(_00E_MQ04_StonesLeft)
	RegisterForSingleUpdate(StoneInterval)
	iIndex = _00E_MQ04_MagicStones.GetSize()
	
EndFunction

Function SaveStone(ObjectReference objSelfRef, ObjectReference objFireRef, ObjectReference objLightRef)

	_00E_MQ04_StonesSaved.SetValue(_00E_MQ04_StonesSaved.GetValueInt() + 1)
	UpdateObjectives()
	_00E_MQ03FireISM.Apply()
	int Extinguish = FXFireOut.Play(PlayerREF)
	Sound.SetInstanceVolume(Extinguish, 3)
	_00E_MQ04_StoneFragmentSaved.Show()
	objSelfRef.Disable(True)
	objFireRef.Disable(True)
	objLightRef.Disable(True)

EndFunction

Function DestroyStone(ObjectReference objSelfRef, ObjectReference objStoneRef)

	objStoneRef.KnockAreaEffect(0.5, 512)
	objStoneRef.PlaceAtMe(_00E_GiantShockExplosionHarmless)
	objSelfRef.DisableNoWait()
	objStoneRef.DisableNoWait()
	_00E_MQ04_StonesLeft.SetValueInt(_00E_MQ04_StonesLeft.GetValueInt() - 1)
	_00E_MQ04_StoneFragmentDestroyed.Show(StoneInterval)
	Game.ShakeCamera(afStrength = 0.4)
	UpdateObjectives()
	
EndFunction

Function UpdateObjectives()

	Self.UpdateCurrentInstanceGlobal(_00E_MQ04_StonesSaved)
	Self.UpdateCurrentInstanceGlobal(_00E_MQ04_StonesLeft)
	int AlreadySaved = _00E_MQ04_StonesSaved.GetValueInt()
	int StonesLeft = _00E_MQ04_StonesLeft.GetValueInt()
	
	if (AlreadySaved == StonesLeft) || (StonesLeft == 0)
		Self.SetObjectiveCompleted(40)
		Self.SetCurrentStageID(60)
		_00E_Music_CombatRegular.Remove()
	Else
		Self.SetObjectiveCompleted(40,0)
		Self.SetObjectiveDisplayed(40, True, True)
	EndIf

EndFunction

;=====================================================================================
;              							EVENTS                 					 
;=====================================================================================

Event OnUpdate()

	iIndex = iIndex - 1
	ObjectReference StoneToDestroy = _00E_MQ04_MagicStones.GetAt(iIndex) as ObjectReference
	StoneToCheck = StoneToDestroy as _00E_MQ04_Firescript
	
	bool Saved = StonetoCheck.CheckSaved()

	if Self.GetCurrentStageID() < 60
		if !(Saved)
			StoneToDestroy.Activate(StoneToDestroy)
			_00E_MQ04_StoneFragmentDestroyed.Show(StoneInterval as Int)
		EndIf
		
		if _00E_MQ04_StonesLeft.GetValueInt() > 0
			RegisterForSingleUpdate(StoneInterval) 
		EndIf
	Else
		; Enderal AllTogether: the minigame ended (possibly in a party member's game): stop its music here too
		_00E_Music_CombatRegular.Remove()
	EndIf

EndEvent

;=====================================================================================
;              							PROPERTIES                 					 
;=====================================================================================

bool bDeadBodyFailsaveUsed

int UpdateCounter
int iIndex

int Property __Config_RewardEXP_PerStone Auto
{How much EP does the player get for every stone he saves for Lishari? Maximum: 7 Stones!}
int Property __Config_RewardEXP Auto
{How much EP does the player get on quest completion}

ObjectReference Property TranslateMarker Auto Hidden
ObjectReference Property PlayerOrigin Auto Hidden

_00E_MQ05Prologue_Functions Property MQ05PrologueFunctions Auto

Float Property StoneInterval Auto
{The interval in which a fire has destroyed a stone}

Formlist Property _00E_MQ04_MagicStones Auto

VisualEffect Property _00E_MQ04_RitualAttachClouds Auto
Sound Property _00E_MagConjureReanimate Auto

GlobalVariable Property _00E_MQ04_StonesLeft Auto
GlobalVariable Property _00E_MQ04_StonesSaved Auto

Message Property _00E_MQ04_StoneFragmentSaved Auto
Message Property _00E_MQ04_StoneFragmentDestroyed Auto

Idle Property TG05_GetUp Auto
Idle Property IdleCowerEnter Auto
Idle Property PlayerStagger Auto

Quest Property MQ05Prologue Auto
Quest Property NQ41 Auto

Actor Property PlayerREF Auto
Actor Property _00E_MC_LishariREF Auto

ReferenceAlias Property Sevf Auto

Scene Property MQ04_SC4_SevfScreamsForHelp Auto
Scene Property MQ04_SC6_LishariPerformsRitual Auto
Scene Property MQ04_SC3_DeadBodyComment Auto

Spell Property _00E_MQ04_FeuerloescherSpell Auto
Spell Property _00E_MQP03_MagicFeverSpell Auto


ObjectReference Property MQ04_SC1_LishariAppearMarker Auto
ObjectReference Property MQ04_SC1_CrystalTrap Auto
ObjectReference Property MQ04_CrystalTrap02 Auto
ObjectReference Property MQ04_CrystalTrap03 Auto
ObjectReference Property MQ04_SC4_SevfKillFire Auto
ObjectReference Property MQ04_SC6_LishariLiftPlatform Auto
ObjectReference Property MQ04_SC6_LishariStandMarker Auto
ObjectReference Property MQ04_D4_PlayerStandMarker Auto
ObjectReference Property MQ04_D4_LishariLeanMarker Auto
ObjectReference Property MQ04Barriere Auto
ObjectReference Property MQ04_Rock02 Auto
ObjectReference Property EnvironmentScene02_StartBox Auto

ImageSpaceModifier Property FadeToBlackIMOD Auto
ImageSpaceModifier Property FadeToBlackHoldIMOD Auto
ImageSpaceModifier Property FadeToBlackBackIMOD Auto

ImpactDataSet Property FXDragonLandingImpactSet Auto

GlobalVariable Property _00E_MQ04_SavedSevf Auto
ObjectReference Property MQ04_SC4_SevfKillBurner Auto

Explosion Property _00E_MQ04_CrystalExplosion Auto
Explosion Property FXdustDropMedExplosion Auto
Explosion Property FireBallExp01 Auto
Explosion Property _00E_MQ04_FlashpowderExplosion Auto
Explosion Property _00E_GiantShockExplosionHarmless Auto

_00E_MQ04_Firescript Property StonetoCheck Auto Hidden

Scene Property MQ04_SC1_LishariAppears Auto

Static Property XMarkerHeading Auto

MusicType Property _00E_Music_CombatRegular Auto

Sound Property _00E_MQ04_CrystalTouch Auto
Sound Property _00E_MAGFireballExplosionM Auto
Sound Property _00E_MAGBottleBreak Auto
Sound Property _00E_MAGFXFireOilIgniteLow Auto
Sound Property FXFireOut Auto

ImageSpaceModifier Property MAGShockExpImod Auto
ImageSpaceModifier Property _00E_MQ04_FlashpowderFlash Auto
ImageSpaceModifier Property _00E_MQ04RitualImod Auto
ImageSpaceModifier Property _00E_MQ03FireISM Auto