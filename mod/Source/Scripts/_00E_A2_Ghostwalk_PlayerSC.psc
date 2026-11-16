Scriptname _00E_A2_Ghostwalk_PlayerSC Extends ReferenceAlias

Import Utility


;=====================================================================================
;              							EVENTS                  					 
;=====================================================================================

Auto State Marking

Event OnCrosshairRefChange(ObjectReference ref)

	if lastTarget != None
		lastTarget.blockActivation(false)
	EndIf
	lastTarget = ref
	ref.blockActivation(true)

	If _00E_A2_GhostwalkGlobal.GetValueInt() == 1
		; Enderal AllTogether: never your partner
		If Ref.GetSelfAsActor() && Ref != Game.GetPlayer() && !(EnderalAllTogether.IsLoaded() && EnderalAllTogether.IsOtherPlayer(Ref as Actor))
			GhostwalkEffectScript.SelectEnemy(Ref as Actor)
		EndIf
	Else
		ref.blockActivation(false)
		UnregisterForCrosshairRef()
	EndIf
	
EndEvent

Event OnAnimationEvent(ObjectReference akSource, string asEventName)

	if(akSource == akSelfRef && asEventName == "weaponSwing") 
		if iAttackCounter == 0
			iAttackCounter = 1
		Else
			; Debug.Notification(sMarkingModeInterrupted)
			_00E_MarkingTalents_sMarkingModeInterrupted.Show()
			Self.GetActorReference().DispelSpell(_00E_A2_GhostwalkSP)
			UnregisterForAnimationEvent(akSelfRef, "weaponSwing")
		EndIf
	EndIf

EndEvent

Event OnObjectEquipped(Form equippedObject, ObjectReference reference)
	
	Shout equippedShout = equippedObject as Shout
	
	if(!equippedShout)
		; Debug.Notification(sMarkingModeInterrupted)
		_00E_MarkingTalents_sMarkingModeInterrupted.Show()
		;Self.GetActorReference().DispelSpell(_00E_A2_GhostwalkSP)
		GhostwalkEffectScript.abort()
	EndIf

EndEvent

Event OnSpellCast(Form akSpell)

	Shout equippedShout = akSpell as Shout
	
	if akSpell != _00E_A2_Ghostwalk
		; Debug.Notification(sMarkingModeInterrupted)
		_00E_MarkingTalents_sMarkingModeInterrupted.Show()
		;Self.GetActorReference().DispelSpell(_00E_A2_GhostwalkSP)
		GhostwalkEffectScript.abort()
	EndIf

EndEvent

Event OnPlayerBowShot(Weapon akWeapon, Ammo akAmmo, float afPower, bool abSunGazing)

	; Debug.Notification(sMarkingModeInterrupted)
	_00E_MarkingTalents_sMarkingModeInterrupted.Show()
	;Self.GetActorReference().DispelSpell(_00E_A2_GhostwalkSP)
	GhostwalkEffectScript.abort()
	
EndEvent

EndState

;=====================================================================================
;              							FUNCTIONS                  					 
;=====================================================================================

Function EnterMarkingMode(Float iReach, _00E_A2_GhostwalkSC _00E_A2_GhostwalkMEScript)

	akSelfRef = Self.GetActorReference()
	RegisterForAnimationEvent(akSelfRef, "weaponSwing")
	fActivatePickLengthBefore = GetINIFloat("fActivatePickLength:Interface")
	SetINIFloat("fActivatePickLength:Interface", iReach)
	GhostwalkEffectScript = _00E_A2_GhostwalkMEScript
	RegisterForCrosshairRef()

EndFunction

Function ExitMarkingMode()

	if lastTarget != None
		lastTarget.blockActivation(false)
	EndIf
	lastTarget = None
	
	UnregisterForAnimationEvent(akSelfRef, "weaponSwing")
	UnregisterForCrosshairRef()
	SetINIFloat("fActivatePickLength:Interface", 150)

EndFunction

;=====================================================================================
;              							PROPERTIES                  					 
;=====================================================================================

ObjectReference lastTarget ; the last target before the crosshair; used to block and unblock activation

Actor akSelfRef

int iAttackCounter
float fActivatePickLengthBefore 

;String Property sMarkingModeInterrupted = "Marking interrupted by attacking." Auto

Message Property _00E_MarkingTalents_sMarkingModeInterrupted Auto

_00E_A2_GhostwalkSC Property GhostwalkEffectScript Auto Hidden

Shout Property _00E_A2_Ghostwalk Auto

Spell Property _00E_A2_GhostwalkSP Auto

GlobalVariable Property _00E_A2_GhostwalkGlobal Auto

