Scriptname _EAT_ChanneledArcaneFever extends ActiveMagicEffect
{Enderal AllTogether: arcane fever for the channeled Second Breath.
Each beam hit makes a new effect that is gone again before this script runs, so it can't count anything itself
(GetMagnitude already fails). It reports the hit to _00E_VisionControl, which adds the fever for the time the beam
keeps hitting and shows one message when you let go. The fever per second comes from the equipped Second Breath.}

Actor Property PlayerREF Auto
Perk Property _00E_Class_Thaumaturge_P07_MentalExpert Auto
Message Property _00E_Player_sArcaneFeverIncreased Auto
Sound Property _00E_FS_IncreaseArcaneFeverM Auto
MagicEffect Property _EAT_ChanneledArcaneFeverME Auto

Event OnEffectStart(Actor akTarget, Actor akCaster)
	; Only the caster's own game counts the fever.
	If akCaster != PlayerREF
		return
	EndIf
	float fPerSecond = FeverPerSecond(PlayerREF.GetEquippedSpell(1))
	If fPerSecond <= 0.0
		fPerSecond = FeverPerSecond(PlayerREF.GetEquippedSpell(0))
	EndIf
	If fPerSecond <= 0.0
		return
	EndIf
	If PlayerREF.HasPerk(_00E_Class_Thaumaturge_P07_MentalExpert)
		fPerSecond = fPerSecond * 0.67
	EndIf
	_00E_PlayerFunctions.GetVisionControl().EATFeverHit(fPerSecond)
EndEvent

float Function FeverPerSecond(Spell akSpell)
	If !akSpell
		return 0.0
	EndIf
	int i = akSpell.GetNumEffects()
	While i > 0
		i -= 1
		If akSpell.GetNthEffectMagicEffect(i) == _EAT_ChanneledArcaneFeverME
			return akSpell.GetNthEffectMagnitude(i)
		EndIf
	EndWhile
	return 0.0
EndFunction
