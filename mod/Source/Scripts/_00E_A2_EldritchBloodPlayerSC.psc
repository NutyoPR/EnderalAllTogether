Scriptname _00E_A2_EldritchBloodPlayerSC extends activemagiceffect  

Import _00E_TalentLibrary
Import Utility

int function _GetScriptVersion() Global
	return 1
endFunction

;=====================================================================================
;              							EVENTS & STATES                 					 
;=====================================================================================

Event OnEffectStart(Actor akTarget, Actor akCaster)
	STR_IsLocalTarget = (akTarget == Game.GetForm(0x14) as Actor)
	if !STR_IsLocalTarget
		return
	endif

	hasAborted = False
	
	iIndex = GetPlayerTalentLevel(_00E_Class_LifeAndDeath_P09b_Talent_EldritchBlood, _00E_Class_LifeAndDeath_P09b_Talent_EldritchBlood2, _00E_Class_LifeAndDeath_P09b_Talent_EldritchBlood3)
	
	If _00E_A2_EldritchBloodGlobal.GetValueInt() == 0
		iFrenzyTargetMarked = False
		iFrezyAttackTargetMarked = False
		GoToState("MarkTargets")
	Elseif _00E_A2_EldritchBloodGlobal.GetValueInt() == 1
		If iFrenzyTargetMarked
			_00E_A2_EldritchBloodGlobal.SetValueInt(2)
			GoToState("AddEffect")
		Elseif !iFrenzyTargetMarked
			_00E_A2_EldritchBloodGlobal.SetValueInt(0)
			NotMarkedClearUp()
		EndIf	
	EndIf
	
EndEvent

Event OnEffectFinish(Actor akTarget, Actor akCaster)
	if akTarget != Game.GetForm(0x14) as Actor
		return
	endif

	If _00E_A2_EldritchBloodGlobal.GetValueInt() == 1
		If iFrenzyTargetMarked && !hasAborted
			_00E_A2_EldritchBloodGlobal.SetValueInt(2)
			float iRecoveryTime = _00E_A2_EldritchBlood.GetNthRecoveryTime(iIndex - 1)
			(PlayerREF as _00E_Game_TalentControlSC).SetTalentRecoveryTime(_00E_A2_EldritchBlood, iRecoveryTime)
			GoToState("AddEffect")
		Else
			NotMarkedClearUp()
		EndIf	
	EndIf

EndEvent

function abort()
	hasAborted = true
	Self.Dispel()
EndFunction

State MarkTargets

	Event OnBeginState()
		if GetTargetActor() != Game.GetForm(0x14) as Actor
			return
		endif

		If _00E_SelectionTutorialShown.GetValueInt() == 0 && _00E_DisableSkillTutorials.GetValueInt() == 0
			_00E_Tutorial_SelectionMode.Show()
			_00E_SelectionTutorialShown.SetValueInt(1)
		EndIf
		
		If _00E_A2_EldritchBloodInDepthTutorial.GetValueInt() == 0  && _00E_DisableSkillTutorials.GetValueInt() == 0
			_00E_A2_Tutorial_EldritchBloodDetailed.Show()
			_00E_A2_EldritchBloodInDepthTutorial.SetValueInt(1)
		EndIf
		
		If	_00E_DisableSkillTutorials.GetValueInt() == 0
			_00E_A2_Tutorial_EldritchBlood.ShowAsHelpMessage("EldritchBlood", 8, 8, 1)
		EndIf
		
		_00E_A2_EldritchBloodGlobal.SetValueInt(1)
		(PlayerREF as _00E_Game_TalentControlSC).SetTalentRecoveryTime(_00E_A2_EldritchBlood, 0)
		A2_EldritchBlood_Player.ForceRefTo(PlayerREF)
		A2_EldritchBlood_PlayerForScript = A2_EldritchBlood_Player as _00E_A2_EldritchBloodPlayerMarkSC
		PlayerREF.AddSpell(_00E_A2_EldritchBloodAbSelectionSP, False)
		_00E_A2_EldritchBloodSelectionIntroIMOD.Apply()
		MarkingLP = _00E_A2_GhostwalkMarkingLPM.Play(playerREF)
		MAGConjurePortal.Play(PlayerREF)
		A2_EldritchBlood_PlayerForScript.EnterMarkingMode(1800, Self as _00E_A2_EldritchBloodPlayerSC)
		Wait(0.5)
		_00E_A2_EldritchBloodSelectionHoldIMOD.ApplyCrossFade(1.5)

	EndEvent

EndState

