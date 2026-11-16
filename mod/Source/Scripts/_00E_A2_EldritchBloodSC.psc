Scriptname _00E_A2_EldritchBloodSC extends activemagiceffect  

Import _00E_TalentLibrary
Import Utility

int function _GetScriptVersion() Global
	return 1
endFunction

;=====================================================================================
;              							EVENTS                  					 
;=====================================================================================

Event OnHit(ObjectReference akAggressor, Form akSource, Projectile akProjectile, bool abPowerAttack, bool abSneakAttack, bool abBashAttack, bool abHitBlocked)

	if akSource == _00E_A2_SkyfallBoltSP 
		if (Victim.GetActorValue("Health") - _00E_A2_SkyfallBoltSP.GetNthEffectMagnitude(0)) <= - 10
			bSynergySkyfallExplosion = True
		EndIf
	EndIf

EndEvent


Event OnEffectStart(Actor akTarget, Actor akCaster)

	Actor PlayerRef = Game.GetForm(0x14) as Actor
	TalentLevel = GetPlayerTalentLevel(_00E_Class_LifeAndDeath_P09b_Talent_EldritchBlood, _00E_Class_LifeAndDeath_P09b_Talent_EldritchBlood2, _00E_Class_LifeAndDeath_P09b_Talent_EldritchBlood3)
	
	Game.ShowFirstPersonGeometry()
	Victim = akTarget
	; Enderal AllTogether: the caster's game already holds the victim in this alias (it marked it). On the other games
	; this effect runs only so the game that controls the victim's AI turns it (EnderalAllTogether.FrenzyFromPartner).
	bEATOwnCast = A2_EldritchBlood_Victim.GetActorReference() == akTarget
	A2_EldritchBlood_Victim.ForceRefTo(Victim)
	
	bIsInPlayerFaction = Victim.IsInFaction(PlayerAlliesFaction)
	
	; Strip Victim off all its factions
	VictimFactions = Victim.GetFactions(-128, 127)
	VictimFactionRanks = CreateIntArray(VictimFactions.Length)
	Int i = 0
	While i < VictimFactions.Length
		If VoiceFactions.HasForm(VictimFactions[i]) ; Skip voice factions
			VictimFactions[i] = None
		Else
			VictimFactionRanks[i] = Victim.GetFactionRank(VictimFactions[i])
			Victim.RemoveFromFaction(VictimFactions[i])
		EndIf
		i += 1
	EndWhile 

	Victim.AddToFaction(PlayerAlliesFaction)
	
	Victim.SetRelationshipRank(PlayerRef, 3)
	
	Victim.SetActorValue("Confidence", 4)
	Victim.SetActorValue("Aggression", 2)
	
	AdjustDamageMult(Victim)
	
	_00E_A2_EldritchBloodParticelAttachVFX.Play(Victim)
	
	Victim.StopCombat()
	
	If A2_EldritchBlood_VictimTarget.GetActorReference()
		A2_EldritchBlood_Victim.GetActorReference().StartCombat(A2_EldritchBlood_VictimTarget.GetActorReference())
	ElseIf PlayerREF.GetCombatTarget()
		A2_EldritchBlood_Victim.GetActorReference().StartCombat(PlayerREF.GetCombatTarget())
	EndIf
	
EndEvent


Event OnEffectFinish(Actor akTarget, Actor akCaster)

	Victim.SetActorValue("attackdamagemult", fInitialAttackDamageMult)
	Victim.SetActorValue("destructionpowermod", fInitialDestructionPowerMod)

	_00E_A2_EldritchBloodMarkedFXS.Stop(Victim)
	A2_EldritchBlood_Victim.Clear()
	A2_EldritchBlood_VictimTarget.Clear()
	_00E_A2_EldritchBloodParticelAttachVFX.Stop(Victim)

	; Restore old factions of Victim
	if ! bIsInPlayerFaction
		Victim.RemoveFromFaction(PlayerAlliesFaction)
	endif
	
	Int i = 0
	While i < VictimFactions.Length
		If VictimFactions[i]
			Victim.AddToFaction(VictimFactions[i])
			If VictimFactionRanks[i] != 0
				Victim.SetFactionRank(VictimFactions[i], VictimFactionRanks[i])
			EndIf
		EndIf
		i += 1
	EndWhile

	Victim.EvaluatePackage()
	
EndEvent

Event OnDying(Actor akKiller)
	
	If bEATOwnCast ; Enderal AllTogether: the explosion happens once, on the caster's game
		Explode()
	EndIf
	Self.Dispel()

EndEvent

;=====================================================================================
;              							FUNCTIONS                  					 
;=====================================================================================

Function AdjustDamageMult(Actor akVictim) ; Enderal AllTogether: renamed from Victim (shadowed the script variable)

	float iDamageMultiplicator = GetMagnitude()
	
	fInitialAttackDamageMult = akVictim.GetActorValue("attackdamagemult")
	fInitialDestructionPowerMod = akVictim.GetActorValue("destructionpowermod")

	akVictim.SetActorValue("attackdamagemult", fInitialAttackDamageMult * iDamageMultiplicator)
	akVictim.SetActorValue("destructionpowermod", fInitialDestructionPowerMod + (100 * iDamageMultiplicator))

EndFunction

