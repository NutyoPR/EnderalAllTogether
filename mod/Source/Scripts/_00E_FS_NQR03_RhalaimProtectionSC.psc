Scriptname _00E_FS_NQR03_RhalaimProtectionSC extends ObjectReference  

;=====================================================================================
;                                       EVENTS                        
;=====================================================================================

Event OnActivate(ObjectReference akActionRef)

	if akActionRef == PlayerREF && !bScion && !bInteractable
		FS_NQR03.ModDistrust(1)
	endif

EndEvent

Event OnHit(ObjectReference akAggressor, Form akSource, Projectile akProjectile, bool abPowerAttack, bool abSneakAttack, bool abBashAttack, bool abHitBlocked)

	if akAggressor == PlayerREF
		
		Utility.Wait(2.0)
		FatherIntervene()
	
	endif
	
EndEvent

;=====================================================================================
;                                       FUNCTIONS                        
;=====================================================================================

Function FatherIntervene()

	FS_NQR03_FatherPlatformREF.Enable()
	Game.DisablePlayerControls()
	MAGIllusionCharm.Play(PlayerREF)
	PlayerREF.MoveTo(FS_NQR03_SC99_FatherTeleportREF)
	If EnderalAllTogether.IsLoaded()
		EnderalAllTogether.ShareTravel(FS_NQR03_SC99_FatherTeleportREF) ; Enderal AllTogether: the party comes along
	EndIf
	PlayerREF.PlaceAtMe(FXDragonPriestSmallExplosion)
	FS_NQR03_SC99_FatherInterventionSC.ForceStart()
	Utility.Wait(5.0)
	FS_NQR03_FatherPlatformREF.Disable()
	Game.DisablePlayerControls()
	
EndFunction

;=====================================================================================
;                                       PROPERTIES                        
;=====================================================================================

_00E_FS_NQR03_Functions Property FS_NQR03 Auto

bool Property bScion Auto
bool Property bInteractable Auto

Scene Property FS_NQR03_SC99_FatherInterventionSC Auto

Sound Property MAGIllusionCharm Auto

Explosion Property FXDragonPriestSmallExplosion Auto

ObjectReference Property FS_NQR03_SC99_FatherTeleportREF Auto
ObjectReference Property FS_NQR03_FatherPlatformREF Auto

Actor Property PlayerREF Auto