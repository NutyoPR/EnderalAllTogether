Scriptname _00E_A2_EyeOfTheStormSC extends activemagiceffect  

Import _00E_TalentLibrary 

int function _GetScriptVersion() Global
    return 1
endFunction

;=====================================================================================
;              							EVENTS                    					 
;=====================================================================================

Event OnUpdate()

	Self.Dispel()

EndEvent

Event OnEffectStart(Actor akTarget, Actor akCaster)

	; Enderal AllTogether: only the caster's own game runs the talent (on the others this effect can land on their copy
	; of the caster, and would play the sound and the explosion on them).
	If akCaster != PlayerREF
		Return
	EndIf

	if !(PlayerREF.HasSpell(_00E_A2_EyeOfTheStormAb))
	
		int iDurationIndex = GetPlayerTalentLevel(_00E_Class_Trickery_P09b_Talent_EyeOfTheStorm,_00E_Class_Trickery_P09b_Talent_EyeOfTheStorm2, _00E_Class_Trickery_P09b_Talent_EyeOfTheStorm3) - 1
		_00E_A2_EyeOfTheStormFailsaveEnch.SetNthEffectDuration(0, _00E_A2_EyeOfTheStormSP.GetNthEffectDuration(iDurationIndex))
		fDurationFailsave = _00E_A2_EyeOfTheStormSP.GetNthEffectDuration(iDurationIndex)
		iSound = MAGShoutSlowTimeActive02LP.Play(PlayerREF)
		PlayerREF.PlaceAtMe(_00E_A2_EyeOfTheStormFailsaveExp, 1)
		akCaster.AddSpell(_00E_A2_EyeOfTheStormAb, False)
		RegisterForSingleUpdate(fDurationFailsave)
		If EnderalAllTogether.IsLoaded()
			; Enderal AllTogether: time slows on every player's game at once, never on one only.
			EnderalAllTogether.ShareSlowTime(True, fDurationFailsave)
		EndIf

		If PlayerREF.HasSpell(_00E_A2_DanceOfBladesSP)
			If _00E_Synergy_EyeOfTheStormBladedance.GetValueInt() == 0
				_00E_Synergy_EyeOfTheStormBladedance.SetValueInt(1)
				_00E_PlayerFunctions.GetSkillControl().ShowSynergyMessage()
			EndIf
		EndIf
		
	endif

EndEvent

Event OnEffectFinish(Actor akTarget, Actor akCaster)

	If akCaster != PlayerREF ; Enderal AllTogether, see OnEffectStart
		Return
	EndIf

	if (PlayerREF.HasSpell(_00E_A2_EyeOfTheStormAb))
		Sound.StopInstance(iSound)
		akCaster.RemoveSpell(_00E_A2_EyeOfTheStormAb)
		If EnderalAllTogether.IsLoaded()
			EnderalAllTogether.ShareSlowTime(False, 0.0) ; Enderal AllTogether: and ends for everyone
		EndIf
	endif

EndEvent

Event OnPlayerBowShot(Weapon akWeapon, Ammo akAmmo, float afPower, bool abSunGazing)

	if PlayerREF.HasSpell(_00E_Affinity_AbArcaneArcher)
		Utility.Wait(0.03)
		ObjectReference akTarget
		if SKSE.GetVersion()
			; Slightly improves precision
			akTarget = Game.GetCurrentCrosshairRef()
		endif
		_00E_AltIshmartepElectroShotSound.Play(PlayerREF)
		_00E_Affinity_AbSpectralArrowSP.Cast(PlayerREF, akTarget)
	EndIf
  
EndEvent

;=====================================================================================
;              							PROPERTIES                    					 
;=====================================================================================

int iSound

float Property fDurationFailsave Auto Hidden

GlobalVariable Property KillMove Auto
GlobalVariable Property _00E_Synergy_EyeOfTheStormBladedance Auto

Spell Property _00E_A2_EyeOfTheStormAb Auto
Spell Property _00E_A2_EyeOfTheStormSP Auto
Spell Property _00E_Affinity_AbSpectralArrowSP Auto
Spell Property _00E_Affinity_AbArcaneArcher Auto
Spell Property _00E_A2_DanceOfBladesSP Auto

Perk Property _00E_Class_Trickery_P09b_Talent_EyeOfTheStorm Auto
Perk Property _00E_Class_Trickery_P09b_Talent_EyeOfTheStorm2 Auto
Perk Property _00E_Class_Trickery_P09b_Talent_EyeOfTheStorm3 Auto

Enchantment Property _00E_A2_EyeOfTheStormFailsaveEnch Auto

Sound Property _00E_AltIshmartepElectroShotSound Auto
Sound Property MAGShoutSlowTimeActive02LP Auto

Actor Property PlayerREF Auto

Explosion Property _00E_A2_EyeOfTheStormFailsaveExp Auto