Scriptname _00E_Theriantrophist_WolfFormSC extends activemagiceffect
; this script is responsible for the transformation process (without any stats calculation)


Float Property BlackAlchemistHealpercentage = 0.33 Autoreadonly Hidden
{Determines the amount of healing the player gets upon succesful transformation if he has the Black Alchemist perk.}

Explosion Property _00E_FS_Theriantrophist_TransEXP Auto
Race Property _00E_Theriantrophist_PlayerWerewolfRace Auto

Sound Property MAGRestorationFFFire Auto

_00E_Theriantrophist_WolfAttributes Property WolfAttributes Auto

Idle Property _00_Theriantrophist_WerewolfTransformBack Auto
Idle Property IdleWerewolfTransformation Auto
Idle Property WebIdleExit Auto
Idle Property _00E_IdleStomp Auto

_00E_FS_NQ11_Functions Property FS_NQ11 Auto

Static Property Xmarker Auto

Sound Property MAGConjurePortal Auto
ImageSpaceModifier Property _00E_ArkanistenfieberIMOD Auto
ImageSpaceModifier Property _00E_FS_Theriantrophist_TransformIMOD Auto
ImageSpaceModifier Property _00E_A2_EldritchBloodSelectionHoldIMOD Auto
ImageSpaceModifier Property _00E_A2_EldritchBloodSelectionIntroIMOD Auto

EffectShader Property _00E_Theriantrophist_TransformShader Auto

Spell Property _00E_FS_Theriantrophist_TransformSlow_01 Auto
Sound Property _00E_FS_Theriantrophist_PotionM Auto
Sound Property _00E_FS_NQR05_SlowMotion_OutroM Auto
Sound Property _00E_FS_NQR05_SlowMotion_IntroM Auto

_FS_TheriantrophistControlQuest Property controlQuest Auto

Race originalRace = None

Perk Property _00E_Class_Theriantrophist_P10_BlackAlchemist Auto

Actor Property PlayerREF Auto

; AFFINITY MODELS

ActorBase Property Player Auto

Armor Property _00E_FS_Theriantrophist_Skin_Brute Auto
Armor Property _00E_FS_Theriantrophist_Skin_Drifter Auto
Armor Property _00E_FS_Theriantrophist_Skin_Druid Auto
Armor Property _00E_FS_Theriantrophist_Skin_Nightwolf Auto
Armor Property _00E_FS_Theriantrophist_Skin_Ravager Auto
Armor Property _00E_FS_Theriantrophist_Skin_Soulcaller Auto
Armor Property _00E_FS_Theriantrophist_Skin_Scourge Auto
Armor Property SkinNakedWerewolfBeast Auto

Spell Property _00E_FS_Affinity_AbBrute Auto
Spell Property _00E_FS_Affinity_AbDrifter Auto
Spell Property _00E_FS_Affinity_AbDruid Auto
Spell Property _00E_FS_Affinity_AbNightwolf Auto
Spell Property _00E_FS_Affinity_AbRavager Auto
Spell Property _00E_FS_Affinity_AbScourge Auto
Spell Property _00E_FS_Affinity_AbSoulcaller Auto
Spell Property _00E_FS_Theriantrophist_WolfHealFXS Auto

; AFFINITY MODELS


Event OnEffectStart(Actor akTarget, Actor akCaster)
	; Skyrim Together: STR mirrors this effect onto the drinker's puppet on every other client, where
	; PlayerREF is the OTHER player. Only ever act on the local player itself.
	if akTarget != Game.GetForm(0x14) as Actor
		return
	endif


	if !FS_NQ11.IsObjectiveCompleted(20)
		FS_NQ11.SetObjectiveCompleted(20)
		FS_NQ11.SetCurrentStageID(20)
		FS_NQ11.ShowTutorial(3)
	endif
	
	Transform()
	
Endevent

Event OnEffectFinish(Actor akTarget, Actor akCaster)
	; Skyrim Together: STR mirrors this effect onto the drinker's puppet on every other client, where
	; PlayerREF is the OTHER player. Only ever act on the local player itself.
	if akTarget != Game.GetForm(0x14) as Actor
		return
	endif
	GoBackToNormal()
	controlQuest.GetPlayerAsWerewolfAlias().OnWolfFormSpellEnd()
Endevent