Function Explode()
	
	Victim.SetCriticalStage(Victim.CritStage_DisintegrateStart)
	
	If bSynergySkyfallExplosion
		AtronachUnsummonDeathFXS.Play(Victim)
	Else
		_00E_A1_DevourSoul_DisintegrateFXS.Play(Victim)
	EndIf
	
	Wait(1.5)
	Game.ShakeCamera(afStrength = 1.0)
	ObjectReference EXPMarker = Victim.PlaceAtMe(XMarker, 1)
	EXPMarker.MoveTo(Victim, 0.0, 0.0, 50.0)
	
	If bSynergySkyfallExplosion
	
		bSynergySkyfallExplosion = False
		If TalentLevel == 1
			EXPMarker.PlaceAtMe(_00E_MAGEldritchShockExplosion, 1)
		Elseif TalentLevel == 2
			EXPMarker.PlaceAtMe(_00E_MAGEldritchShockExplosion02, 1)
		Elseif TalentLevel == 3
			EXPMarker.PlaceAtMe(_00E_MAGEldritchShockExplosion03, 1)
		EndIf
		_00E_A2_SynergyEldritchBloodSkyfallDMGEnch.SetNthEffectMagnitude(0, (_00E_A2_EldritchBloodEnchantment.GetNthEffectMagnitude(0)*1.5))
		_00E_MQ16_EchoScreamsM.Play(Victim)
		EXPMarker.PlaceAtMe(_00E_A2_SynergyEldritchBloodSkyfallExp, 1)
		Victim.AttachAshPile(_00E_NPCOorbayaAshPile)
		Victim.KnockAreaEffect(0.5, 256)
		
		If _00E_Synergy_EldritchBloodSkyfall.GetValueInt() == 0
			_00E_Synergy_EldritchBloodSkyfall.SetValueInt(1)
			_00E_PlayerFunctions.GetSkillControl().ShowSynergyMessage()
		EndIf
		
	Else
		
		If TalentLevel == 1
			EXPMarker.PlaceAtMe(_00E_MAGEldritchShockExplosion, 1)
		Elseif TalentLevel == 2
			EXPMarker.PlaceAtMe(_00E_MAGEldritchShockExplosion02, 1)
		Elseif TalentLevel == 3
			EXPMarker.PlaceAtMe(_00E_MAGEldritchShockExplosion03, 1)
		EndIf
		EXPMarker.PlaceAtMe(_00E_FS_MAGGoreExplosion, 1)
		_00E_A2_ShatterSoulExpIMOD.Apply()
		Victim.AttachAshPile(_00E_EldritchPile)
		
	EndIf
	
	ObjectReference VictimREF = Victim as ObjectReference
	(VictimREF as _00E_EPOnDeath).HasBlameSpell = true
	Victim.SetAlpha(0.0, true)
	Victim.Kill(Victim)
	Victim.SetCriticalStage(Victim.CritStage_DisintegrateEnd)
	EXPMarker.Delete()
		
EndFunction

;=====================================================================================
;              							PROPERTIES                  					 
;=====================================================================================

float fInitialAttackDamageMult
float fInitialDestructionPowerMod

Faction[] VictimFactions
Int[] VictimFactionRanks
FormList Property VoiceFactions Auto
Faction Property PlayerAlliesFaction Auto
Faction Property EPFaction Auto

int TalentLevel
bool bEATOwnCast

bool bSynergySkyfallExplosion

Actor Victim
Perk iPerk

Perk Property _00E_A2_EldritchBloodPerk01 Auto
Perk Property _00E_A2_EldritchBloodPerk02 Auto
Perk Property _00E_A2_EldritchBloodPerk03 Auto

Sound Property _00E_MQ16_EchoScreamsM Auto

Enchantment Property _00E_A2_EldritchBloodEnchantment Auto
Enchantment Property _00E_A2_SynergyEldritchBloodSkyfallDMGEnch Auto

Perk Property _00E_Class_LifeAndDeath_P09b_Talent_EldritchBlood Auto
Perk Property _00E_Class_LifeAndDeath_P09b_Talent_EldritchBlood2 Auto
Perk Property _00E_Class_LifeAndDeath_P09b_Talent_EldritchBlood3 Auto

Static Property XMarker Auto

Activator Property _00E_EldritchPile Auto
Activator Property _00E_NPCOorbayaAshPile Auto

VisualEffect Property _00E_A2_EldritchBloodParticelAttachVFX Auto

Spell Property _00E_A2_EldritchBloodSP Auto
Spell Property _00E_A2_SkyfallBoltSP Auto

GlobalVariable Property _00E_Synergy_EldritchBloodSkyfall Auto

EffectShader Property _00E_A1_DevourSoul_DisintegrateFXS Auto
EffectShader Property _00E_A2_EldritchBloodMarkedFXS Auto
EffectShader Property AtronachUnsummonDeathFXS Auto

ImageSpaceModifier Property _00E_A2_ShatterSoulExpIMOD Auto

ReferenceAlias Property A2_EldritchBlood_Victim Auto
ReferenceAlias Property A2_EldritchBlood_VictimTarget Auto

Explosion Property _00E_MAGEldritchShockExplosion Auto
Explosion Property _00E_MAGEldritchShockExplosion02 Auto
Explosion Property _00E_MAGEldritchShockExplosion03 Auto
Explosion Property _00E_A2_SynergyEldritchBloodSkyfallExp Auto
Explosion Property _00E_FS_MAGGoreExplosion Auto

bool bIsInPlayerFaction
