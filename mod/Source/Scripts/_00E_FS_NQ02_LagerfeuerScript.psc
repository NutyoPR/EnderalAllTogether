Scriptname _00E_FS_NQ02_LagerfeuerScript extends ObjectReference  

Import Utility

Event OnActivate(ObjectReference akActionRef)
	if akActionRef == PlayerREF && FS_NQ02.GetCurrentStageID() == 70
		GoToState("DoNothing")
		_00E_FadeToBlackControl FadeToBlackControl = _00E_PlayerFunctions.GetFadeToBlackControl()
		FadeToBlackControl.FadeToBlack()
		FS_NQ02.SetCurrentStageID(80)
		wait(0.1)
		_00E_FS_NQ02_EsmeREF.MoveTo(_00E_FS_NQ02_SC02_EsmeMarker2)
		PlayerREF.MoveTo(_00E_FS_NQ02_SC02_PlayerMarker)
		If EnderalAllTogether.IsLoaded()
			EnderalAllTogether.ShareTravel(_00E_FS_NQ02_SC02_PlayerMarker) ; Enderal AllTogether: the party comes along
		EndIf
		_00E_FS_NQ02_CaravanCampfireOff.Disable()
		_00E_TimeControl.SkipTimeToHour(0)
		_00E_SilenceLongTransitionHighPriority.Add()
		self.Disable()
		FadeToBlackControl.FadeToBlackBack()

	Endif
EndEvent

State DoNothing
	Event OnActivate(ObjectReference akActionRef)
		; Do nothing
	EndEvent
EndState

Actor Property PlayerREF Auto
Actor Property _00E_FS_NQ02_EsmeREF Auto
Quest Property FS_NQ02 Auto
ObjectReference Property _00E_FS_NQ02_SC02_PlayerMarker Auto
ObjectReference Property _00E_FS_NQ02_SC02_EsmeMarker2 Auto
ObjectReference Property _00E_FS_NQ02_CaravanCampfireOff Auto
MusicType Property _00E_SilenceLongTransitionHighPriority Auto
