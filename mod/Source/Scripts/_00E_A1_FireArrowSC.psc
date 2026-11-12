Scriptname _00E_A1_FireArrowSC extends activemagiceffect  

Import _00E_TalentLibrary

;=====================================================================================
;              							EVENTS                  					 
;=====================================================================================

Event OnUpdate()
	if GetTargetActor() != Game.GetForm(0x14) as Actor
		return
	endif

	PlayerRef.UnequipItem(_00E_A1_FireArrowAmm, GetArrowCount())
	Self.Dispel()
	
EndEvent

Event OnEffectStart(Actor akTarget, Actor akCaster)
	STR_IsLocalTarget = (akTarget == Game.GetForm(0x14) as Actor)
	if !STR_IsLocalTarget
		return
	endif

	iIndex = GetPlayerTalentLevel(_00E_Class_Trickery_P05_Talent_Firearrow, _00E_Class_Trickery_P05_Talent_Firearrow2, _00E_Class_Trickery_P05_Talent_Firearrow3)
	AdjustArrowEnchantment()
	amOldAmmo = GetEquippedAmmo()
	akCaster.AddItem(_00E_A1_FireArrowAmm, GetArrowCount())
	akcaster.EquipItem(_00E_A1_FireArrowAmm)
	AddInventoryEventFilter(_00E_A1_FireArrowAmm)
	
EndEvent

Event OnEffectFinish(Actor akTarget, Actor akCaster)
	if akTarget != Game.GetForm(0x14) as Actor
		return
	endif

	If PlayerREF.GetItemCount(_00E_A1_FireArrowAmm) > 0
		PlayerREF.UnequipItem(_00E_A1_FireArrowAmm)
		PlayerREF.RemoveItem(_00E_A1_FireArrowAmm, GetArrowCount())
	EndIf
	
	PlayerREF.EquipItem(amOldAmmo)
	
EndEvent

Event OnPlayerBowShot(Weapon akWeapon, Ammo akAmmo, float afPower, bool abSunGazing)
	if GetTargetActor() != Game.GetForm(0x14) as Actor
		return
	endif

	If (akAmmo == _00E_A1_FireArrowAmm)
		_00E_A1_FireArrowIgniteSound.Play(PlayerREF)
	EndIf
	
	counter += 1
	
	If(counter == GetArrowCount()) && PlayerREF.GetItemCount(_00E_A1_FireArrowAmm) == 0
		RegisterForSingleUpdate(2)
	EndIf
  
EndEvent

Event OnItemRemoved(Form akBaseItem, int aiItemCount, ObjectReference akItemReference, ObjectReference akDestContainer)
	if GetTargetActor() != Game.GetForm(0x14) as Actor
		return
	endif
	If akItemReference && ! akDestContainer
		akItemReference.Delete()
	EndIf
EndEvent

;=====================================================================================
;              							FUNCTION                  					 
;=====================================================================================

Ammo Function GetEquippedAmmo()

	bool bFound
	int iFormlistIndex = _00E_A1_FirearrowAmmoFormlist.GetSize() - 1
	
	While iFormlistIndex >= 0 && !bFound
	
		Ammo amCurrentAmmoEntry = _00E_A1_FirearrowAmmoFormlist.GetAt(iFormlistIndex) as Ammo
		
		if PlayerREF.IsEquipped(amCurrentAmmoEntry)
			bFound = True
			Return amCurrentAmmoEntry
		Else
			iFormlistIndex -= 1
		EndIf

	EndWhile
	
EndFunction

Function AdjustArrowEnchantment()

	float iArrowFireDamage = _00E_A1_FireArrowSP.GetNthEffectMagnitude(iIndex - 1)
	
	_00E_A1_FireArrowEnchantment.SetNthEffectMagnitude(1, iArrowFireDamage)
	
	If PlayerREF.HasSpell(_00E_Affinity_AbWayfarer)
		_00E_A1_FireArrowWayfarerEnch.SetNthEffectMagnitude(0, (_00E_A1_FireArrowSP.GetNthEffectMagnitude(6)))
	EndIf
	
EndFunction

int Function GetArrowCount()

	int iArrowCount = _00E_A1_FireArrowSP.GetNthEffectMagnitude(iIndex + 2) as Int
	
	Return iArrowCount

EndFunction

;=====================================================================================
;              							PROPERTIES                  					 
;=====================================================================================

Ammo amOldAmmo

int iIndex
int Counter

Formlist Property _00E_A1_FirearrowAmmoFormlist Auto

Enchantment Property _00E_A1_FireArrowEnchantment Auto
Enchantment Property _00E_A1_FireArrowWayfarerEnch Auto

Ammo Property _00E_A1_FireArrowAmm Auto

Perk Property _00E_Class_Trickery_P05_Talent_Firearrow Auto
Perk Property _00E_Class_Trickery_P05_Talent_Firearrow2 Auto
Perk Property _00E_Class_Trickery_P05_Talent_Firearrow3 Auto
Spell Property _00E_Affinity_AbWayfarer Auto

Actor Property PlayerREF Auto

Sound property _00E_A1_FireArrowIgniteSound Auto

Spell Property _00E_A1_FireArrowSP Auto

; Skyrim Together: STR mirrors this effect onto the caster's puppet on other clients. This flag marks
; whether this copy runs on the local player; every event is skipped for the puppet's copy.
Bool STR_IsLocalTarget = False
