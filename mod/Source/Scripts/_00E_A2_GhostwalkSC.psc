Scriptname _00E_A2_GhostwalkSC extends activemagiceffect  

; UNUSED

Import _00E_TalentLibrary
Import Utility

;=====================================================================================
;              							EVENTS & STATES                 					 
;=====================================================================================

Event OnEffectStart(Actor akTarget, Actor akCaster)
	STR_IsLocalTarget = (akTarget == Game.GetForm(0x14) as Actor)
	if !STR_IsLocalTarget
		return
	endif

	PlayerREF.AddPerk(QuietCasting)
	hasAborted = false
	PlayerREF.AddSpell(PerkShadowWarriorInvisibility, False)
	
	iShoutIndex = GetPlayerTalentLevel(_00E_Class_Manipulation_P09b_Talent_WellOfLife, _00E_Class_Manipulation_P09b_Talent_WellOfLife2, _00E_Class_Manipulation_P09b_Talent_WellOfLife3) 
	
	If _00E_A2_GhostwalkGlobal.GetValueInt() == 0
		bTargetMarked = False
		GoToState("MarkTargets")
	Elseif _00E_A2_GhostwalkGlobal.GetValueInt() == 1
		If bTargetMarked
			_00E_A2_GhostwalkGlobal.SetValueInt(2)
			GoToState("Teleporting")
		Elseif !bTargetMarked
			_00E_A2_GhostwalkGlobal.SetValueInt(0)
			NotMarkedClearUp()
		EndIf	
	EndIf
	
EndEvent

Event OnEffectFinish(Actor akTarget, Actor akCaster)
	if akTarget != Game.GetForm(0x14) as Actor
		return
	endif

	If _00E_A2_GhostwalkGlobal.GetValueInt() == 1
		If bTargetMarked && !hasAborted
			_00E_A2_GhostwalkGlobal.SetValueInt(2)
			float iRecoveryTime = _00E_A2_Ghostwalk.GetNthRecoveryTime(iShoutIndex - 1)
			(PlayerREF as _00E_Game_TalentControlSC).SetTalentRecoveryTime(_00E_A2_Ghostwalk, iRecoveryTime)
			GoToState("Teleporting")
		Else
			NotMarkedClearUp()
		EndIf	
	EndIf

	PlayerREF.RemovePerk(QuietCasting)
	
EndEvent

Function abort()
	hasAborted = true
	self.Dispel()
EndFunction

State MarkTargets

Event OnBeginState()
	if GetTargetActor() != Game.GetForm(0x14) as Actor
		return
	endif
	
	PlayerREF.AddPerk(QuietCasting)
	If _00E_DisableSkillTutorials.GetValueInt() == 0
		_00E_A2_Tutorial_GhostwalkTutorial.ShowAsHelpMessage("Ghostwalk", 7, 7, 1)
	EndIf
	_00E_A2_GhostwalkGlobal.SetValueInt(1)
	(PlayerREF as _00E_Game_TalentControlSC).SetTalentRecoveryTime(_00E_A2_Ghostwalk, 0)
	A2_Ghostwalk_Player.ForceRefTo(PlayerREF)
	A2_Ghostwalk_PlayerForScript = A2_Ghostwalk_Player as _00E_A2_Ghostwalk_PlayerSC
	PlayerREF.AddSpell(_00E_A2_GhostwalkAbSelectionSP, False)
	_00E_A2_GhostwalkSelectionIntroIMOD.Apply()
	MarkingLP = _00E_A2_GhostwalkMarkingLPM.Play(playerREF)
	MAGConjurePortal.Play(PlayerREF)
	float iReach = _00E_A2_GhostwalkSP.GetNthEffectMagnitude(iShoutIndex - 1)
	A2_Ghostwalk_PlayerForScript.EnterMarkingMode(iReach, Self as _00E_A2_GhostwalkSC)
	Wait(0.5)
	_00E_A2_GhostwalkSelectionHoldIMOD.ApplyCrossFade(1.5)

EndEvent

EndState

State Teleporting