State AddEffect

	Event OnBeginState()
		if GetTargetActor() != Game.GetForm(0x14) as Actor
			return
		endif

		A2_EldritchBlood_Victim.GetActorReference().RemoveSpell(_00E_A2_EldritchBloodAbMarkedVictimSP)
		
		if A2_EldritchBlood_VictimTarget.GetActorReference()
			A2_EldritchBlood_VictimTarget.GetActorReference().RemoveSpell(_00E_A2_EldritchBloodAbMarkedVictimTargetSP)
		endif
		
		PlayerREF.RemoveSpell(_00E_A2_EldritchBloodAbSelectionSP)
		A2_EldritchBlood_PlayerForScript.ExitMarkingMode()
		_00E_A2_EldritchBloodSelectionHoldIMOD.Remove()
		QSTDA16SoulGemOffM.Play(PlayerREF)
		A2_EldritchBlood_Player.Clear()
		
		if A2_EldritchBlood_Rune.GetReference()
			A2_EldritchBlood_Rune.GetReference().Delete()
		endif
		
		if A2_EldritchBlood_VictimRune.GetReference()
			A2_EldritchBlood_VictimRune.GetReference().Delete()
		endif
		
		A2_EldritchBlood_Rune.Clear()
		A2_EldritchBlood_VictimRune.Clear()
		
		If MarkingRuneREF
			MarkingRuneREF.Delete()
		EndIf
		
		If MarkingVictimRuneREF
			MarkingVictimRuneREF.Delete()
		EndIf
		
		AddFrenzySpell()
		
		_00E_A2_EldritchBloodGlobal.SetValueInt(0)
		Sound.StopInstance(MarkingLP)
		
	EndEvent

EndState

;=====================================================================================
;              							FUNCTIONS                  					 
;=====================================================================================

Function AddFrenzySpell()

	float iExpDamage = _00E_A2_EldritchBloodSP.GetNthEffectMagnitude(iIndex - 1)
	_00E_A2_EldritchBloodEnchantment.SetNthEffectMagnitude(0, iExpDamage)
	
	if A2_EldritchBlood_VictimTarget.GetActorReference()
		_00E_A2_EldritchBloodMarkedVictimFXS.Stop(A2_EldritchBlood_VictimTarget.GetActorReference())
	endif
	
	float iFrenzyDMGMult = _00E_A2_EldritchBloodSP.GetNthEffectMagnitude(iIndex + 2)
	Int iFrenzyDuration = _00E_A2_EldritchBloodSP.GetNthEffectDuration(iIndex + 2) as Int
	
	_00E_A2_EldritchBloodVictimSP.SetNthEffectMagnitude(0, iFrenzyDMGMult)
	_00E_A2_EldritchBloodVictimSP.SetNthEffectDuration(0, iFrenzyDuration)
	
	if A2_EldritchBlood_Victim.GetReference()
		_00E_A2_EldritchBloodVictimSP.Cast(A2_EldritchBlood_Victim.GetReference(), A2_EldritchBlood_Victim.GetReference())
	endif
	
EndFunction

Function NotMarkedClearUp()

	if A2_EldritchBlood_Victim.GetActorReference()
		A2_EldritchBlood_Victim.GetActorReference().RemoveSpell(_00E_A2_EldritchBloodAbMarkedVictimSP)
	endif
	
	if A2_EldritchBlood_VictimTarget.GetActorReference()
		A2_EldritchBlood_VictimTarget.GetActorReference().RemoveSpell(_00E_A2_EldritchBloodAbMarkedVictimTargetSP)
		_00E_A2_EldritchBloodMarkedVictimFXS.Stop(A2_EldritchBlood_VictimTarget.GetActorReference())
	endif
	
	(PlayerREF as _00E_Game_TalentControlSC).SetTalentRecoveryTime(_00E_A2_EldritchBlood, 0)	
	MAGFail.Play(PlayerREF)
	PlayerREF.RemoveSpell(_00E_A2_EldritchBloodAbSelectionSP)
	
	if A2_EldritchBlood_PlayerForScript
		A2_EldritchBlood_PlayerForScript.ExitMarkingMode()
	endif
	
	_00E_A2_EldritchBloodSelectionHoldIMOD.Remove()
	QSTDA16SoulGemOffM.Play(PlayerREF)
	A2_EldritchBlood_Player.Clear()
	
	if A2_EldritchBlood_Rune.GetReference()
		A2_EldritchBlood_Rune.GetReference().Delete()
	endif
	
	if A2_EldritchBlood_VictimRune.GetReference()
		A2_EldritchBlood_VictimRune.GetReference().Delete()
	endif
	
	A2_EldritchBlood_Rune.Clear()
	A2_EldritchBlood_VictimRune.Clear()
	A2_EldritchBlood_VictimTarget.Clear()
	A2_EldritchBlood_Victim.Clear()
	
	If MarkingRuneREF
		MarkingRuneREF.Delete()
	EndIf
	
	If MarkingVictimRuneREF
		MarkingVictimRuneREF.Delete()
	EndIf

	if ! PlayerREF.IsDead()
		Wait(2.0)
	endif
	
	_00E_A2_EldritchBloodGlobal.SetValueInt(0)
	
	if MarkingLP
		Sound.StopInstance(MarkingLP)
	endif
	
