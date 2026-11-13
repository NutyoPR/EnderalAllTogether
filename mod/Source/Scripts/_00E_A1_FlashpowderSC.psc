Scriptname _00E_A1_FlashpowderSC extends activemagiceffect  

Import _00E_TalentLibrary 

;=====================================================================================
;              							EVENTS                  					 
;=====================================================================================

Event OnEffectStart (Actor akTarget, Actor akCaster)
	; Enderal AllTogether: Skyrim Together copies this to the other games (effect on the player's copy, or a replayed
	; activation); only the player it's really for may run it, or it would act on whoever is local there.
	If akTarget != Game.GetForm(0x14) as Actor
		Return
	EndIf

	_00E_A2_FlashpowderGlobal.SetValueInt(1)
	AdjustSpell()
	_00E_A1_FlashpowderExplSP.Cast(PlayerREF, PlayerREF)
	_00E_A1_FlashpowderWidgetSP.Cast(PlayerREF, PlayerREF)
	Game.ShakeCamera(afStrength = 0.5)
	_00E_A1_Flashpowder_Flash.Apply()
	A1_FlashpowderFXBox.MoveTo(playerREF)
	
	If !(PlayerREF.HasPerk(_00E_A2_Ghostwalk_Perk))
		PlayerREF.AddPerk(_00E_A2_Ghostwalk_Perk)
	EndIf

EndEvent

Event OnEffectFinish(Actor akTarget, Actor akCaster)
	; Enderal AllTogether: Skyrim Together copies this to the other games (effect on the player's copy, or a replayed
	; activation); only the player it's really for may run it, or it would act on whoever is local there.
	If akTarget != Game.GetForm(0x14) as Actor
		Return
	EndIf

	PlayerREF.RemovePerk(_00E_A2_Ghostwalk_Perk)
	A1_FlashpowderFXBox.MoveTo(A1_FlashpowderHomeMarker)

EndEvent

;=====================================================================================
;              							FUNCTIONS                  					 
;=====================================================================================

Function AdjustSpell()

	int iIndex = GetPlayerTalentLevel(_00E_Class_Manipulation_P05_Talent_Rift, _00E_Class_Manipulation_P05_Talent_Rift2, _00E_Class_Manipulation_P05_Talent_Rift3) - 1
	Float iDuration = _00E_A1_FlashpowderSP.GetNthEffectDuration(iIndex)
	Float iArea = _00E_A1_FlashpowderSP.GetNthEffectArea(iIndex)
	_00E_A1_FlashpowderExplSP.SetNthEffectDuration(0, iDuration as Int)
	_00E_A1_FlashpowderExplSP.SetNthEffectArea(0, iArea as Int)
	_00E_A1_FlashpowderWidgetSP.SetNthEffectDuration(0, iDuration as Int)

EndFunction

;=====================================================================================
;              							PROPERTIES                  					 
;=====================================================================================

GlobalVariable Property _00E_A2_FlashpowderGlobal Auto

ObjectReference HomeMarker 

Static Property XMarker Auto

ObjectReference Property A1_FlashpowderFXBox Auto
ObjectReference Property A1_FlashpowderHomeMarker Auto

Message Property _00E_A1_Flashpowder_sCantBeCastWhenActive Auto

MagicEffect Property _00E_A1_FlashpowderME Auto

Actor property PlayerREF Auto

ImagespaceModifier Property _00E_A1_Flashpowder_Flash Auto

Spell Property _00E_A1_FlashpowderExplSP Auto
Spell Property _00E_A1_FlashpowderSP Auto
Spell Property _00E_A1_FlashpowderWidgetSP Auto

Explosion Property _00E_A1_FlashpowderExplosion Auto

Perk Property _00E_Class_Espionage_P05_Talent_Flashpowder Auto
Perk Property _00E_Class_Espionage_P05_Talent_Flashpowder2 Auto
Perk Property _00E_Class_Espionage_P05_Talent_Flashpowder3 Auto

Perk Property _00E_Class_Manipulation_P05_Talent_Rift Auto
Perk Property _00E_Class_Manipulation_P05_Talent_Rift2 Auto
Perk Property _00E_Class_Manipulation_P05_Talent_Rift3 Auto

Perk Property _00E_A2_Ghostwalk_Perk Auto



