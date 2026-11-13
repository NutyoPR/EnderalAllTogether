Scriptname _00E_A2_GhostwalkCloakSC extends activemagiceffect  

Import _00E_TalentLibrary

Event OnEffectStart(Actor akTarget, Actor akCaster)
	; Enderal AllTogether: Skyrim Together copies this to the other games (effect on the player's copy, or a replayed
	; activation); only the player it's really for may run it, or it would act on whoever is local there.
	If akTarget != Game.GetForm(0x14) as Actor
		Return
	EndIf

	int iIndex = GetPlayerTalentLevel(_00E_Class_Infiltrator_P08_B_Talent_Ghostwalk_01, _00E_Class_Infiltrator_P08_B_Talent_Ghostwalk_02, _00E_Class_Infiltrator_P08_B_Talent_Ghostwalk_03)
	iCritChanceBonus = _00E_FS_A2_Ghostwalk_NewSP.GetNthEffectMagnitude(iIndex)
	PlayerREF.ModActorValue("CritChance", iCritChanceBonus)
	_00E_FS_Tharael_DematerializeFXS.Play(akTarget)
	_00E_EspionageFXS.Play(akTarget)

EndEvent

Event OnEffectFinish(Actor akTarget, Actor akCaster)
	; Enderal AllTogether: Skyrim Together copies this to the other games (effect on the player's copy, or a replayed
	; activation); only the player it's really for may run it, or it would act on whoever is local there.
	If akTarget != Game.GetForm(0x14) as Actor
		Return
	EndIf

	_00E_FS_NQR05_TharaelMaterializeFXS.Play(akTarget)

	if PlayerREF.HasMagicEffect(_00E_A1_InvisibilityME)
		PlayerREF.DispelSpell(_00E_A1_InvisibilitySP)
	endif

	PlayerREF.ModActorValue("CritChance", - iCritChanceBonus)
	Utility.Wait(0.3)
	_00E_FS_Tharael_DematerializeFXS.Stop(akTarget)
	_00E_FS_NQR05_TharaelMaterializeFXS.Stop(akTarget)
	_00E_EspionageFXS.Stop(akTarget)
	
EndEvent

float iCritChanceBonus

Spell Property _00E_FS_A2_Ghostwalk_NewSP Auto
Spell Property _00E_A1_InvisibilitySP Auto
MagicEffect Property _00E_A1_InvisibilityME Auto

Actor Property PlayerREF Auto

Perk Property _00E_Class_Infiltrator_P08_B_Talent_Ghostwalk_01 Auto
Perk Property _00E_Class_Infiltrator_P08_B_Talent_Ghostwalk_02 Auto
Perk Property _00E_Class_Infiltrator_P08_B_Talent_Ghostwalk_03 Auto

EffectShader Property _00E_EspionageFXS Auto
EffectShader Property _00E_FS_Tharael_DematerializeFXS Auto
EffectShader Property _00E_FS_NQR05_TharaelMaterializeFXS Auto