Event OnBeginState()
	if GetTargetActor() != Game.GetForm(0x14) as Actor
		return
	endif

	iSneakSkill = PlayerREF.GetBaseActorValue("Sneak")
	Game.ForceFirstPerson()
	Game.DisablePlayerControls(false, false, true, false, false, false, false, false)
	A2_Ghostwalk_Victim.GetActorReference().RemoveSpell(_00E_A2_GhostwalkAbMarkedSP)
	PlayerREF.RemoveSpell(_00E_A2_GhostwalkAbSelectionSP)
	A2_Ghostwalk_PlayerForScript.ExitMarkingMode()
	_00E_A2_GhostwalkSelectionHoldIMOD.Remove()
	Sound.StopInstance(MarkingLP)
	QSTDA16SoulGemOffM.Play(PlayerREF)
	A2_Ghostwalk_Player.Clear()
	A2_GhostwalkMarkingRune.GetReference().Delete()
	A2_GhostwalkMarkingRune.Clear()
	
	If MarkingRuneREF
		MarkingRuneREF.Delete()
	EndIf
	
	TeleportToTarget()
	
EndEvent

EndState

;=====================================================================================
;              							FUNCTIONS                  					 
;=====================================================================================

Function NotMarkedClearUp()

	(PlayerREF as _00E_Game_TalentControlSC).SetTalentRecoveryTime(_00E_A2_Ghostwalk, 0)
	MAGFail.Play(PlayerREF)
	A2_Ghostwalk_Victim.GetActorReference().RemoveSpell(_00E_A2_GhostwalkAbMarkedSP)
	PlayerREF.RemoveSpell(_00E_A2_GhostwalkAbSelectionSP)
	A2_Ghostwalk_PlayerForScript.ExitMarkingMode()
	_00E_A2_GhostwalkSelectionHoldIMOD.Remove()
	Sound.StopInstance(MarkingLP)
	QSTDA16SoulGemOffM.Play(PlayerREF)
	A2_Ghostwalk_Player.Clear()
	A2_GhostwalkMarkingRune.GetReference().Delete()
	A2_GhostwalkMarkingRune.Clear()
	PlayerREF.RemoveSpell(PerkShadowWarriorInvisibility)
		
	If MarkingRuneREF
		MarkingRuneREF.Delete()
	EndIf

	Wait(2)
	_00E_A2_GhostwalkGlobal.SetValueInt(0)
	
EndFunction

Function TeleportToTarget()

	if !PlayerREF.IsSneaking()
		PlayerREF.StartSneaking()
	EndIf
	
	Victim = A2_Ghostwalk_Victim.GetActorReference()
	InitializeCoordinates(Victim)

	_00E_FS_NQR05_TharaelTeleportShockSmallIMOD.Apply()
	_00E_FS_Tharael_DematerializeFXS.Play(PlayerREF)
	Utility.Wait(0.2)

	If !bTargetCloseToWall
		PlayerREF.MoveTo(Victim, EndLocX, EndLocY, EndLocZ)
	Elseif bTargetCloseToWall
		PlayerREF.SetPosition(fGhostwalkCheckActorX, fGhostwalkCheckActorY, fGhostwalkCheckActorZ)
	EndIf
	
	PlayerREF.SetAngle(TargetAngleX, TargetAngleY, TargetAngleZ)
	WallCheckActor.Delete()
	PlayerREF.setActorValue("Variable03", 5)

	float iCritChance = _00E_A2_GhostwalkSP.GetNthEffectMagnitude(iShoutIndex + 2)
	float iDuration = _00E_A2_GhostwalkSP.GetNthEffectMagnitude(iShoutIndex + 3)
	_00E_A2_GhostwalkCloakSP.SetNthEffectMagnitude(0, iCritChance)
	_00E_A2_GhostwalkCloakSP.SetNthEffectDuration(0, iDuration as Int)
	_00E_A2_GhostwalkCloakSP.Cast(PlayerREF, PlayerREF)
	Victim.StopCombat()
	Victim.StopCombatAlarm()
	_00E_A2_GhostwalkGlobal.SetValueInt(0)
	_00E_EspionageFXS.Stop(Victim)
	Game.EnablePlayerControls()
	PlayerREF.RemovePerk(_00E_VisionPerk)
	A2_Ghostwalk_Victim.GetActorReference().SetActorValue("Blindness", 0)
	MAGIllusionReleaseAimedSDM.Play(PlayerREF)
	_00E_FS_Tharael_DematerializeFXS.Stop(PlayerREF)
	_00E_FS_NQR05_TharaelMaterializeFXS.Play(PlayerREF)
	
	Utility.Wait(3)
	
	If PlayerREF.HasSpell(_00E_Affinity_AbShadowdancer) && Victim.IsDead() 
		
		if Victim.GetActorBase().HasKeyword(ActorTypeGhost) || Victim.GetRace() == SkeletonRace
		
			_00E_A2_GhostwalkGhostsCannotBeReanimated.Show()
		
		Else
		
			PlayerREF.AddPerk(_00E_A2_ShadowdancerRaisePerk)
			Victim.AddToFaction(PlayerAlliesFaction)
			_00E_Affinity_ShadowdancerRenimateSelf.Cast(PlayerREF, Victim)
			_00E_MagConjureReanimate.Play(PlayerREF)
			PlayerREF.RemovePerk(_00E_A2_ShadowdancerRaisePerk)
			
		EndIf	

	EndIf
	
	A2_Ghostwalk_Victim.Clear()
	PlayerREF.RemovePerk(QuietCasting)	

	if PlayerREF.GetActorValue("Sneak") >= 200
	
		if _00E_A2_GhostwalkSneakFailsave.GetValueInt() > 0
		
			PlayerREF.ForceActorValue("Sneak", _00E_A2_GhostwalkSneakFailsave.GetValueInt())
			
		Else
			
			PlayerREF.ForceActorValue("Sneak", 50)
			
		EndIf
		
	EndIf

	PlayerREF.RemoveSpell(PerkShadowWarriorInvisibility)
	
