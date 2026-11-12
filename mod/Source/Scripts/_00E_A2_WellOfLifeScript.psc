Scriptname _00E_A2_WellOfLifeScript extends activemagiceffect  
{Once the player would die, his life is automatically restored to a set percentage of his base life.}

Import _00E_TalentLibrary

;=====================================================================================
;              							EVENTS                 					 
;=====================================================================================

Event OnEnterBleedout()
	if GetTargetActor() != Game.GetForm(0x14) as Actor
		return
	endif

	Game.ForceThirdPerson()
	RestoreHealth()
	Self.Dispel()
	
EndEvent

Event OnEffectStart(Actor akTarget, Actor akCaster)
	STR_IsLocalTarget = (akTarget == Game.GetForm(0x14) as Actor)
	if !STR_IsLocalTarget
		return
	endif

	iKillMove = _00E_KillMove.Off()
	MAGPowerRacialHitskinM.Play(PlayerREF)
	AudioCategorySFXDeath.Mute()
	PlayerREF.GetActorBase().SetEssential(True)
	iTriggerHealthPercentage = (_00E_A2_WellOfLifeSP.GetNthEffectMagnitude(3)/100)

EndEvent

Event OnEffectFinish(Actor akTarget, Actor akCaster)
	if akTarget != Game.GetForm(0x14) as Actor
		return
	endif

	AudioCategorySFXDeath.UnMute()
	PlayerREF.GetActorBase().SetEssential(False)
	_00E_KillMove.SetValue(iKillMove)
	
EndEvent


;=====================================================================================
;              							FUNCTIONS                 					 
;=====================================================================================

Function RestoreHealth()

	_00E_A2_WellOfLifeAttachEffect.Play(PlayerREF)
	_00E_A2_WellOfLifeExplosionIMOD.Apply()
	_00E_MagicCharge02M.Play(PlayerREF)
	_00E_A2_ChaosruneImplosionSoundM.Play(PlayerREF)
	
	Utility.Wait(4)

	int iIndex = (GetPlayerTalentLevel(_00E_Class_Espionage_P09b_Talent_Ghostwalk, _00E_Class_Espionage_P09b_Talent_Ghostwalk2, _00E_Class_Espionage_P09b_Talent_Ghostwalk3) - 1)
	float iHealAmount = (PlayerREF.GetBaseActorValue("Health")*(_00E_A2_WellOfLifeSP.GetNthEffectMagnitude(iIndex)/100))
	ObjectReference EffectExplosion = PlayerREF.PlaceAtMe(_00E_A2_WellOfLifeExplosionVisual, 1)
	EffectExplosion.MoveTo(PlayerREF, 0.0, 0.0, - 50.0)
	MAGPowerRacialPacifyFire.Play(PlayerREF)
	PlayerREF.KnockAreaEffect(1.0, 1024)
	PlayerREF.RestoreActorValue("Health", iHealAmount+30)
	
	If PlayerREF.HasMagicEffect(_50E_MSet_5Pieces_ME)
		ScanForEnemy(iHealAmount)
	EndIf
	
	Utility.Wait(1)
	_00E_A2_WellOfLifeAttachEffect.Stop(PlayerREF)
	
EndFunction

Function ScanForEnemy(float fDamage)
	
	int iIndexScan = 0
	Actor[] nearbyenemies = new Actor[10]
	
	while iIndexScan < 10
		Actor RandomActor =  Game.FindRandomActorFromRef(PlayerREF, 1000)
		If RandomActor.GetFactionReaction(PlayerREF) == 1
			nearbyenemies[iIndexScan] = RandomActor
		Else
			nearbyenemies[iIndexScan] = None
		EndIf
		iIndexScan += 1
	EndWhile
	
	While iIndexScan > 0
		If nearbyenemies[iIndexScan] == None
			iIndexScan -= 1
		Else
			Actor RandomEnemy = nearbyenemies[iIndexScan]
			RandomEnemy.DamageActorValue("Health", fDamage)
			iIndexScan = 0
		EndIf
	EndWhile
	
EndFunction


;=====================================================================================
;              							PROPERTIES                					 
;=====================================================================================

int iKillMove
float iTriggerHealthPercentage

Explosion Property _00E_A2_WellOfLifeExplosionVisual Auto
VisualEffect Property _00E_A2_WellOfLifeAttachEffect Auto
ImageSpaceModifier Property _00E_A2_WellOfLifeExplosionIMOD Auto

GlobalVariable Property KillMove Auto

Actor Property PlayerREF Auto

SoundCategory Property AudioCategorySFXDeath Auto

Sound Property MAGPowerRacialPacifyFire Auto
Sound Property _00E_A2_ChaosruneImplosionSoundM Auto
Sound Property MAGPowerRacialHitskinM Auto
Sound Property _00E_MagicCharge02M Auto

Spell Property _00E_A2_WellOfLifeSP Auto

Perk Property _00E_Class_Espionage_P09b_Talent_Ghostwalk Auto
Perk Property _00E_Class_Espionage_P09b_Talent_Ghostwalk2 Auto
Perk Property _00E_Class_Espionage_P09b_Talent_Ghostwalk3 Auto

MagicEffect Property _50E_MSet_5Pieces_ME Auto

; Skyrim Together: STR mirrors this effect onto the caster's puppet on other clients. This flag marks
; whether this copy runs on the local player; every event is skipped for the puppet's copy.
Bool STR_IsLocalTarget = False