EndFunction

Function SelectEnemy(Actor iVictim)

	If !IsTargetMarked(iVictim) 
		If !iFrenzyTargetMarked 
			If ! IsTargetValid(iVictim)
				return
			EndIf
			MarkFrenzyVictim(iVictim)
			iFrenzyTargetMarked = True
		Elseif !iFrezyAttackTargetMarked
			MarkFrenzyTargetVictim(iVictim)
			iFrezyAttackTargetMarked = True
		Else
			_00E_Levelsystem_sEnemyAlreadyMarked.Show()
			MAGFail.Play(PlayerREF)
		EndIf
	Else
		UnmarkEnemy(iVictim)
	EndIf
		
EndFunction

Function MarkFrenzyVictim(Actor iFrenzyVictim)

	MarkingRuneREF = iFrenzyVictim.PlaceAtMe(_00E_A2_EldritchBloodMarkedRune, 1)
	A2_EldritchBlood_Rune.ForceRefTo(MarkingRuneREF)
	A2_EldritchBlood_Victim.ForceRefTo(iFrenzyVictim)
    _00E_Levelsystem_sEldritchBloodVictimMarked.Show()
	_00E_A2_EldritchBloodMarkedFXS.Play(iFrenzyVictim)
	iFrenzyVictim.AddSpell(_00E_A2_EldritchBloodAbMarkedVictimSP)
	_00E_A2_GhostwalkSelectM.Play(PlayerREF)

EndFunction

Function MarkFrenzyTargetVictim(Actor iFrenzyTargetVictim)

	MarkingVictimRuneREF = iFrenzyTargetVictim.PlaceAtMe(_00E_A2_EldritchBloodMarkedTargetRune, 1)
	A2_EldritchBlood_VictimRune.ForceRefTo(MarkingVictimRuneREF)
	A2_EldritchBlood_VictimTarget.ForceRefTo(iFrenzyTargetVictim)
    _00E_Levelsystem_sEldritchBloodAttackTargetMarked.Show()
	_00E_A2_EldritchBloodMarkedVictimFXS.Play(iFrenzyTargetVictim)
	iFrenzyTargetVictim.AddSpell(_00E_A2_EldritchBloodAbMarkedVictimTargetSP)
	_00E_A2_GhostwalkSelectM.Play(PlayerREF)

EndFunction

Function UnmarkEnemy(Actor iVictim)
	
	If iVictim.HasSpell(_00E_A2_EldritchBloodAbMarkedVictimSP)
		A2_EldritchBlood_Rune.Clear()
		A2_EldritchBlood_Victim.Clear()
		iFrenzyTargetMarked = False
        _00E_Levelsystem_sEldritchBloodVictimMarkingRemoved.Show()
		iVictim.RemoveSpell(_00E_A2_EldritchBloodAbMarkedVictimSP)
		_00E_A2_EldritchBloodMarkedFXS.Stop(iVictim)
		_00E_A2_GhostwalkDeselectM.Play(PlayerREF)
		MarkingRuneREF.Delete()
		MarkingRuneREF = None
	Elseif iVictim.HasSpell(_00E_A2_EldritchBloodAbMarkedVictimTargetSP)
		A2_EldritchBlood_VictimRune.Clear()
		A2_EldritchBlood_VictimTarget.Clear()
		iFrezyAttackTargetMarked = False
        _00E_Levelsystem_sEldritchBloodAttackVictimMarkingRemoved.Show()
		iVictim.RemoveSpell(_00E_A2_EldritchBloodAbMarkedVictimTargetSP)
		_00E_A2_EldritchBloodMarkedVictimFXS.Stop(iVictim)
		_00E_A2_GhostwalkDeselectM.Play(PlayerREF)
		MarkingVictimRuneREF.Delete()
		MarkingVictimRuneREF = None
	EndIf
	
EndFunction

bool Function IsTargetValid(Actor CheckVictim)

		If CheckVictim.IsInFaction(PlayerAlliesFaction) || CheckVictim.IsPlayerTeammate()
			Return False
		ElseIf CheckVictim.HasKeyword(MagicNoEldritchBlood)
            _00E_Levelsystem_sAbilityEnemyLevelTooHigh.Show()
			Return False
		Elseif CheckVictim == PlayerREF
			Return False
		Elseif EnemyLevelTooHigh(CheckVictim)
            _00E_Levelsystem_sAbilityEnemyLevelTooHigh.Show()
			Return False
		Else
			Return True
		EndIf
	