EndFunction

Function SelectEnemy(Actor iVictim)

		If IsTargetValid(iVictim)
			If !IsTargetMarked(iVictim) 
				If !bTargetMarked
					MarkingRuneREF = iVictim.PlaceAtMe(_00E_A2_GhostwalkRuneHazard, 1)
					A2_GhostwalkMarkingRune.ForceRefTo(MarkingRuneREF)
					A2_Ghostwalk_Victim.ForceRefTo(iVictim)
					A2_Ghostwalk_Victim.GetActorReference().SetActorValue("Blindness", 100)
					A2_Ghostwalk_Victim.GetActorReference().EvaluatePackage()
					bTargetMarked = True
					_00E_Levelsystem_sEnemyMarked.Show()
					_00E_EspionageFXS.Play(iVictim)
					iVictim.AddSpell(_00E_A2_GhostwalkAbMarkedSP)
					_00E_A2_GhostwalkSelectM.Play(PlayerREF)
				Else
					_00E_Levelsystem_sEnemyAlreadyMarked.Show()
					MAGFail.Play(PlayerREF)
				EndIf
			Else
				UnmarkEnemy(iVictim)
			EndIf
		Else
			Return
		EndIf
		
		If _00E_SelectionTutorialShown.GetValueInt() == 0 && _00E_DisableSkillTutorials.GetValueInt() == 0
			_00E_Tutorial_SelectionMode.Show()
			_00E_SelectionTutorialShown.SetValueInt(1)
		EndIf
		
		If _00E_DisableSkillTutorials.GetValueInt() == 0
			_00E_A2_Tutorial_GhostwalkTutorial.ShowAsHelpMessage("Ghostwalk02", 7, 7, 1)
		EndIf
		
EndFunction

Function UnmarkEnemy(Actor iVictim)
	
	bool Cleared
	A2_GhostwalkMarkingRune.Clear()
	A2_Ghostwalk_Victim.Clear()
	MarkingRuneREF.Disable()
	bTargetMarked = False
	_00E_Levelsystem_sAbilityMarkingRemoved.Show()
	iVictim.RemoveSpell(_00E_A2_GhostwalkAbMarkedSP)
	A2_Ghostwalk_Victim.GetActorReference().SetActorValue("Blindness", 0)
	_00E_EspionageFXS.Stop(iVictim)
	_00E_A2_GhostwalkDeselectM.Play(PlayerREF)
	
	if WallCheckActor
		WallCheckActor.Delete()
	Endif
	
	Cleared = True
EndFunction

