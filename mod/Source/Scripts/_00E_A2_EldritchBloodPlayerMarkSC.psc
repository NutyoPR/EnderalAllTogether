Scriptname _00E_A2_EldritchBloodPlayerMarkSC extends ReferenceAlias

Import Utility

int function _GetScriptVersion() Global
	return 1
endFunction

;=====================================================================================
;              							EVENTS                  					 
;=====================================================================================

Auto State Marking

	Event OnControlUp(string control, float HoldTime)
		
		Actor rTarget = Game.GetCurrentCrosshairRef() as Actor
		
		if ! rTarget || rTarget == Game.GetForm(0x14)
			return
		endif
		If EnderalAllTogether.IsLoaded() && EnderalAllTogether.IsOtherPlayer(rTarget) ; Enderal AllTogether: never your partner
			return
		EndIf
		
		If _00E_A2_EldritchBloodGlobal.GetValueInt() == 1
			EldritchBloodEffectScript.SelectEnemy(rTarget)
		EndIf
		
	EndEvent

	Event OnCrosshairRefChange(ObjectReference ref)

		if lastTarget != None
			lastTarget.blockActivation(false)
		EndIf
		lastTarget = ref
		
		if ref
			ref.blockActivation(true)
		endif
		
	EndEvent

	Event OnAnimationEvent(ObjectReference akSource, string asEventName)

		if(akSource == akSelfRef && asEventName == "weaponSwing") 
			if iAttackCounter == 0
				iAttackCounter = 1
			Else
				; Debug.Notification(sMarkingModeInterrupted)
				_00E_MarkingTalents_sMarkingModeInterrupted.Show()
				EldritchBloodEffectScript.abort()
				UnregisterForAnimationEvent(akSelfRef, "weaponSwing")
			EndIf
		EndIf

	EndEvent

	Event OnObjectEquipped(Form equippedObject, ObjectReference reference)

		if ! equippedObject as Shout
			; Debug.Notification(sMarkingModeInterrupted)
			_00E_MarkingTalents_sMarkingModeInterrupted.Show()
			EldritchBloodEffectScript.abort()
		EndIf

	EndEvent

	Event OnSpellCast(Form akSpell)

		if akSpell != _00E_A2_EldritchBloodSP
			; Debug.Notification(sMarkingModeInterrupted)
			_00E_MarkingTalents_sMarkingModeInterrupted.Show()
			EldritchBloodEffectScript.abort()
		EndIf

	EndEvent

	Event OnPlayerBowShot(Weapon akWeapon, Ammo akAmmo, float afPower, bool abSunGazing)

		; Debug.Notification(sMarkingModeInterrupted)
		_00E_MarkingTalents_sMarkingModeInterrupted.Show()
		EldritchBloodEffectScript.abort()

	EndEvent

EndState


;=====================================================================================
;              							FUNCTIONS                  					 
;=====================================================================================

Function EnterMarkingMode(Float iReach, _00E_A2_EldritchBloodPlayerSC _00E_A2_EldritchBloodMEScript)

	akSelfRef = Self.GetActorReference()
	RegisterForAnimationEvent(akSelfRef, "weaponSwing")
	fActivatePickLengthBefore = GetINIFloat("fActivatePickLength:Interface")
	SetINIFloat("fActivatePickLength:Interface", iReach)
	EldritchBloodEffectScript = _00E_A2_EldritchBloodMEScript
	RegisterForCrosshairRef()
	RegisterForControl("Activate")

EndFunction

Function ExitMarkingMode()

	iAttackCounter = 0
	UnregisterForAllControls()
	UnregisterForCrosshairRef()
	UnregisterForAnimationEvent(akSelfRef, "weaponSwing")

	; Restore activation reach
	if fActivatePickLengthBefore <= 0
		fActivatePickLengthBefore = 150.0
	endif
	SetINIFloat("fActivatePickLength:Interface", fActivatePickLengthBefore)
	
	if lastTarget != None
		lastTarget.blockActivation(false)
	EndIf
	lastTarget = None

EndFunction

;=====================================================================================
;              							PROPERTIES                  					 
;=====================================================================================

ObjectReference lastTarget ; the last target before the crosshair; used to block and unblock activation

Actor akSelfRef

int iAttackCounter

_00E_A2_EldritchBloodPlayerSC Property EldritchBloodEffectScript Auto Hidden

float fActivatePickLengthBefore 

;String Property sMarkingModeInterrupted = "Marking interrupted by attacking." Auto

GlobalVariable Property _00E_A2_EldritchBloodGlobal Auto

Spell Property _00E_A2_EldritchBloodSP Auto
Shout Property _00E_A2_EldritchBlood Auto

Message Property _00E_MarkingTalents_sMarkingModeInterrupted Auto
