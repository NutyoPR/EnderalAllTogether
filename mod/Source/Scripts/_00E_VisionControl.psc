Scriptname _00E_VisionControl extends Quest Hidden 

import Utility

int function _GetScriptVersion() Global
    return 1
endFunction

;/ Unused
function EndVision(bool ScenePlaying, Scene RunningScene = None)

	If PlayerREF.HasSpell(_00E_Vision_TimeSpell)
		PlayerREF.RemoveSpell(_00E_Vision_TimeSpell)
	ElseIf PlayerREF.HasSpell(_00E_Vision_NoTimeSpell)
		PlayerREF.RemoveSpell(_00E_Vision_NoTimeSpell)
	ElseIf PlayerREF.HasSpell(_00E_Vision_NoTimeSubtleSpell)
		PlayerREF.RemoveSpell(_00E_Vision_NoTimeSubtleSpell)
	EndIf
	If ScenePlaying == True && RunningScene.IsPlaying()
		RunningScene.Stop()
	EndIf
	PlayerREF.MoveTo(PlayerVisionStartMarker)

endFunction
/;

Function VisionEffectTimestop(bool bSilent = False, bool bCustomImod = False, bool bCustomMusic = False)

	If bCustomImod == False
		_00E_VisionStartTimestopIMOD.Apply()
		_00E_VisionImod.ApplyCrossFade(0.25)
	EndIf

	PlayerREF.AddSpell(_00E_Vision_TimeSpell, False)
	
	if !bCustomMusic
		_00E_SilenceAbruptHighPriority.Add()
	EndIf
	
	MagRacialBattlecryFire.Play(PlayerREF)
	fPlayerSpeedBeforeVision = PlayerREF.GetBaseActorValue("SpeedMult")
	PlayerREF.SetActorValue("SpeedMult", 35)
	UpdateSpeed(PlayerREF)
	
	VisionSound = 0
	If !bSilent
		VisionSound = _00E_VisionLPM.Play(PlayerREF)
	EndIf
	
	_00E_VisionShaderParticles.Apply(0.5)
	AudioCategoryFST.Mute()
	
	PlayerREF.SetGhost(True)
	
	PlayerVisionStartMarker = PlayerREF.PlaceAtMe(XMarker as form, 1, false, false)
	PlayerVisionFailsaveMarker.MoveTo(PlayerREF)
	Game.DisablePlayerControls(false, true, true, false, true, false, true, false)
	Game.ForceFirstPerson()
	Game.ShowFirstPersonGeometry(False)
	Wait(0.100000)
		
EndFunction

Function VisionEffectTimestopStop(bool bMovementHasBeenLocked = False)

	Game.DisablePlayerControls()
	AudioCategoryFST.UnMute()
	
	If !bMovementHasBeenLocked
		If PlayerVisionFailsaveMarker.GetDistance(PlayerREF) <= 1000
			PlayerREF.MoveTo(PlayerVisionStartMarker)
		Elseif PlayerVisionFailsaveMarker.GetDistance(PlayerREF) >= 1000
			PlayerREF.MoveTo(PlayerVisionFailsaveMarker)
		EndIf
	EndIf
	
	if VisionSound
		Sound.StopInstance(VisionSound)
		VisionSound = 0
	endif
	MAGConjurePortalClose.Play(PlayerREF)
	PlayerREF.RemoveSpell(_00E_Vision_TimeSpell)
	_00E_VisionShaderParticles.Remove(0.5)
	_00E_VisionEndImod.ApplyCrossFade(1)
	Wait(0.5)
	PlayerREF.SetActorValue("speedMult", fPlayerSpeedBeforeVision)
	
	If PlayerREF.GetActorValue("speedMult") < 50
		PlayerREF.SetActorValue("speedMult", 100)
	EndIf

	UpdateSpeed(PlayerREF)
	Game.EnablePlayerControls()
	Game.SetPlayerAIDriven(false)
	Game.ShowFirstPersonGeometry(True)
	_00E_SilenceAbruptHighPriority.Remove()
	PlayerREF.SetGhost(False)
	If EnderalAllTogether.IsLoaded()
		EnderalAllTogether.ShareRelease() ; Enderal AllTogether: the partner's game lets go too
	EndIf
EndFunction

Function VisionEffectNoTimestop(Formlist RefsInvolved, Formlist ActorsToFreeze = None, bool bCustomMusic = False)

	Game.ShowFirstPersonGeometry(False)
	PlayerREF.SetAlpha(0.1)
	PlayerREF.AddPerk(_00E_VisionPerk)
	UpdateSpeed(PlayerREF)
	MagRacialBattlecryFire.Play(PlayerREF)
	
	if !bCustomMusic
		_00E_SilenceAbruptHighPriority.Add()
	EndIf
	
	AudioCategoryFST.Mute()
	PlayerVisionStartMarker = PlayerREF.PlaceAtMe(XMarker as form, 1, false, false)
	PlayerVisionFailsaveMarker.MoveTo(PlayerREF)
	PlayerREF.SetGhost(True)
	VisionSound = _00E_VisionLPM.Play(PlayerREF)
	_00E_VisionStartImod.Apply()
	
	If PlayerREF.IsInInterior()
		_00E_VisionShaderParticles.Apply(0.5)
	EndIf
	
	if RefsInvolved != None
		Int iIndex = 0
		int nItems = RefsInvolved.GetSize()
		While iIndex < nItems
			Actor VisionREF = RefsInvolved.GetAt(iIndex) as Actor
			if VisionREF
				if VisionREF.IsDisabled()
					VisionREF.EnableNoWait()
				EndIf
				VisionRef.SetAlpha(0.5)
				MS04MemoryFXBody01VFX.Play(VisionREF)
			endif
			iIndex += 1
		EndWhile
	endif

	if ActorsToFreeze != None
		int iIndex02 = ActorsToFreeze.GetSize()

		while iIndex02 > 0
			iIndex02 -= 1
			Actor FreezeREF = ActorsToFreeze.GetAt(iIndex02) as Actor
			FreezeREF.EnableAI(False)
		EndWhile
	endif
	
	_00E_MQ16_VisionIMOD.Remove()
	_00E_VisionImod.ApplyCrossFade(1)
	