bool Function IsTargetValid(Actor CheckVictim)

		If CheckVictim.IsInFaction(PlayerAlliesFaction)
			Return False
		ElseIf CheckVictim.HasKeyword(MagicNoGhostwalk)
			_00E_Levelsystem_sAbilityTargetImmune.Show()
			Return False
		Elseif CheckVictim == PlayerREF
			Return False
		Elseif IsTargetTooCloseToWall(CheckVictim)
			_00E_Levelsystem_sGhostwalkEnemyTooCloseToWall.Show()
			bTargetCloseToWall = True
			Return True
		Else
			Return True
		EndIf

EndFunction

bool Function IsTargetTooCloseToWall(Actor WallCheckVictim)
	
	if WallCheckActor
		WallCheckActor.Delete()
	Endif

	InitializeCoordinates(WallCheckVictim)
	WallCheckActor = WallCheckVictim.PlaceActorAtMe(_00E_A2_GhostwalkWallCheckActorBase, 1)
	WallCheckActor.setAlpha(0)
	fGhostwalkCheckActorX = WallCheckActor.GetPositionX()
	fGhostwalkCheckActorY = WallCheckActor.GetPositionY()
	fGhostwalkCheckActorZ = WallCheckActor.GetPositionZ()
	WallCheckActor.MoveTo(WallCheckVictim, (-105*Math.Sin(WallCheckVictim.GetAngleZ())), (-105*Math.Cos(WallCheckVictim.GetAngleZ())), EndLocZ + 110)
	WallCheckActor.SetAlpha(1.0)
	WallCheckActor.SetAngle(TargetAngleX, TargetAngleY, TargetAngleZ)
	A2_Ghostwalk_WallCheckActor.ForceRefTo(WallCheckActor)
	ObjectReference CastMarker = WallCheckVictim.PlaceAtMe(XMarker, 1)
	_00E_A2_GhostwalkCollCheckSP.Cast(WallCheckVictim, WallCheckActor)
	Wait(0.2)
	
	_00E_A2_Ghostwalk_WallCheckSC WallCheckActorSC = A2_Ghostwalk_WallCheckActor as _00E_A2_Ghostwalk_WallCheckSC
	
	If WallCheckActorSC.CheckOnSpellImpact()
		Return False
	Else
		Return True
	EndIf

EndFunction

bool Function IsTargetMarked(Actor iVictim)

	If iVictim.HasSpell(_00E_A2_GhostwalkAbMarkedSP)
		Return True
	Else
		Return False
	EndIf

EndFunction

bool Function TargetMarked()

	If bTargetMarked == True
		_00E_Levelsystem_sEnemyAlreadyMarked.Show()
		MAGFail.Play(PlayerREF)
		Return True
	Else
		Return False
	EndIf
	
EndFunction

Function InitializeCoordinates(Actor TargetVictim)

	EndLocX = (-100*Math.Sin(TargetVictim.GetAngleZ()))
	EndLocY = (-100*Math.Cos(TargetVictim.GetAngleZ()))
	EndLocZ = 0

	TargetAngleX = TargetVictim.GetAngleX()
	TargetAngleY = TargetVictim.GetAngleY()
	TargetAngleZ = TargetVictim.GetAngleZ()

EndFunction

;=====================================================================================
;              							PROPERTIES                  					 
;=====================================================================================

bool hasAborted
Bool bTargetCloseToWall
Bool bTargetMarked

int MarkingLP
int iShoutIndex

float iSneakSkill

float fGhostwalkCheckActorX
float fGhostwalkCheckActorY
float fGhostwalkCheckActorZ

float TargetAngleX
float TargetAngleY
float TargetAngleZ

float EndLocX
float EndLocY
float EndLocZ
Float iPlayerSpeedBefore

_00E_A2_Ghostwalk_PlayerSC A2_Ghostwalk_PlayerForScript

Message Property _00E_Levelsystem_sEnemyMarked Auto
Message Property _00E_Levelsystem_sEnemyAlreadyMarked Auto
Message Property _00E_Levelsystem_sAbilityMarkingRemoved Auto
Message Property _00E_Levelsystem_sAbilityTargetImmune Auto
Message Property _00E_Levelsystem_sGhostwalkEnemyTooCloseToWall Auto

