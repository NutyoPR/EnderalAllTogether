Scriptname _00E_FS_MesmerizeSC extends ActiveMagicEffect  

;=====================================================================================
;              							 EVENTS                   					 
;=====================================================================================

Event OnEffectStart(Actor akTarget, Actor akCaster)
	; Enderal AllTogether: Skyrim Together copies this to the other games (effect on the player's copy, or a replayed
	; activation); only the player it's really for may run it, or it would act on whoever is local there.
	If akCaster != Game.GetForm(0x14) as Actor
		Return
	EndIf

	if PlayerREF.IsDetectedBy(akTarget)
	
		_00E_FS_MesmerizeDetected.Show()
		Faction crimeFaction = akTarget.GetCrimeFaction()
		
		if crimeFaction != none
			crimeFaction.ModCrimeGold(20, False)
		endIf
		
		akTarget.SendAssaultAlarm()
		
	Else
	
		if SKSE.GetVersion()
			fMagnitude = GetMagnitude()
		endif
		
		float fBuff = ((PlayerREF.GetActorValue("Illusion") / 6 as Int) + fMagnitude) / 100
		PlayerREF.SetActorValue(sActorValue, fBuff)
		
		PlayerREF.AddPerk(_00E_FS_MesmerizePerk)
		
	EndIf

EndEvent

Event OnEffectFinish(Actor akTarget, Actor akCaster)
	; Enderal AllTogether: Skyrim Together copies this to the other games (effect on the player's copy, or a replayed
	; activation); only the player it's really for may run it, or it would act on whoever is local there.
	If akCaster != Game.GetForm(0x14) as Actor
		Return
	EndIf

	PlayerREF.RemovePerk(_00E_FS_MesmerizePerk)
	PlayerREF.SetActorValue(sActorValue, 0.0)

EndEvent

;=====================================================================================
;              							 PROPERTIES                  					 
;=====================================================================================

Float Property fMagnitude = 7.0 Auto  
String Property sActorValue = "Variable07" Auto

Actor Property PlayerREF Auto

Perk Property _00E_FS_MesmerizePerk Auto

Message Property _00E_FS_MesmerizeDetected Auto