Function Transform()
{Transforms the player into the wolf, but does not calculate stats, unlock perks, ... and does not check if a transformation is legal}

	Game.SetInCharGen(true, true, false)
	Game.ForceThirdPerson()
	Game.DisablePlayerControls(true, true, true, false, true, true, true)

	If PlayerREF == None
		PlayerREF = Game.GetForm(0x14) as Actor
	EndIf
	
	_00E_FS_Theriantrophist_PotionM.Play(PlayerREF)
	originalRace = PlayerRef.getRace()
	_00E_Theriantrophist_TransformShader.Play(PlayerREF)
	
	if !PlayerREF.IsInCombat()	
		PlayerREF.GetActorBase().SetInvulnerable(True)
		Utility.Wait(0.1)
		PlayerREF.playIdle(IdleWerewolfTransformation)
		Utility.Wait(3.0)
		PlayerREF.GetActorBase().SetInvulnerable(False)
	endif
	
	ObjectReference explosionMarker = PlayerREF.PlaceAtMe(Xmarker)
	explosionMarker.SetPosition(PlayerREF.GetPositionX(), PlayerREF.GetPositionY(), (PlayerREF.GetPositionZ() + 100.0))
	explosionMarker.PlaceAtMe(_00E_FS_Theriantrophist_TransEXP)
	_00E_FS_Theriantrophist_TransformIMOD.Apply()
	
	if SKSE.GetVersion()
		; Re-equipping is fully working with SKSE
		PlayerREF.UnequipAll()
	endif
	
	PlayerREF.SetRace(_00E_Theriantrophist_PlayerWerewolfRace)

	if SKSE.GetVersion()
		if PlayerREF.HasSpell(_00E_FS_Affinity_AbBrute)
			Player.SetSkin(_00E_FS_Theriantrophist_Skin_Brute)
		elseif PlayerREF.HasSpell(_00E_FS_Affinity_AbDrifter)
			Player.SetSkin(_00E_FS_Theriantrophist_Skin_Drifter)
		elseif PlayerREF.HasSpell(_00E_FS_Affinity_AbDruid)
			Player.SetSkin(_00E_FS_Theriantrophist_Skin_Druid)
		elseif PlayerREF.HasSpell(_00E_FS_Affinity_AbNightwolf)
			Player.SetSkin(_00E_FS_Theriantrophist_Skin_Nightwolf)
		elseif PlayerREF.HasSpell(_00E_FS_Affinity_AbRavager)
			Player.SetSkin(_00E_FS_Theriantrophist_Skin_Ravager)
		elseif PlayerREF.HasSpell(_00E_FS_Affinity_AbScourge)
			Player.SetSkin(_00E_FS_Theriantrophist_Skin_Scourge)
		elseif PlayerREF.HasSpell(_00E_FS_Affinity_AbSoulcaller)
			Player.SetSkin(_00E_FS_Theriantrophist_Skin_Soulcaller)
		else
			Player.SetSkin(Player.GetRace().GetSkin())
		endif
		PlayerREF.QueueNiNodeUpdate()
	endif
	
	_00E_Theriantrophist_TransformShader.Stop(PlayerREF)
	explosionMarker.Delete()
	Game.EnablePlayerControls(true, true, false, true, true, true, true, true)
			
	WolfAttributes.updateAfterRaceSwitch(true)
	controlQuest.GetAffinityControl().OnTransform(true)
	Game.SetInCharGen(false, true, false)
	
	if PlayerREF.HasPerk(_00E_Class_Theriantrophist_P10_BlackAlchemist)
		
		PlayerREF.RestoreActorValue("Health", PlayerREF.GetBaseActorValue("Health")*BlackAlchemistHealpercentage)
		_00E_FS_Theriantrophist_WolfHealFXS.Cast(PlayerREF, PlayerREF)
		MAGRestorationFFFire.Play(PlayerREF)
		
	endif
	
	if PlayerREF.IsInCombat()
		Debug.SendAnimationEvent(PlayerREF, "idleReturnToDefault")
	EndIf
	
	;Failsafe in case something gets messed up, had bugs with the player copy in FS_NQ01
	If PlayerREF.GetActorBase().IsInvulnerable()
		PlayerREF.GetActorBase().SetInvulnerable(False)
	EndIf
	
EndFunction

Function GoBackToNormal()
{Transforms the player back to human, but does not calculate stats, unlock perks, ... and does not check if a transformation is legal}
	If PlayerREF == None
		PlayerREF = Game.GetForm(0x14) as Actor
	EndIf
	;PlayerREF.GetActorBase().SetSkin(SkinNakedWerewolfBeast)
	
	_00E_Theriantrophist_TransformShader.Play(PlayerREF)
	
	if PlayerREF.IsSneaking()
		PlayerREF.StartSneaking()
	endif
	
	Game.SetInCharGen(true, true, false)
	Game.DisablePlayerControls(true, true, true, false, true, true, true)
	
	PlayerREF.PlaceAtMe(_00E_FS_Theriantrophist_TransEXP) 
	
	PlayerREF.PlayIdle(_00_Theriantrophist_WerewolfTransformBack)
	
	_00E_FS_Theriantrophist_TransformIMOD.Apply()
	
	PlayerREF.SetRace(originalRace)
	PlayerREF.PlayIdle(_00E_IdleStomp)
	
	if SKSE.GetVersion()
		Player.SetSkin(Player.GetRace().GetSkin())
		PlayerREF.QueueNiNodeUpdate()
	endif
	
	Game.EnablePlayerControls()
	
	_00E_Theriantrophist_TransformShader.Stop(PlayerREF)
	WolfAttributes.updateAfterRaceSwitch(false)
	controlQuest.GetAffinityControl().OnTransform(false)
	Game.SetInCharGen(false, true, false)
	
	;Failsafe in case something gets messed up, had bugs with the player copy in FS_NQ01
	If PlayerREF.GetActorBase().IsInvulnerable()
		PlayerREF.GetActorBase().SetInvulnerable(False)
	EndIf
	
Endfunction