ActorBase Property _00E_A2_GhostwalkWallCheck Auto
Actor WallCheckActor
Actor FakeActor
Actor Victim

ObjectReference MarkingRuneREF 

ReferenceAlias NextTarget 

Actor Property PlayerREF Auto

ActorBase Property _00E_A2_GhostwalkWallCheckActorBase Auto

Faction Property PlayerAlliesFaction Auto

Message Property _00E_A2_Tutorial_GhostwalkTutorial Auto
Message Property _00E_A2_Tutorial_GhostwalkTutorial02 Auto
Message Property _00E_Tutorial_SelectionMode Auto
Message Property _00E_A2_GhostwalkGhostsCannotBeReanimated Auto

Keyword Property ActorTypeGhost Auto

Explosion Property _00E_A2_GhostwalkImpactExplosion Auto

ReferenceAlias Property A2_Ghostwalk_Player Auto
ReferenceAlias Property A2_Ghostwalk_WallCheckActor Auto

GlobalVariable Property _00E_A2_GhostwalkGlobal Auto
GlobalVariable Property _00E_SelectionTutorialShown Auto
GlobalVariable Property _00E_A2_GhostwalkSneakFailsave Auto
GlobalVariable Property _00E_DisableSkillTutorials Auto

ReferenceAlias Property A2_Ghostwalk_Victim Auto
ReferenceAlias Property A2_GhostwalkMarkingRune Auto

ImageSpaceModifier Property _00E_A2_GhostwalkSelectionIntroIMOD Auto
ImageSpaceModifier Property _00E_A2_GhostwalkSelectionHoldIMOD Auto
ImageSpaceModifier Property _00E_FS_NQR05_TharaelTeleportShockSmallIMOD Auto

EffectShader Property _00E_FS_NQR05_TharaelMaterializeFXS Auto
EffectShader Property _00E_EspionageFXS Auto
EffectShader Property _00E_FS_Tharael_DematerializeFXS Auto

Race Property SkeletonRace Auto

Sound Property MAGIllusionReleaseAimedSDM Auto

Spell Property _00E_A2_GhostwalkSP Auto
Spell Property _00E_A2_GhostwalkAbMarkedSP Auto
Spell Property _00E_A2_GhostwalkAbSelectionSP Auto
Spell Property _00E_A2_GhostwalkCloakSP Auto
Spell Property _00E_A2_GhostwalkCollCheckSP Auto
Spell Property PerkShadowWarriorInvisibility Auto
Spell Property _00E_Vision_UpdateAb Auto
Spell Property _00E_Affinity_AbShadowdancerCloakSP Auto
Spell Property _00E_Affinity_AbShadowdancer Auto
Spell Property _00E_Affinity_ShadowdancerRenimateSelf Auto

Static Property XMarker Auto
Activator Property _00E_A2_GhostwalkMarkingRune Auto

Hazard Property _00E_A2_GhostwalkRuneHazard Auto

Sound Property _00E_A2_GhostwalkSelectM Auto
Sound Property _00E_A2_GhostwalkDeselectM Auto
Sound Property MAGFail Auto
Sound Property _00E_A2_GhostwalkMarkingLPM Auto
Sound Property QSTDA16SoulGemOffM Auto
Sound Property MAGConjurePortal Auto
Sound Property _00E_A2_Ghostwalk_TeleportDoneSound Auto
Sound Property _00E_A2_Ghostwalk_TeleportSound Auto
Sound Property _00E_MagConjureReanimate Auto

Shout Property _00E_A2_Ghostwalk Auto

Perk Property _00E_Class_Manipulation_P09b_Talent_WellOfLife3 Auto
Perk Property _00E_Class_Manipulation_P09b_Talent_WellOfLife2 Auto
Perk Property _00E_Class_Manipulation_P09b_Talent_WellOfLife Auto
Perk Property QuietCasting Auto

Perk Property _00E_VisionPerk Auto
Perk Property _00E_A2_ShadowdancerRaisePerk Auto

Keyword Property MagicNoGhostwalk Auto

; Skyrim Together: STR mirrors this effect onto the caster's puppet on other clients. This flag marks
; whether this copy runs on the local player; every event is skipped for the puppet's copy.
Bool STR_IsLocalTarget = False
