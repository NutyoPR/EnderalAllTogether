Scriptname _00E_MQ04_Firescript extends ObjectReference  
{Disables a fire and saves a stone upon being hit by Lishari's Spell}

;=====================================================================================
;              							EVENTS                    					 
;=====================================================================================

Event OnReset()

	; RegisterForSingleUpdate(1)

EndEvent

Event OnUpdate()

	If QuestScript.GetCurrentStageID() < 60 && QuestScript.GetCurrentStageID() >= 50
		If Self.IsEnabled()
			objFireRef.Reset()
			objLightRef.Reset()
		EndIf
		RegisterForSingleUpdate(1.5)
	Else
		UnregisterForUpdate()
	EndIf

EndEvent

Event OnHit(ObjectReference akAggressor, Form akSource, Projectile akProjectile, bool abPowerAttack, bool abSneakAttack, bool abBashAttack, bool abHitBlocked)

	if (akAggressor == PlayerREF) && (akSource == _00E_MQ04_FeuerloescherSpell) && (bDone == False)
		bDone = True
		QuestScript.SaveStone(Self, objFireRef, objLightRef)
		If EnderalAllTogether.IsLoaded()
			EnderalAllTogether.ShareValue("mq04stone:" + Self.GetFormID(), 1) ; Enderal AllTogether: saved for the party too
		EndIf
	EndIf

EndEvent

; Enderal AllTogether: a party member saved this stone. The same as saving it here, so the counters agree and the
; destruction timer skips it on every game. Only while the minigame is running.
Function SavedByParty()
	Int iStage = QuestScript.GetCurrentStageID()
	If !bDone && iStage >= 50 && iStage < 60
		bDone = True
		QuestScript.SaveStone(Self, objFireRef, objLightRef)
	EndIf
EndFunction

Event OnActivate(ObjectReference akActionRef)

	if akActionRef == Self
		QuestScript.DestroyStone(Self, objStoneRef)
		Self.PlaceAtMe(_00E_GiantShockExplosionHarmless, 1)
		Self.Disable()
	 EndIf
	 
EndEvent

;=====================================================================================
;              							FUNCTIONS                   					 
;=====================================================================================

Bool Function CheckSaved() 
	if bDone
		Return True
	Else
		Return False
	EndIf
EndFunction

;=====================================================================================
;              							PROPERTIES                    					 
;=====================================================================================

Bool bDone

ObjectReference Property objFireRef Auto
ObjectReference Property objLightRef Auto
ObjectReference Property objStoneRef Auto

MQ03_Functions Property QuestScript Auto

Actor Property PlayerREF Auto

ImageSpaceModifier Property _00E_MQ03FireISM Auto

Spell Property _00E_MQ04_FeuerloescherSpell Auto

Explosion Property _00E_GiantShockExplosionHarmless Auto