EndFunction

Function VisionEffectNoTimestopStop(Formlist RefsInvolved, Formlist ActorsToFreeze = None, bool bHasBeenRestrained = False)

	PlayerREF.SetAlpha(1.0)
	Game.ShowFirstPersonGeometry(True)
	
	If !bHasBeenRestrained
		If PlayerVisionFailsaveMarker.GetDistance(PlayerREF) <= 1000
			PlayerREF.MoveTo(PlayerVisionStartMarker)
		Elseif PlayerVisionFailsaveMarker.GetDistance(PlayerREF) >= 1000
			PlayerREF.MoveTo(PlayerVisionFailsaveMarker)
		EndIf
	EndIf
	
	_00E_VisionEndImod.ApplyCrossFade(1)
	If PlayerREF.IsInInterior()
		_00E_VisionShaderParticles.Remove(0.5)
	EndIf
	
	if RefsInvolved != None
		int nItems = RefsInvolved.GetSize()
		Int iIndex = 0
		While iIndex < nItems
			Actor VisionREF = RefsInvolved.GetAt(iIndex) as Actor
			if VisionREF
				MS04MemoryFXBody01VFX.Stop(VisionREF)
				VisionRef.SetAlpha(1)
			endif
			iIndex += 1
		EndWhile
	endif

	if ActorsToFreeze != None
		int iIndex02 = ActorsToFreeze.GetSize()

	    while iIndex02 > 0
	        iIndex02 -= 1
	        Actor FreezeREF = ActorsToFreeze.GetAt(iIndex02) as Actor
	        FreezeREF.EnableAI(True)
	    EndWhile
	endif
	
	AudioCategoryFST.UnMute()
	PlayerREF.SetGhost(False)
	Sound.StopInstance(VisionSound)
	MAGConjurePortalClose.Play(PlayerREF)
	_00E_SilenceAbruptHighPriority.Remove()
	PlayerREF.RemovePerk(_00E_VisionPerk)
	
	If PlayerREF.GetActorValue("speedMult") < 50
		PlayerREF.SetActorValue("speedMult", 100)
	EndIf
	
	UpdateSpeed(PlayerREF)
	_00E_MQ16_VisionIMOD.Remove()
	_00E_VisionImod.Remove()
	If EnderalAllTogether.IsLoaded()
		EnderalAllTogether.ShareRelease() ; Enderal AllTogether: the partner's game lets go too
	EndIf
EndFunction

Function UpdateSpeed(Actor SpeedUpdateActor)

	If SpeedUpdateActor.HasSpell(_00E_Vision_UpdateAb)
		SpeedUpdateActor.RemoveSpell(_00E_Vision_UpdateAb)
	EndIf
	
	SpeedUpdateActor.AddSpell(_00E_Vision_UpdateAb, False)
	Wait(0.1)
	SpeedUpdateActor.RemoveSpell(_00E_Vision_UpdateAb)

EndFunction

float fPlayerSpeedBeforeVision

ObjectReference Property PlayerVisionStartMarker Auto Hidden
ObjectReference Property PlayerVisionFailsaveMarker Auto

int VisionSound

SPELL Property _00E_Vision_TimeSpell  Auto  

SPELL Property _00E_Vision_NoTimeSpell  Auto  

SPELL Property _00E_Vision_NoTimeSubtleSpell  Auto  

ImageSpaceModifier Property _00E_VisionStartTimestopIMOD  Auto  

ImageSpaceModifier Property _00E_VisionIMOD  Auto  

MusicType Property _00E_SilenceAbruptHighPriority  Auto  

Sound Property MagRacialBattlecryFire  Auto  

actor Property PlayerRef  Auto  

Sound Property _00E_VisionLPM  Auto  

ImageSpaceModifier Property _00E_VisionStartImod  Auto  

ShaderParticleGeometry Property _00E_VisionShaderParticles  Auto  

SoundCategory Property AudioCategoryFST  Auto  

VisualEffect Property MS04MemoryFXBody01VFX  Auto  

ImageSpaceModifier Property _00E_MQ16_VisionIMOD  Auto  

Sound Property MAGConjurePortalClose  Auto  

SPELL Property _00E_Vision_UpdateAb  Auto  

Perk Property _00E_VisionPerk  Auto  

STATIC Property XMarker  Auto  

ImageSpaceModifier Property _00E_VisionEndImod  Auto  
  