EndFunction

bool Function EnemyLevelTooHigh(Actor LevelVictim)

	Float iAllowedDif = _00E_A2_EldritchBloodSP.GetNthEffectMagnitude(6)
	
	return (LevelVictim.GetLevel() > (PlayerLevel.GetValueInt() + iAllowedDif as Int))

EndFunction

bool Function IsTargetMarked(Actor iVictim)

	return iVictim.HasSpell(_00E_A2_EldritchBloodAbMarkedVictimSP) || iVictim.HasSpell(_00E_A2_EldritchBloodAbMarkedVictimTargetSP)

EndFunction

;=====================================================================================
;              							PROPERTIES                  					 
;=====================================================================================

bool hasAborted

int iIndex
int MarkingLP

; bool Property bTutorialShown Auto Hidden

Bool iFrenzyTargetMarked
Bool iFrezyAttackTargetMarked

_00E_A2_EldritchBloodPlayerMarkSC A2_EldritchBlood_PlayerForScript 

Message Property _00E_Levelsystem_sEnemyAlreadyMarked Auto
Message Property _00E_Levelsystem_sEldritchBloodVictimMarked Auto
Message Property _00E_Levelsystem_sEldritchBloodAttackTargetMarked Auto
Message Property _00E_Levelsystem_sAbilityEnemyLevelTooHigh Auto
Message Property _00E_Levelsystem_sEldritchBloodVictimMarkingRemoved Auto
Message Property _00E_Levelsystem_sEldritchBloodAttackVictimMarkingRemoved Auto

GlobalVariable Property _00E_A2_EldritchBloodGlobal Auto
GlobalVariable Property PlayerLevel Auto
GlobalVariable Property _00E_SelectionTutorialShown Auto
GlobalVariable Property _00E_A2_EldritchBloodInDepthTutorial Auto
GlobalVariable Property _00E_DisableSkillTutorials Auto

Actor Property PlayerREF Auto

ObjectReference MarkingRuneREF
ObjectReference MarkingVictimRuneREF

ReferenceAlias Property A2_EldritchBlood_Player Auto
ReferenceAlias Property A2_EldritchBlood_Victim Auto
ReferenceAlias Property A2_EldritchBlood_VictimTarget Auto
ReferenceAlias Property A2_EldritchBlood_Rune Auto
ReferenceAlias Property A2_EldritchBlood_VictimRune Auto

Hazard Property _00E_A2_EldritchBloodMarkedRune Auto
Hazard Property _00E_A2_EldritchBloodMarkedTargetRune Auto

EffectShader Property _00E_A2_EldritchBloodMarkedFXS Auto
EffectShader Property _00E_A2_EldritchBloodMarkedVictimFXS Auto

Perk Property _00E_Class_LifeAndDeath_P09b_Talent_EldritchBlood Auto
Perk Property _00E_Class_LifeAndDeath_P09b_Talent_EldritchBlood2 Auto
Perk Property _00E_Class_LifeAndDeath_P09b_Talent_EldritchBlood3 Auto

Shout Property _00E_A2_EldritchBlood Auto

Message Property _00E_A2_Tutorial_EldritchBlood Auto
Message Property _00E_Tutorial_SelectionMode Auto
Message Property _00E_A2_Tutorial_EldritchBloodDetailed Auto

Enchantment Property _00E_A2_EldritchBloodEnchantment Auto

Faction Property PlayerAlliesFaction Auto

Keyword Property MagicNoEldritchBlood Auto

Spell Property _00E_A2_EldritchBloodAbSelectionSP Auto
Spell Property _00E_A2_EldritchBloodAbMarkedVictimTargetSP Auto
Spell Property _00E_A2_EldritchBloodAbMarkedVictimSP Auto
Spell Property _00E_A2_EldritchBloodVictimSP Auto
Spell Property _00E_A2_EldritchBloodSP Auto 

Sound Property MAGFail Auto
Sound Property _00E_A2_GhostwalkSelectM Auto
Sound Property _00E_A2_GhostwalkDeselectM Auto
Sound Property _00E_A2_GhostwalkMarkingLPM Auto
Sound Property QSTDA16SoulGemOffM Auto
Sound Property MAGConjurePortal Auto

ImageSpaceModifier Property _00E_A2_EldritchBloodSelectionIntroIMOD Auto
ImageSpaceModifier Property _00E_A2_EldritchBloodSelectionHoldIMOD Auto

; Skyrim Together: STR mirrors this effect onto the caster's puppet on other clients. This flag marks
; whether this copy runs on the local player; every event is skipped for the puppet's copy.
Bool STR_IsLocalTarget = False
